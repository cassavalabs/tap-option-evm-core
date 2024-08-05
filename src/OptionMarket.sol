// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {ICuratorFees} from "./interfaces/ICuratorFees.sol";
import {IOptionMarket} from "./interfaces/IOptionMarket.sol";
import {IOptionMarketConfig} from "./interfaces/IOptionMarketConfig.sol";
import {IPyth} from "./interfaces/external/IPyth.sol";

import {BitMaps} from "./libraries/BitMaps.sol";
import {Currency} from "./libraries/Currency.sol";
import {Errors} from "./libraries/Errors.sol";
import {MarketId} from "./libraries/MarketId.sol";
import {Market} from "./libraries/Market.sol";
import {MerkleProof} from "./libraries/MerkleProof.sol";
import {Option} from "./libraries/Option.sol";
import {Position} from "./libraries/Position.sol";

import {ProtocolFees} from "./ProtocolFees.sol";

contract OptionMarket is ICuratorFees, IOptionMarket, IOptionMarketConfig, ProtocolFees {
    using Currency for address;
    using Position for Position.State;

    uint8 public constant MAX_SECONDS_OFFSET = 5; // 5 seconds
    uint8 public constant MAX_SECONDS_DELAY = 30; // 30 seconds

    IPyth public immutable pyth;

    uint256 tournamentIds;
    mapping(MarketId id => Market.MarketInfo) public markets;
    mapping(uint256 => Market.Tournament) internal tournaments;
    mapping(address currency => uint256) public totalValueLocked;

    constructor(address _owner, address _pyth) ProtocolFees(_owner) {
        pyth = IPyth(_pyth);
    }

    /// @inheritdoc ICuratorFees
    function collectFees(uint64 tournamentId) external override {
        Market.Tournament storage tournament = tournaments[tournamentId];

        if (msg.sender != tournament.creator) revert Errors.OnlyCreatorCanCollectFees();
        if (tournament.isFeeClaimed) revert Errors.FeeClaimed();

        address currency = tournament.config.currency;
        uint256 amount = tournament.fees;
        // mark claimed
        tournament.isFeeClaimed = true;
        deductTVL(currency, amount);

        currency.transfer(msg.sender, amount);
        emit CollectFee(tournamentId, msg.sender, currency, amount);
    }

    /// @inheritdoc IOptionMarket
    function bearish(MarketId id, uint64 tournamentId, uint64 investment, uint32 expiry, bytes calldata priceUpdate)
        external
        payable
        override
    {
        (bytes32 positionId, int64 strikePrice) =
            openPosition(id, tournamentId, investment, expiry, Option.wrap(0), priceUpdate);

        emit Bearish(id, tournamentId, msg.sender, positionId, block.timestamp + expiry, investment, strikePrice);
    }

    /// @inheritdoc IOptionMarket
    function bullish(MarketId id, uint64 tournamentId, uint64 investment, uint32 expiry, bytes calldata priceUpdate)
        external
        payable
        override
    {
        (bytes32 positionId, int64 strikePrice) =
            openPosition(id, tournamentId, investment, expiry, Option.wrap(1), priceUpdate);

        emit Bullish(id, tournamentId, msg.sender, positionId, block.timestamp + expiry, investment, strikePrice);
    }

    /// @inheritdoc IOptionMarket
    function settle(MarketId id, uint64 tournamentId, address account, bytes calldata priceUpdate)
        external
        payable
        override
    {
        Market.MarketInfo storage market = markets[id];
        Market.Tournament storage tournament = tournaments[tournamentId];
        Market.Entrant storage entrant = tournament.entrants[account];

        uint256 sequenceId = market.sequenceIds[account][tournamentId];
        bytes32 positionId = Position.toId(id, sequenceId, account);

        Position.State storage position = market.positions[positionId];

        // ensure it's a valid position
        if (position.investment == 0) revert Errors.PositionNotFound();
        // ensure reward has not been claimed before
        if (position.rewardClaimed) revert Errors.RewardClaimed();

        int64 closingPrice =
            parsePriceData(MarketId.unwrap(id), priceUpdate, uint64(position.expiry), MAX_SECONDS_OFFSET);

        position.closingPrice = closingPrice;
        position.rewardClaimed = true;

        // increment the sequenceId
        market.sequenceIds[account][tournamentId] += 1;
        // remove from unsettled position queue
        entrant.unsettled -= 1;

        uint64 reward;
        if (position.isRewardable()) {
            reward = (market.config.reward * position.investment) / BASIS_POINT;
            reward += position.investment;
            entrant.balance += reward;
        }

        emit Settle(id, tournamentId, account, positionId, reward, closingPrice);
    }

    /// @inheritdoc IOptionMarket
    function signup(uint256 tournamentId) external payable override {
        Market.Tournament storage tournament = tournaments[tournamentId];

        if (tournament.config.closingTime <= block.timestamp) {
            revert Errors.TournamentEnded();
        }

        Market.Entrant storage entrant = tournament.entrants[msg.sender];

        if (entrant.isRegistered) revert Errors.AlreadySignedUp();

        entrant.balance += tournament.lotAmount;
        entrant.isRegistered = true;

        tournament.entrantCount += 1;
        address currency = tournament.config.currency;
        uint256 entryFee = tournament.config.entryFee;

        if (entryFee > 0) {
            tournament.fees += entryFee;
            addTVL(currency, entryFee);
            accountProtocolFee(currency, entryFee);

            if (currency.isNative() && msg.value < entryFee) {
                revert Errors.InsufficientFee();
            }
            // not sure how using else would play out here
            if (!currency.isNative()) {
                currency.safeTransferFrom(msg.sender, address(this), entryFee);
            }
        }

        emit SignUp(tournamentId, msg.sender, tournament.lotAmount);
    }

    /// @inheritdoc IOptionMarket
    function refill(uint256 tournamentId) external payable override {
        Market.Tournament storage tournament = tournaments[tournamentId];
        Market.TournamentConfig memory config = tournament.config;

        if (config.closingTime <= block.timestamp) revert Errors.TournamentEnded();

        Market.Entrant storage entrant = tournament.entrants[msg.sender];

        /// Ensure entrant is eligible to refill balance
        if (!entrant.isRegistered) revert Errors.NotSignedUp();
        if (entrant.balance > tournament.lotAmount || entrant.unsettled > 0) {
            revert Errors.CannotRefill();
        }
        /// Check if max refill is set, revert if user has reached max refill
        if (entrant.refillCount >= config.maxRefill) revert Errors.MaxRefillReached();

        if (config.cost > 0) {
            tournament.fees += config.cost;
            addTVL(config.currency, config.cost);
            accountProtocolFee(config.currency, config.cost);

            if (config.currency.isNative() && msg.value < config.cost) {
                revert Errors.InsufficientFee();
            }
            // not sure how using else would play out here
            if (!config.currency.isNative()) {
                config.currency.safeTransferFrom(msg.sender, address(this), config.cost);
            }
        }

        entrant.balance += tournament.lotAmount;
        entrant.refillCount += 1;

        tournament.refilCount += 1;

        emit Refill(tournamentId, msg.sender, tournament.lotAmount);
    }

    /// @inheritdoc IOptionMarket
    function claim(uint256 tournamentId, bytes32[] memory proof, uint256 index, address account, uint256 amount)
        external
        override
    {
        Market.Tournament storage tournament = tournaments[tournamentId];

        ///@dev Ensure reward is claimable
        if (tournament.merkleRoot == bytes32(0)) revert Errors.TournamentNotFinalized();

        ///@dev Ensure the user has not claimed before
        if (BitMaps.get(tournament.claimList, index)) revert Errors.RewardClaimed();

        ///@dev Construct leaf and verify claim
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, index, amount))));

        if (!MerkleProof.verify(proof, tournament.merkleRoot, leaf)) {
            revert Errors.InvalidMerkleProof();
        }

        address currency = tournament.config.currency;

        deductTVL(currency, amount);
        ///@dev tag as claimed to avoid reentrant claims
        BitMaps.setTo(tournament.claimList, index, true);
        ///@dev transfer fund to claimant
        currency.transfer(account, amount);

        emit Claim(tournamentId, account, amount);
    }

    /// @inheritdoc IOptionMarketConfig
    function startTournament(Market.StartTournamentParam memory params) external payable override {
        if (params.prizePool == 0 || params.winners == 0 || params.closingTime < params.startTime) {
            revert Errors.InvalidTournament();
        }

        uint256 tournamentId = tournamentIds;
        Market.Tournament storage tournament = tournaments[tournamentId];
        Market.TournamentConfig storage config = tournament.config;

        config.currency = params.currency;
        config.winners = params.winners;
        config.startTime = params.startTime;
        config.closingTime = params.closingTime;
        config.maxRefill = params.maxRefill;
        config.prizePool = params.prizePool;
        config.entryFee = params.entryFee;
        config.cost = params.cost;

        tournament.lotAmount = params.lotAmount;
        tournament.creator = msg.sender;

        // increment the ids
        tournamentIds += 1;
        // account for value received to aid token recovery
        addTVL(config.currency, params.prizePool);

        if (config.currency.isNative() && msg.value < params.prizePool) {
            revert Errors.InsufficientRewardFund();
        }
        // not sure how using else would play out here
        if (!config.currency.isNative()) {
            config.currency.safeTransferFrom(msg.sender, address(this), params.prizePool);
        }

        emit StartTournament(
            tournamentId,
            msg.sender,
            params.currency,
            params.prizePool,
            params.entryFee,
            params.cost,
            params.winners,
            params.startTime,
            params.closingTime,
            params.maxRefill,
            params.title
        );
    }

    /// @inheritdoc IOptionMarketConfig
    function settleTournament(uint64 tournamentId, bytes32 merkleRoot) external override onlyOperator {
        Market.Tournament storage tournament = tournaments[tournamentId];

        if (tournament.config.closingTime > block.timestamp) {
            revert Errors.TournamentOngoing();
        }

        tournament.merkleRoot = merkleRoot;
        emit SettleTournament(tournamentId, msg.sender, merkleRoot);
    }

    /// @inheritdoc IOptionMarketConfig
    function extendTournament(uint64 tournamentId, uint64 closingTime) external override onlyOperator {
        Market.Tournament storage tournament = tournaments[tournamentId];

        // ensure tournament exist
        if (tournament.config.startTime == 0) revert Errors.InvalidTournament();
        // ensure new closing time is in the future
        if (tournament.config.closingTime > closingTime || block.timestamp > closingTime) {
            revert Errors.InvalidTimeConfig();
        }

        tournament.config.closingTime = uint48(closingTime);
        emit ExtendTournament(tournamentId, closingTime);
    }

    /// @inheritdoc IOptionMarketConfig
    function adjustMarketReward(MarketId id, uint16 reward) external override onlyOperator {
        Market.MarketInfo storage market = markets[id];
        if (!market.config.isInitialized) revert Errors.MarketDoesNotExist();
        if (reward > BASIS_POINT) revert Errors.RewardExceedsMax();

        market.config.reward = reward;
        emit AdjustMarketReward(id, reward);
    }

    /// @inheritdoc IOptionMarketConfig
    function createMarket(MarketId id, uint16 reward, uint32 minInterval, uint32 maxInterval)
        external
        override
        onlyOperator
    {
        Market.MarketInfo storage market = markets[id];
        Market.Config storage config = market.config;

        if (config.isInitialized) revert Errors.MarketAlreadyExist();
        if (reward > BASIS_POINT) revert Errors.RewardExceedsMax();

        config.minExpiry = minInterval;
        config.maxExpiry = maxInterval;
        config.reward = reward;
        config.paused = false;
        config.isInitialized = true;

        emit CreateMarket(id, msg.sender, reward, minInterval, maxInterval);
    }

    /// @inheritdoc IOptionMarketConfig
    function adjustMarketExpiry(MarketId id, uint32 minExpiry, uint32 maxExpiry) external override onlyOperator {
        Market.Config storage config = markets[id].config;

        if (!config.isInitialized) revert Errors.MarketDoesNotExist();
        if (minExpiry < 60 || minExpiry > maxExpiry) revert Errors.InvalidTimeConfig();

        config.minExpiry = minExpiry;
        config.maxExpiry = maxExpiry;

        emit AdjustMarketExpiry(id, minExpiry, maxExpiry);
    }

    /// @inheritdoc IOptionMarketConfig
    function pause(MarketId id) external override onlyOperator {
        Market.Config storage config = markets[id].config;

        if (!config.isInitialized) revert Errors.MarketDoesNotExist();
        if (config.paused) revert Errors.MarketPaused();

        config.paused = true;
        emit Pause(id);
    }

    /// @inheritdoc IOptionMarketConfig
    function unpause(MarketId id) external override onlyOperator {
        Market.Config storage config = markets[id].config;

        if (!config.isInitialized) revert Errors.MarketDoesNotExist();
        if (!config.paused) revert Errors.MarketNotPaused();

        config.paused = false;
        emit UnPause(id);
    }

    /// @inheritdoc IOptionMarketConfig
    function recoverToken(address currency, address recipient, uint256 amount) external override {
        // Ensure recovering will not have a negative balance impact
        uint256 balanceBefore = currency.balanceOf(address(this));
        uint256 balanceAfter = balanceBefore - totalValueLocked[currency];

        if (balanceAfter < amount) revert Errors.InsufficientBalance();

        currency.transfer(recipient, amount);
        emit RecoverToken(currency, recipient, amount);
    }

    /// @inheritdoc ICuratorFees
    function unclaimedFees(uint64 tournamentId) external view override returns (uint256 amount) {
        Market.Tournament storage tournament = tournaments[tournamentId];
        amount = tournament.fees;
    }

    function addTVL(address currency, uint256 amount) internal {
        totalValueLocked[currency] += amount;
    }

    function deductTVL(address currency, uint256 amount) internal override {
        totalValueLocked[currency] -= amount;
    }

    function parsePriceData(
        bytes32 priceFeedId,
        bytes calldata priceUpdateData,
        uint64 minPublishTime,
        uint8 maxSecondsOffset
    ) private returns (int64 latestPrice) {
        bytes32[] memory priceFeedIds = new bytes32[](1);
        priceFeedIds[0] = priceFeedId;

        bytes[] memory updateData = new bytes[](1);
        updateData[0] = priceUpdateData;

        uint256 updateFee = pyth.getUpdateFee(updateData);
        if (msg.value < updateFee) revert Errors.InsufficientFee();

        IPyth.PriceFeed[] memory priceFeeds = pyth.parsePriceFeedUpdates{value: updateFee}(
            updateData, priceFeedIds, minPublishTime, uint64(minPublishTime + maxSecondsOffset)
        );

        IPyth.PriceFeed memory priceFeed = priceFeeds[0];
        IPyth.Price memory price = priceFeed.price;

        latestPrice = price.price;
    }

    function openPosition(
        MarketId id,
        uint64 tournamentId,
        uint64 investment,
        uint32 expiry,
        Option option,
        bytes calldata priceUpdate
    ) private returns (bytes32 positionId, int64 strikePrice) {
        Market.MarketInfo storage market = markets[id];
        Market.Tournament storage tournament = tournaments[tournamentId];
        Market.TournamentConfig memory config = tournament.config;
        Market.Entrant storage entrant = tournament.entrants[msg.sender];

        // ensure market exists
        if (!market.config.isInitialized) revert Errors.MarketDoesNotExist();
        // ensure tournament is open
        if (config.startTime > block.timestamp || block.timestamp > config.closingTime) {
            revert Errors.EntryNotAllowed();
        }
        // ensure user has enough balance to cover investment amount
        if (entrant.balance < investment) revert Errors.InsufficientBalance();
        // ensure expiry is within market allowed range
        if (market.config.minExpiry > expiry || market.config.maxExpiry < expiry) {
            revert Errors.InvalidExpiryInterval();
        }

        // deduct entrant balance
        entrant.balance -= investment;
        entrant.positionCount += 1;
        entrant.unsettled += 1;

        // fetch the strike price from Pyth Network oracle
        strikePrice = parsePriceData(
            MarketId.unwrap(id), priceUpdate, uint64(block.timestamp - MAX_SECONDS_DELAY), MAX_SECONDS_DELAY
        );

        uint256 sequenceId = market.sequenceIds[msg.sender][tournamentId];
        positionId = Position.toId(id, sequenceId, msg.sender);
        Position.State storage position = market.positions[positionId];

        // ensure no position exists for sequence id
        if (position.investment > 0) revert Errors.PositionAlreadyExist();

        position.investment = investment;
        position.option = option;
        position.strikePrice = strikePrice;
        position.expiry = uint48(block.timestamp + expiry);
    }
}
