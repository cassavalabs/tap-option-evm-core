// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {Market} from "../libraries/Market.sol";
import {MarketId} from "../libraries/MarketId.sol";

interface IOptionMarketConfig {
    /**
     * @notice Emitted whenever a new tournament is created
     */
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

    /**
     * @notice Emitted whenever a tournament is finalized
     */
    event SettleTournament(uint256 indexed tournamentId, address indexed operator, bytes32 merkleRoot);

    /**
     * @notice Emitted whenever a tournament expiration is extended
     */
    event ExtendTournament(uint256 indexed tournamentId, uint64 endTime);

    /**
     * @notice Emitted whenever a markets reward rate is adjusted
     */
    event AdjustMarketReward(MarketId indexed id, uint16 reward);

    /**
     * @notice Emitted when a market is created
     */
    event CreateMarket(MarketId indexed id, address creator, uint16 reward, uint32 minInterval, uint32 maxInterval);

    /**
     * @notice Emitted when the market time config is updated
     */
    event AdjustMarketExpiry(MarketId indexed id, uint32 minExpiry, uint32 maxExpiry);

    /**
     * @notice Emitted when a market is paused
     */
    event Pause(MarketId indexed id);

    /**
     * @notice Emitted when a market is unpaused
     */
    event UnPause(MarketId indexed id);

    /// @notice Emitted when native/local tokens are recovered from the contract
    event RecoverToken(address indexed currency, address indexed recipient, uint256 amount);

    /**
     * @dev Allow anyone to start a tournament
     *
     * @param params required object to create a tournament
     */
    function startTournament(Market.StartTournamentParam memory params) external payable;

    /**
     * @dev Allow operators to finalize a tournament
     *
     * @param tournamentId the tournament identifier
     * @param merkleRoot the merkly root for claiming reward
     */
    function settleTournament(uint64 tournamentId, bytes32 merkleRoot) external;

    /**
     * @dev Allow extending tournament close time
     *
     * @param tournamentId tournament id
     * @param endTime the new closing time in seconds
     */
    function extendTournament(uint64 tournamentId, uint64 endTime) external;

    /**
     * @dev Allow adjusting the market percentage reward rate
     *
     * @param id the unique market identifier
     * @param reward the new reward rate in basis point
     */
    function adjustMarketReward(MarketId id, uint16 reward) external;

    /**
     * @dev Allow creating a new option market
     *
     * @param id the Pyth network price feed ID
     * @param reward the percentage reward in basis point
     * @param minInterval the minimum expiry in seconds
     * @param maxInterval the maximum expiry in seconds
     */
    function createMarket(MarketId id, uint16 reward, uint32 minInterval, uint32 maxInterval) external;

    /**
     * @dev Allow re-configuring market option expiry after creation
     *
     * @param id unique market identifier
     * @param minExpiry minimum option expiry in seconds
     * @param maxExpiry maximum option expiry in seconds
     */
    function adjustMarketExpiry(MarketId id, uint32 minExpiry, uint32 maxExpiry) external;

    /**
     * @dev Allow halting market activities
     * @param id the unique market identifier
     */
    function pause(MarketId id) external;

    /**
     * @dev Allow resuming market operations
     * @param id the unique market identifier
     */
    function unpause(MarketId id) external;

    /**
     * @dev useful for recovering native/local tokens sent to the contract by mistake
     *
     * @param currency address of token to withdraw
     * @param receipient address of token receiver
     * @param amount amount of token to withdraw
     */
    function recoverToken(address currency, address receipient, uint256 amount) external;
}
