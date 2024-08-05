// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {MarketId} from "../src/libraries/MarketId.sol";
import {OptionMarket} from "../src/OptionMarket.sol";

contract OptionMarketTest is Test {
    bytes32 public immutable BTC_PRICE_FEED_ID = bytes32(uint256(1));
    bytes32 public immutable ETH_PRICE_FEED_ID = bytes32(uint256(2));
    address public immutable NATIVE_GAS_TOKEN = address(0);

    uint256 public constant MAX_INT = 2 ** 256 - 1;

    MarketId public btcMarketId = MarketId.wrap(BTC_PRICE_FEED_ID);
    MarketId public ethMarketId = MarketId.wrap(ETH_PRICE_FEED_ID);

    event Bearish(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 expiry,
        uint256 stake,
        int64 price
    );

    event Bullish(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 expiry,
        uint256 stake,
        int64 price
    );

    event Settle(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 reward,
        int64 closingPrice
    );

    event SignUp(uint256 indexed tournamentId, address indexed account, uint256 amount);

    event Refill(uint256 indexed tournamentId, address indexed account, uint256 amount);

    event Claim(uint256 indexed tournamentId, address indexed account, uint256 amount);

    event StartTournament(
        uint256 indexed tournamentId,
        address initiator,
        address currency,
        uint256 prizePool,
        uint256 entryFee,
        uint256 cost,
        uint64 winners,
        uint64 startTime,
        uint64 endTime,
        uint64 maxRefill,
        string title
    );

    event SettleTournament(
        uint256 indexed tournamentId,
        address indexed operator,
        bytes32 merkleRoot
    );

    event ExtendTournament(uint256 indexed tournamentId, uint64 endTime);

    event AdjustMarketReward(MarketId indexed id, uint16 reward);

    event CreateMarket(
        MarketId indexed id,
        address creator,
        uint16 reward,
        uint32 minInterval,
        uint32 maxInterval
    );

    event AdjustMarketExpiry(MarketId indexed id, uint32 minExpiry, uint32 maxExpiry);

    event Pause(MarketId indexed id);

    event UnPause(MarketId indexed id);

    event RecoverToken(
        address indexed currency,
        address indexed recipient,
        uint256 amount
    );
}
