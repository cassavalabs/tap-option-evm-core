// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IERC20} from "../interfaces/external/IERC20.sol";

/**
 * @title Currency
 * @notice A library to safely manage transfer of both native
 * and non-native token in a gas optimised manner
 * @author Iphyman
 * @author Modified from Solady https://github.com/Vectorized/solady/blob/main/src/utils/SafeTransferLib.sol
 */
library Currency {
    using Currency for address;

    address public constant NATIVE = address(0);

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();

    /// @notice Thrown when ERC20 transferFrom fails
    error TransferFromFailed();

    /**
     * @notice A function to handle outbound native and non-native asset transfer
     *
     * @param currency address of token to be transfered
     * @param to address of the token receipient
     * @param amount the amount of value
     */
    function transfer(address currency, address to, uint256 amount) internal {
        if (currency.isNative()) {
            safeTransferETH(to, amount);
        } else {
            safeTransfer(currency, to, amount);
        }
    }

    /**
     * @dev Send `amount` in wei to `to`
     *
     * @param to the address to send `amount`
     * @param amount the value amount been sent
     */
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xf4b3b1bc) // `NativeTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /**
     * @dev handles safely ERC20 transfer from contract to `to`
     *
     * @param currency the token address
     * @param to the recipient address
     * @param amount the value to transfer
     */
    function safeTransfer(address currency, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), currency, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0xf27f64e4) // `ERC20TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
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
    function safeTransferFrom(address currency, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), currency, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
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
    function balanceOf(address currency, address account) internal view returns (uint256) {
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
}
