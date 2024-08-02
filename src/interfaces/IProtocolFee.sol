// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

interface IProtocolFee {
    /**
     * @dev Emitted when the protocol manager collects accrued fees
     *
     * @param collector The transaction sender
     * @param receipient The destination address
     * @param token The token address
     * @param amount Amount collected
     */
    event CollectFee(address indexed collector, address indexed receipient, address indexed token, uint256 amount);

    /**
     * @dev Emitted when a new protocol fee is set for market with id of `id`
     *
     */
    event SetProtocolFee(uint256 newFee);

    /**
     * @dev Allows protocol managers to collect accrued fee in `token`
     *
     * @param token address of token contract
     * @param receipient address to forward fund to
     * @param amount amount
     */
    function collectFee(address token, address receipient, uint256 amount) external;

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
    function unclaimedFees(address token) external view returns (uint256 amount);
}
