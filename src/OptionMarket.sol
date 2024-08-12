// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {IOptionMarket} from "./interfaces/IOptionMarket.sol";
import {IOptionMarketConfig} from "./interfaces/IOptionMarketConfig.sol";
import {IProtocolFees} from "./interfaces/IProtocolFees.sol";
import {IPyth} from "./interfaces/external/IPyth.sol";

import {BitMaps} from "./libraries/BitMaps.sol";
import {Currency} from "./libraries/Currency.sol";
import {Errors} from "./libraries/Errors.sol";
import {MarketId} from "./libraries/MarketId.sol";
import {Market} from "./libraries/Market.sol";
import {MerkleProof} from "./libraries/MerkleProof.sol";
import {Option} from "./libraries/Option.sol";
import {Position} from "./libraries/Position.sol";

import {Authorization} from "./auth/Authorization.sol";

contract OptionMarket is
    IProtocolFees,
    IOptionMarket,
    IOptionMarketConfig,
    Authorization
{
    using Currency for address;
    using Position for Position.State;

    uint24 public constant MAX_REFILL = type(uint24).max - 1;
    uint8 public constant MAX_SECONDS_OFFSET = 5; // 5 seconds
    uint8 public constant MAX_SECONDS_DELAY = 30; // 30 seconds
    uint32 public constant DEFAULT_LOT_AMOUNT = 100; // 100 USD
    uint16 public constant BASIS_POINT = 10_000;

    IPyth public immutable pyth;

    uint256 public tournamentIds;
    mapping(MarketId id => Market.MarketInfo) public markets;
    mapping(uint256 => Market.Tournament) private tournaments;
    /// @dev keep track of fees owned to the protocol
    mapping(address currency => uint256 accruedFee) private protocolFees;
    mapping(address currency => uint256) public totalValueLocked;

    constructor(address _owner, address _pyth) Authorization(_owner) {
        pyth = IPyth(_pyth);
        tournamentIds = 1;
    }

    /// @inheritdoc IOptionMarket
    function bearish(
        MarketId id,
        uint64 tournamentId,
        uint64 investment,
        uint32 expiry,
        bytes calldata priceUpdate
    ) external payable override {
        (bytes32 positionId, int64 strikePrice) = takePosition(
            id,
            tournamentId,
            investment,
            expiry,
            Option.wrap(0),
            priceUpdate
        );

        emit Bearish(
            id,
            tournamentId,
            msg.sender,
            positionId,
            block.timestamp + expiry,
            investment,
            strikePrice
        );
    }

    /// @inheritdoc IOptionMarket
    function bullish(
        MarketId id,
        uint64 tournamentId,
        uint64 investment,
        uint32 expiry,
        bytes calldata priceUpdate
    ) external payable override {
        (bytes32 positionId, int64 strikePrice) = takePosition(
            id,
            tournamentId,
            investment,
            expiry,
            Option.wrap(1),
            priceUpdate
        );

        emit Bullish(
            id,
            tournamentId,
            msg.sender,
            positionId,
            block.timestamp + expiry,
            investment,
            strikePrice
        );
    }

    /// @inheritdoc IOptionMarket
    function settle(
        MarketId id,
        uint64 tournamentId,
        address account,
        bytes calldata priceUpdate
    ) external payable override {
        Market.MarketInfo storage market = markets[id];
        Market.Tournament storage tournament = tournaments[tournamentId];
        Market.Entrant storage entrant = tournament.entrants[account];

        uint256 sequenceId = market.sequenceIds[account][tournamentId];
        bytes32 positionId = Position.toId(id, sequenceId, account);

        Position.State storage position = market.positions[positionId];

        // ensure it's a valid position
        if (position.investment == 0) revert Errors.PositionNotFound();

        int64 closingPrice = parsePriceData(
            MarketId.unwrap(id),
            priceUpdate,
            uint64(position.expiry),
            MAX_SECONDS_OFFSET
        );

        position.closingPrice = closingPrice;
        position.settled = true;

        ///@dev increment the sequenceId to prevent reentrant claim
        unchecked {
            market.sequenceIds[account][tournamentId] += 1;
            // remove from unsettled position queue
            entrant.unsettled -= 1;
        }

        uint64 reward;
        if (position.isRewardable()) {
            unchecked {
                reward = (market.config.reward * position.investment) / BASIS_POINT;
                reward += position.investment;
                entrant.balance += reward;
            }
        }

        emit Settle(id, tournamentId, account, positionId, reward, closingPrice);
    }

    /// @inheritdoc IOptionMarket
    function signup(uint256 tournamentId) external payable override {
        Market.Tournament storage tournament = tournaments[tournamentId];

        if (tournament.config.startTime == 0) revert Errors.InvalidTournament();
        if (tournament.config.closingTime <= block.timestamp) {
            revert Errors.TournamentEnded();
        }

        Market.Entrant storage entrant = tournament.entrants[msg.sender];

        if (entrant.isRegistered) revert Errors.AlreadySignedUp();

        unchecked {
            entrant.balance += DEFAULT_LOT_AMOUNT;
        }
        entrant.isRegistered = true;

        // tournament.entrantCount += 1;
        address currency = tournament.config.currency;
        uint256 entryFee = tournament.config.entryFee;

        if (entryFee > 0) {
            unchecked {
                totalValueLocked[currency] += entryFee;
                protocolFees[currency] += entryFee;
            }

            if (currency.isNative()) {
                if (msg.value < entryFee) revert Errors.InsufficientFee();
            } else {
                currency.safeTransferFrom(msg.sender, address(this), entryFee);
            }
        }

        emit SignUp(tournamentId, msg.sender);
    }

    /// @inheritdoc IOptionMarket
    function refill(uint256 tournamentId) external payable override {
        Market.Tournament storage tournament = tournaments[tournamentId];
        Market.TournamentConfig memory config = tournament.config;

        if (config.startTime == 0) revert Errors.InvalidTournament();
        if (config.closingTime <= block.timestamp) revert Errors.TournamentEnded();

        Market.Entrant storage entrant = tournament.entrants[msg.sender];

        /// Ensure entrant is eligible to refill balance
        if (!entrant.isRegistered) revert Errors.NotSignedUp();
        if (entrant.balance >= DEFAULT_LOT_AMOUNT || entrant.unsettled > 0) {
            revert Errors.CannotRefill();
        }
        /// Check if max refill is set, revert if user has reached max refill
        if (entrant.refillCount >= config.maxRefill) revert Errors.MaxRefillReached();

        address currency = config.currency;
        uint256 rebuyPrice = config.entryFee;
        if (rebuyPrice > 0) {
            unchecked {
                totalValueLocked[currency] += rebuyPrice;
                protocolFees[currency] += rebuyPrice;
            }

            if (currency.isNative()) {
                if (msg.value < rebuyPrice) revert Errors.InsufficientFee();
            } else {
                currency.safeTransferFrom(msg.sender, address(this), rebuyPrice);
            }
        }

        unchecked {
            entrant.balance += DEFAULT_LOT_AMOUNT;
            entrant.refillCount += 1;
        }

        emit Refill(tournamentId, msg.sender);
    }

    /// @inheritdoc IOptionMarket
    function claim(
        uint256 tournamentId,
        bytes32[] memory proof,
        uint256 index,
        address account,
        uint256 amount
    ) external override {
        Market.Tournament storage tournament = tournaments[tournamentId];

        ///@dev Ensure reward is claimable
        if (tournament.merkleRoot == bytes32(0)) revert Errors.TournamentNotFinalized();

        ///@dev Ensure the user has not claimed before
        if (BitMaps.get(tournament.claimList, index)) revert Errors.RewardClaimed();

        ///@dev Construct leaf and verify claim
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, index, amount)))
        );

        if (!MerkleProof.verify(proof, tournament.merkleRoot, leaf)) {
            revert Errors.InvalidMerkleProof();
        }

        address currency = tournament.config.currency;

        totalValueLocked[currency] -= amount;
        ///@dev tag as claimed to avoid reentrant claims
        BitMaps.setTo(tournament.claimList, index, true);
        ///@dev transfer fund to claimant
        currency.transfer(account, amount);

        emit Claim(tournamentId, account, amount);
    }

    /// @inheritdoc IOptionMarketConfig
    function startTournament(
        Market.StartTournamentParam memory params
    ) external payable override {
        if (
            params.prizePool == 0 ||
            params.winners == 0 ||
            params.closingTime < params.startTime
        ) revert Errors.InvalidTournament();

        uint256 tournamentId = tournamentIds;
        Market.Tournament storage tournament = tournaments[tournamentId];
        Market.TournamentConfig storage config = tournament.config;

        config.currency = params.currency;
        config.winners = params.winners;
        config.startTime = params.startTime;
        config.closingTime = params.closingTime;
        config.maxRefill = MAX_REFILL;
        config.prizePool = params.prizePool;
        config.entryFee = params.entryFee;

        unchecked {
            // increment the ids
            tournamentIds += 1;
            // account for value received to aid token recovery
            totalValueLocked[params.currency] += params.prizePool;
        }

        if (params.currency.isNative()) {
            if (msg.value < params.prizePool) revert Errors.InsufficientRewardFund();
        } else {
            params.currency.safeTransferFrom(msg.sender, address(this), params.prizePool);
        }

        emit StartTournament(
            tournamentId,
            msg.sender,
            params.currency,
            params.prizePool,
            params.entryFee,
            params.winners,
            params.startTime,
            params.closingTime,
            params.title
        );
    }

    /// @inheritdoc IOptionMarketConfig
    function settleTournament(
        uint64 tournamentId,
        bytes32 merkleRoot
    ) external override onlyOperator {
        Market.Tournament storage tournament = tournaments[tournamentId];

        if (tournament.config.startTime == 0) revert Errors.InvalidTournament();
        if (tournament.config.closingTime > block.timestamp) {
            revert Errors.TournamentOngoing();
        }

        tournament.merkleRoot = merkleRoot;
        emit SettleTournament(tournamentId, msg.sender, merkleRoot);
    }

    /// @inheritdoc IOptionMarketConfig
    function extendTournament(
        uint64 tournamentId,
        uint64 closingTime
    ) external override onlyOperator {
        Market.Tournament storage tournament = tournaments[tournamentId];
        uint256 maxExtension = block.timestamp + 12 weeks;

        // ensure tournament exist
        if (tournament.config.startTime == 0) revert Errors.InvalidTournament();
        // ensure new closing time is in the future
        if (
            tournament.config.closingTime > closingTime ||
            block.timestamp > closingTime ||
            closingTime > maxExtension
        ) {
            revert Errors.InvalidTimeConfig();
        }

        tournament.config.closingTime = uint48(closingTime);
        emit ExtendTournament(tournamentId, closingTime);
    }

    /// @inheritdoc IOptionMarketConfig
    function adjustMarketReward(
        MarketId id,
        uint16 reward
    ) external override onlyOperator {
        Market.MarketInfo storage market = markets[id];
        if (!market.config.isInitialized) revert Errors.MarketDoesNotExist();
        if (reward > BASIS_POINT) revert Errors.RewardExceedsMax();

        market.config.reward = reward;
        emit AdjustMarketReward(id, reward);
    }

    /// @inheritdoc IOptionMarketConfig
    function createMarket(
        MarketId id,
        uint16 reward,
        uint32 minInterval,
        uint32 maxInterval
    ) external override onlyOwner {
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
    function adjustMarketExpiry(
        MarketId id,
        uint32 minExpiry,
        uint32 maxExpiry
    ) external override onlyOperator {
        Market.Config storage config = markets[id].config;

        if (!config.isInitialized) revert Errors.MarketDoesNotExist();
        if (minExpiry < 60 || minExpiry > maxExpiry) revert Errors.InvalidTimeConfig();

        config.minExpiry = minExpiry;
        config.maxExpiry = maxExpiry;

        emit AdjustMarketExpiry(id, minExpiry, maxExpiry);
    }

    /// @inheritdoc IOptionMarketConfig
    function pause(MarketId id) external override onlyOwnerOrOperator {
        Market.Config storage config = markets[id].config;

        if (!config.isInitialized) revert Errors.MarketDoesNotExist();
        if (config.paused) revert Errors.MarketPaused();

        config.paused = true;
        emit Pause(id);
    }

    /// @inheritdoc IOptionMarketConfig
    function unpause(MarketId id) external override onlyOwnerOrOperator {
        Market.Config storage config = markets[id].config;

        if (!config.isInitialized) revert Errors.MarketDoesNotExist();
        if (!config.paused) revert Errors.MarketNotPaused();

        config.paused = false;
        emit UnPause(id);
    }

    /// @inheritdoc IOptionMarketConfig
    function recoverToken(
        address currency,
        address recipient,
        uint256 amount
    ) external override onlyOwner {
        // Ensure recovering will not have a negative balance impact
        uint256 balanceBefore = currency.balanceOf(address(this));
        uint256 balanceAfter = balanceBefore - totalValueLocked[currency];

        if (balanceAfter < amount) revert Errors.InsufficientBalance();

        currency.transfer(recipient, amount);
        emit RecoverToken(currency, recipient, amount);
    }

    /// @inheritdoc IProtocolFees
    function collectFees(
        address currency,
        address recipient,
        uint256 amount
    ) external override onlyOwner returns (uint256 amountCollected) {
        /// @notice Ensures protocol manager can only claim what is owed
        if (amount > protocolFees[currency]) revert Errors.InsufficientBalance();
        amountCollected = (amount == 0) ? protocolFees[currency] : amount;

        protocolFees[currency] -= amount;
        totalValueLocked[currency] -= amountCollected;

        currency.transfer(recipient, amountCollected);
        emit CollectFees(msg.sender, recipient, currency, amountCollected);
    }

    /// @inheritdoc IProtocolFees
    function unclaimedFees(
        address currency
    ) external view override returns (uint256 amount) {
        amount = protocolFees[currency];
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

        IPyth.PriceFeed[] memory priceFeeds = pyth.parsePriceFeedUpdates{
            value: updateFee
        }(
            updateData,
            priceFeedIds,
            minPublishTime,
            uint64(minPublishTime + maxSecondsOffset)
        );

        IPyth.PriceFeed memory priceFeed = priceFeeds[0];
        IPyth.Price memory price = priceFeed.price;

        latestPrice = price.price;
    }

    function takePosition(
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

        unchecked {
            // deduct entrant balance
            entrant.balance -= investment;
            entrant.positionCount += 1;
            entrant.unsettled += 1;
        }

        // fetch the strike price from Pyth Network oracle
        strikePrice = parsePriceData(
            MarketId.unwrap(id),
            priceUpdate,
            uint64(block.timestamp - MAX_SECONDS_DELAY),
            MAX_SECONDS_DELAY
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
