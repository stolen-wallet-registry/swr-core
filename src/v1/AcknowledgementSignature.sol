// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {EIP712Acknowledgement} from "@utils/EIP712Acknowledgement.sol";
import {CommonUtils} from "@utils/CommonUtils.sol";

/// @author FooBar
/// @title A simple FooBar example
abstract contract AcknowledgementSignature is EIP712Acknowledgement {
    error Acknowledgement__invalidSigner();     // 0
    error Acknowledgement__invalidForwarder();  // 1
    error Acknowledgement__signatureExpired();  // 2
    error Acknowledgement__forwarderExpired();  // 3
    error Acknowledgement__forwarderNotFound(); // 4

    bytes32 private constant ACKNOWLEDGEMENT_TYPEHASH =
        keccak256("AcknowledgementOfRegistry(address owner,address forwarder,uint256 nonce,uint256 deadline)");

    event AcknowledgementEvent(address indexed owner, bool indexed isSponsored);

    // solhint-disable-next-line no-empty-blocks
    constructor() EIP712Acknowledgement("AcknowledgementOfRegistry", "4") {}

    function verifyAcknowledgement(
        uint256 deadline,
        uint256 nonce,
        address owner,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address recoveredWallet) {
        // ensure signature was sent within the time limit
        if (deadline <= block.timestamp) revert Acknowledgement__signatureExpired();

        bytes32 digest = _hashTypedDataV4Acknowledgement(
            keccak256(abi.encode(ACKNOWLEDGEMENT_TYPEHASH, owner, msg.sender, nonce, deadline))
        );

        address recoveredWallet = ECDSA.recover(digest, v, r, s);

        if (recoveredWallet == address(0)) revert Acknowledgement__invalidSigner();
        if (recoveredWallet != owner) revert Acknowledgement__invalidSigner();
    }

    function getDeadline() public view returns (uint256) {
        return CommonUtils._getDeadline();
    }

    // function generateHashStruct(address forwarder) public view returns (uint256 deadline, bytes32 hashStruct) {
    //     uint256 deadline = _getDeadline();
    //     bytes32 hashStruct = keccak256(
    //         abi.encode(ACKNOWLEDGEMENT_TYPEHASH, msg.sender, forwarder, nonces[msg.sender], deadline)
    //     );
    //
    //     return (deadline, hashStruct);
    // }
}
