// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {OptionMarket} from "../src/OptionMarket.sol";

contract DeployOptionMarket is Script {
    struct DeploymentParams {
        address pyth;
        address owner;
    }

    function readEnvFile() internal view returns (DeploymentParams memory params) {
        // Pyth network oracle address on the deployment chain
        params.pyth = vm.envAddress("PYTH_ORACLE_ADDRESS");
        require(params.pyth != address(0), "Invalid oracle address");

        params.owner = vm.envAddress("OWNER");
        require(params.owner != address(0), "Owner not set");
    }

    function run() public {
        DeploymentParams memory params = readEnvFile();
        vm.startBroadcast();
        new OptionMarket(params.owner, params.pyth);
        vm.stopBroadcast();
    }
}
