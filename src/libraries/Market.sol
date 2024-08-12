// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {BitMaps} from "./BitMaps.sol";
import {MarketId} from "./MarketId.sol";
import {Position} from "./Position.sol";

library Market {
    /// @notice meta data for each tournament, should probably fit in 3 slots
    struct TournamentConfig {
        // token address for tickets/prize pool
        address currency;
        // timestamp when tournament will start
        uint48 startTime;
        // timestamp when tournament will end
        uint48 closingTime;
        // the fee to join tournament
        uint208 entryFee;
        // number of winners
        uint24 winners;
        // max number of refill for tournament
        uint24 maxRefill;
        // the amount to be distributed
        uint256 prizePool;
    }

    struct Tournament {
        TournamentConfig config;
        // merkly root for claiming reward
        bytes32 merkleRoot;
        // map to track if reward is already claimed
        BitMaps.BitMap claimList;
        // map of users tournament account
        mapping(address => Entrant) entrants;
    }

    /// @dev trying as much as possible to fit into a slot
    struct Entrant {
        uint176 balance;
        uint24 refillCount;
        uint24 unsettled;
        uint24 positionCount;
        bool isRegistered;
    }

    struct Config {
        /// the minimum option expiration in seconds
        uint112 minExpiry;
        /// the maximum option expiration in seconds
        uint112 maxExpiry;
        /// the percentage reward for winning positions
        uint16 reward;
        /// false if the market is open otherwise true
        bool paused;
        /// true if the market has been initialized
        bool isInitialized;
    }

    struct MarketInfo {
        Config config;
        /// Keeps track of user market tournament position sequence
        mapping(address account => mapping(uint256 tournamentId => uint256 seqId)) sequenceIds;
        /// keeps track of users positions in this market
        mapping(bytes32 positionId => Position.State) positions;
    }

    struct StartTournamentParam {
        // token address for tickets/prize pool
        address currency;
        // number of winners
        uint24 winners;
        // timestamp when tournament will start
        uint48 startTime;
        // timestamp when tournament will end
        uint48 closingTime;
        // the amount to be distributed
        uint256 prizePool;
        // the fee to join tournament
        uint208 entryFee;
        // title of tournament
        string title;
    }
}
