// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {IAuthorization} from "../interfaces/IAuthorization.sol";

/**
 * @title Authorization
 * @notice Allow owner or operators to securely manage some protocol operations
 */
contract Authorization is IAuthorization {
    address public owner;
    mapping(address account => bool isOperator) public hasOperatorRole;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyOperator() {
        if (!hasOperatorRole[msg.sender]) revert NotOperator();
        _;
    }

    modifier onlyOwnerOrOperator() {
        if (msg.sender != owner && !hasOperatorRole[msg.sender]) revert UnAuthorized();
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /// @inheritdoc IAuthorization
    function transferOwnership(address newOwner) external override onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /// @inheritdoc IAuthorization
    function grantOperatorRole(address account) external override onlyOwner {
        hasOperatorRole[account] = true;
        emit GrantOperatorRole(account);
    }

    /// @inheritdoc IAuthorization
    function revokeOperatorRole(address account) external override onlyOwner {
        hasOperatorRole[account] = false;
        emit RevokeOperatorRole(account);
    }
}
