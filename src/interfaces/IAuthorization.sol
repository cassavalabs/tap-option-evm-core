// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

interface IAuthorization {
    /**
     * @notice Emitted whenever a new operator is granted role
     * @param account the new operator address
     */
    event GrantOperatorRole(address indexed account);

    /**
     * @notice Emitted whenever an operator role is revoked
     * @param account the new operator address
     */
    event RevokeOperatorRole(address indexed account);

    /**
     * @notice Emitted whenever the protocol's ownership changes
     * @param prevOwner the previous owner address
     * @param newOwner the new owner address
     */
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    ///@notice Revert when `msg.sender` is not a privileged user
    error UnAuthorized();

    ///@notice Revert when `msg.sender` is not a privileged owner
    error NotOwner();

    ///@notice Revert when `msg.sender` is not a previleged operator
    error NotOperator();

    /**
     * @notice Allow owner to transfer ownership to a new account
     * @param newOwner address of new owner
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Allow owner to grant team members operator roles
     * @param account address to grant role
     */
    function grantOperatorRole(address account) external;

    /**
     * @notice Allow owner to revoke team member operator role
     * @param account address to revoke role
     */
    function revokeOperatorRole(address account) external;
}
