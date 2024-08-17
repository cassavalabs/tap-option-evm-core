// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {MarketId} from "./MarketId.sol";
import {Option, OptionLibrary} from "./Option.sol";

library Position {
    using OptionLibrary for Option;

    /**
     * @dev State represents a structure for users current
     * prediction
     */
    struct State {
        // The amount staked as wager for position
        uint64 investment;
        // The user's choice of either `Bearish` or `Bullish`
        Option option;
        // True if the option has been exercised
        bool settled;
        // The strike price for option
        int64 strikePrice;
        // The closing price of underlying asset
        int64 closingPrice;
        // the option expiry time
        uint48 expiry; // probably not going to overflow in a million years to come
    }

    /**
     * @dev Returns true if a users position won otherwise false
     *
     * @param position The user position
     * @return rewardable true if position expired in the money
     */
    function isRewardable(State memory position) internal pure returns (bool rewardable) {
        if (position.option.isBullish()) {
            rewardable = position.closingPrice > position.strikePrice;
        } else {
            rewardable = position.closingPrice < position.strikePrice;
        }
    }

    /**
     * @dev Abi encoded `marketId`, `sequenceId` and `owner`
     *
     * @param id unique market identifier
     * @param sequenceId incremented sequence Id
     * @param owner address of Postion taker
     *
     * @return positionId Unique id for the users position in round
     */
    function toId(MarketId id, uint256 sequenceId, address owner) internal pure returns (bytes32 positionId) {
        positionId = keccak256(abi.encodePacked(id, sequenceId, owner));
    }
}
