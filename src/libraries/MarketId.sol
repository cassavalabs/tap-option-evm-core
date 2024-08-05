// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

type MarketId is bytes32;

function equals(MarketId id, MarketId otherId) pure returns (bool) {
    return MarketId.unwrap(id) == MarketId.unwrap(otherId);
}

function notEquals(MarketId id, MarketId otherId) pure returns (bool) {
    return MarketId.unwrap(id) == MarketId.unwrap(otherId);
}

using {equals as ==, notEquals as !=} for MarketId global;
