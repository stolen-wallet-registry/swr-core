// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@std/Script.sol";
import "../src/v1/StolenWalletRegistry.sol";

contract DeployStollenWalletRegistry is Script {
    function run() external {
        vm.startBroadcast();

        // StolenWalletRegistry stolenWalletRegistry = new StolenWalletRegistry(mockAggregator.address);

        vm.stopBroadcast();
    }
}
