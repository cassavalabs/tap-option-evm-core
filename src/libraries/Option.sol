// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

type Option is uint8;

library OptionLibrary {
    using OptionLibrary for Option;

    Option public constant BEARISH = Option.wrap(1);
    Option public constant BULLISH = Option.wrap(2);

    function isBearish(Option option) internal pure returns (bool) {
        return Option.unwrap(option) == Option.unwrap(BEARISH);
    }

    function isBullish(Option option) internal pure returns (bool) {
        return Option.unwrap(option) == Option.unwrap(BULLISH);
    }
}
