// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

interface IProtocolFees {
    /**
     * @dev Emitted when the protocol manager collects accrued fees
     *
     * @param collector The transaction sender
     * @param recipient The destination address
     * @param token The token address
     * @param amount Amount collected
     */
    event CollectProtocolFees(
        address indexed collector, address indexed recipient, address indexed token, uint256 amount
    );

    /**
     * @dev Emitted when a new protocol fee is set
     *
     */
    event SetProtocolFee(uint256 newFee);

    /**
     * @dev Allows protocol managers to collect accrued fee in `token`
     *
     * @param token address of token contract
     * @param recipient address to forward fund to
     * @param amount amount
     */
    function collectProtocolFees(address token, address recipient, uint256 amount)
        external
        returns (uint256 amountCollected);

    /**
     * @dev Allows protocol managers to set fee for market with id `id`
     *
     * @param fee the fee in BPS
     */
    function setProtocolFee(uint16 fee) external;

    /**
     * @notice A function to get accumulated protocol fee
     *
     * @param token address of token to check fees for
     * @return amount of unclaimed protocol fee
     */
    function unclaimedProtocolFees(address token) external view returns (uint256 amount);
}
