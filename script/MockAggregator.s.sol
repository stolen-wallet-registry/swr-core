// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@std/Script.sol";
import "./chainlink/MockV3Aggregator.sol";

contract DeployMockAggregator is Script {
    function run() external {
        vm.startBroadcast();

        MockV3Aggregator mockAggregator = new MockV3Aggregator(8, 155996954280);

        vm.stopBroadcast();
    }
}
