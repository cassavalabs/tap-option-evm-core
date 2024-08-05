// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {IProtocolFees} from "./interfaces/IProtocolFees.sol";
import {Currency} from "./libraries/Currency.sol";
import {Errors} from "./libraries/Errors.sol";
import {Authorization} from "./auth/Authorization.sol";

abstract contract ProtocolFees is IProtocolFees, Authorization {
    using Currency for address;

    uint16 public constant MAX_PROTOCOL_FEE = 1000; //10%
    uint16 public constant BASIS_POINT = 10_000;

    uint16 public protocolFee;
    /// @dev keep track of fees owned to the protocol
    mapping(address currency => uint256 accruedFee) public protocolFees;

    constructor(address _owner) Authorization(_owner) {
        _setProtocolFee(MAX_PROTOCOL_FEE);
    }

    /// @inheritdoc IProtocolFees
    function collectProtocolFees(address currency, address recipient, uint256 amount)
        external
        override
        onlyOwner
        returns (uint256 amountCollected)
    {
        /// @notice Ensures protocol manager can only claim what is owed
        if (amount > protocolFees[currency]) revert Errors.InsufficientBalance();
        amountCollected = (amount == 0) ? protocolFees[currency] : amount;

        protocolFees[currency] -= amount;
        deductTVL(currency, amountCollected);

        currency.transfer(recipient, amountCollected);
        emit CollectProtocolFees(msg.sender, recipient, currency, amountCollected);
    }

    /// @inheritdoc IProtocolFees
    function setProtocolFee(uint16 fee) external override onlyOwner {
        _setProtocolFee(fee);
    }

    /// @inheritdoc IProtocolFees
    function unclaimedProtocolFees(address currency) external view override returns (uint256 amount) {
        amount = protocolFees[currency];
    }

    function accountProtocolFee(address currency, uint256 amount) internal {
        uint256 fee = (amount * protocolFee) / BASIS_POINT;
        protocolFees[currency] += fee;
    }

    function deductTVL(address currency, uint256 amount) internal virtual;

    function _setProtocolFee(uint16 fee) private {
        if (fee > MAX_PROTOCOL_FEE) revert Errors.FeeExceedsMaximum();

        protocolFee = fee;
        emit SetProtocolFee(fee);
    }
}
