// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

interface IMockAggregator {
    function getLatestPrice() external returns (uint256);
}

interface IStolenWalletRegistry {
    function myWalletWasStolen() external payable;
}

interface IMockPublicGoodsAreGood {
    function fundOptimismRetroactivePublicGoods() external;

    function getLatestETHUSDPrice() external view returns (uint256);
}

contract BaseTestHarness is Test {
    // random address to represent public goods.
    address PUBLIC_GOODS_ADDRESS = 0x1239B0Fb406486B41Bc85B0BC375c371ec0B9Aa6;

    function getRequiredAmount(uint256 pgFee, uint256 ethPrice) public pure returns (uint256) {
        return (pgFee * 10**18) / uint256(ethPrice / 10**8);
    }

    function setupAcknowledgement(
        address forwarder,
        address alice,
        uint256 ethPrice,
        IMockAggregator mockAggregator,
        IStolenWalletRegistry stolenWalletRegistry
    ) public returns (bool) {
        vm.deal(alice, 1 ether);
        vm.startPrank(payable(alice));

        vm.mockCall(
            address(mockAggregator),
            abi.encodeWithSelector(mockAggregator.getLatestPrice.selector),
            abi.encode(ethPrice) // $1698.00000000 / ETH
        );

        stolenWalletRegistry.myWalletWasStolen();

        vm.clearMockedCalls();
        vm.stopPrank();
    }
}
