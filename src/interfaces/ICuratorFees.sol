// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

interface ICuratorFees {
    /**
     * @dev Emitted when a tournament curator collects accrued fee
     *
     * @param tournamentId the tournament fee is accrued to
     * @param collector The transaction sender
     * @param token The token address
     * @param amount Amount collected
     */
    event CollectFee(uint256 indexed tournamentId, address indexed collector, address token, uint256 amount);

    /**
     * @dev Allows tournament creator to claim accrued fees in `tournamentId`
     *
     * @param tournamentId the tournament fee is accrued to
     */
    function collectFees(uint64 tournamentId) external;

    /**
     * @notice A function to get accumulated curators fee
     *
     * @param tournamentId the tournament fee is accrued to
     * @return amount of unclaimed fees
     */
    function unclaimedFees(uint64 tournamentId) external view returns (uint256 amount);
}
