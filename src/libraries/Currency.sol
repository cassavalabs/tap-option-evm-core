// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IERC20} from "../interfaces/external/IERC20.sol";

/**
 * @title Currency
 * @notice A library to safely manage transfer of both native
 * and non-native token in a gas optimised manner
 */
library Currency {
    using Currency for address;

    address public constant NATIVE = address(0);

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();

    /**
     * @notice A function to handle outbound native and non-native asset transfer
     *
     * @param currency address of token to be transfered
     * @param to address of the token receipient
     * @param amount the amount of value
     */
    function transfer(address currency, address to, uint256 amount) internal {
        if (currency.isNative()) {
            assembly ("memory-safe") {
                // Transfer the ETH and revert if it fails.
                if iszero(call(gas(), to, amount, 0x00, 0x00, 0x00, 0x00)) {
                    mstore(0x00, 0xf4b3b1bc) // `NativeTransferFailed()`.
                    revert(0x1c, 0x04)
                }
            }
        } else {
            IERC20 token = IERC20(currency);
            bool success = _callOptionalReturnBool(
                token,
                abi.encodeCall(token.transfer, (to, amount))
            );

            if (!success) revert ERC20TransferFailed();
        }
    }

    /**
     * @notice Internal function to handle non-native token transferFrom
     *
     * @param currency contract address of token
     * @param from address of source account
     * @param to receipient address
     * @param amount value to transfer
     */
    function safeTransferFrom(
        address currency,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20 token = IERC20(currency);
        bool success = _callOptionalReturnBool(
            token,
            abi.encodeCall(token.transferFrom, (from, to, amount))
        );

        if (!success) revert ERC20TransferFailed();
    }

    /**
     * @notice Internal function to return if a currency is native or ERC20
     * @param token address of token contract
     */
    function isNative(address token) internal pure returns (bool) {
        return token == NATIVE;
    }

    /**
     * @notice Internal function to get the balance of an address
     * @param currency address of token
     * @param account the address to check balance for
     */
    function balanceOf(
        address currency,
        address account
    ) internal view returns (uint256) {
        if (currency.isNative()) {
            return account.balance;
        } else {
            return IERC20(currency).balanceOf(account);
        }
    }

    /**
     * @dev Sets a `amount` amount of tokens as the allowance of `spender` over the
     *  caller's tokens.
     * @param currency address of token
     * @param spender address of spender
     * @param amount amount to approve
     */
    function approve(address currency, address spender, uint256 amount) internal {
        IERC20(currency).approve(spender, amount);
    }

    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return
            success &&
            (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}
