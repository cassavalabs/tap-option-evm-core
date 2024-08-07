// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {BitMaps} from "./BitMaps.sol";
import {Currency} from "./Currency.sol";
import {Errors} from "./Errors.sol";
import {MarketId} from "./MarketId.sol";
import {MerkleProof} from "./MerkleProof.sol";
import {Option, OptionLibrary} from "./Option.sol";
import {Position} from "./Position.sol";

library Market {
    using Currency for address;
    using OptionLibrary for Option;
    using Position for *;

    /// @notice meta data for each tournament, should probably fit in 5 slots
    struct TournamentConfig {
        // token address for tickets/prize pool
        address currency;
        // the USD amount users get credited on signup or refill
        uint96 lotAmount;
        // number of winners
        uint64 winners;
        // max number of refill for tournament
        uint64 maxRefill;
        // timestamp when tournament will start
        uint64 startTime;
        // timestamp when tournament will end
        uint64 closingTime;
        // the amount to be distributed
        uint256 prizePool;
        // the fee to join tournament
        uint256 entryFee;
        // price for refilling deplicted balance
        uint256 cost;
    }

    struct Tournament {
        TournamentConfig config;
        // address of the tournament creator
        address creator;
        // total number of unique entrants
        uint48 entrantCount;
        // the total refill count for the tournament
        uint40 refilCount;
        // true if the fees has been claimes
        bool isFeeClaimed;
        // keeps track of fees collected
        uint256 fees;
        // merkly root for claiming reward
        bytes32 merkleRoot;
        // map to track if reward is already claimed
        BitMaps.BitMap claimList;
        // map of users tournament account
        mapping(address => Entrant) entrants;
    }

    /// @dev trying as much as possible to fit into 2 slots
    struct Entrant {
        uint256 balance;
        uint120 refillCount;
        uint64 unsettled;
        uint64 positionCount;
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
        uint64 winners;
        // timestamp when tournament will start
        uint64 startTime;
        // timestamp when tournament will end
        uint64 closingTime;
        // the amount to be distributed
        uint256 prizePool;
        // the fee to join tournament
        uint256 entryFee;
        // price for refilling deplicted balance
        uint256 cost;
        // title of tournament
        string title;
    }
}
