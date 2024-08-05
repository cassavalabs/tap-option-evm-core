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

    /// @notice meta data for each tournament, should probably fit in 2 slots
    struct TournamentConfig {
        // token address for tickets/prize pool
        address currency;
        // number of winners
        uint32 winners;
        // timestamp when tournament will start
        uint48 startTime;
        // timestamp when tournament will end
        uint48 closingTime;
        // max number of refill for tournament
        uint16 maxRefill;
        // the amount to be distributed
        uint80 prizePool;
        // the fee to join tournament
        uint64 entryFee;
        // price for refilling deplicted balance
        uint64 cost;
    }

    struct Tournament {
        TournamentConfig config;
        // address of the tournament creator
        address creator;
        // total number of unique entrants
        uint24 entrantCount;
        // the total refill count for the tournament
        uint24 refilCount;
        // the amount users get credited on signup or refill
        uint40 lotAmount;
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

    /// @dev trying as much as possible to pack in a single slot
    struct Entrant {
        uint32 refillCount;
        uint184 balance;
        uint16 unsettled;
        uint16 positionCount;
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
        uint32 winners;
        // timestamp when tournament will start
        uint48 startTime;
        // timestamp when tournament will end
        uint48 closingTime;
        // max number of refill for tournament
        uint16 maxRefill;
        // the amount to be distributed
        uint80 prizePool;
        // the fee to join tournament
        uint64 entryFee;
        // price for refilling deplicted balance
        uint64 cost;
        // lot amount
        uint40 lotAmount;
        // title of tournament
        string title;
    }
}
