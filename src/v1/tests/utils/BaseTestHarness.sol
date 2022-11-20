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

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

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
