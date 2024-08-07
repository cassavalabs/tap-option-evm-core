// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

/// @dev This token contract simulates the ERC20 representation of a native token where on `transfer` and `transferFrom` the native balances are modified using a precompile
contract MockERC20 is Test {
    string public name;
    string public symbol;
    uint8 public decimals;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function mint(address account, uint256 amount) external {
        vm.deal(account, amount);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(src.balance >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "");
            allowance[src][msg.sender] -= wad;
        }

        vm.deal(src, src.balance - wad);
        vm.deal(dst, dst.balance + wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return account.balance;
    }
}
