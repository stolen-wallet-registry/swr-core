// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {EIP712Registration} from "@utils/EIP712Registration.sol";
import {CommonUtils} from "@utils/CommonUtils.sol";

/// @author FooBar
/// @title A simple FooBar example
abstract contract RegistrationSignature is EIP712Registration {
    error Registration__invalidSigner();         // 0
    error Registration__invalidForwarder();      // 1
    error Registration__signatureExpired();      // 2
    error Registration__forwarderExpired();      // 3
    error Registration__userAlreadyRegistered(); // 4
    error Registration__walletNotRegistered();   // 5
    error Registration__notEnoughFunds();        // 6

    bytes32 private constant REGISTRATION_TYPEHASH =
        keccak256("Registration(address owner,address forwarder,uint256 nonce,uint256 deadline)");

    // solhint-disable-next-line no-empty-blocks
    constructor() EIP712Registration("Registration", "4") {}

    function verifyRegistration(
        uint256 deadline,
        uint256 nonce,
        address owner,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (address recoveredWallet) {
        if (deadline <= block.timestamp) revert Registration__signatureExpired();

        bytes32 digest = _hashTypedDataV4Registration(
            keccak256(abi.encode(REGISTRATION_TYPEHASH, owner, msg.sender, nonce, deadline))
        );

        address recoveredWallet = ECDSA.recover(digest, v, r, s);
        if (recoveredWallet == address(0)) revert Registration__invalidSigner();
        if (recoveredWallet != owner) revert Registration__invalidSigner();
    }
}
