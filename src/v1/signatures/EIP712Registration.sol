// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4Registration}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Registration {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR__REGISTRATION;
    uint256 private immutable _CACHED_CHAIN_ID__REGISTRATION;
    address private immutable _CACHED_THIS__REGISTRATION;

    bytes32 private immutable _HASHED_NAME__REGISTRATION;
    bytes32 private immutable _HASHED_VERSION__REGISTRATION;
    bytes32 private immutable _TYPE_HASH__REGISTRATION;
    bytes32 constant _SALT__REGISTRATION = 0x86fdecd3151a18dd477feb379432be4107d347c2ee6bc63ca6212c6d674c17f9;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract, bytes32 salt)"
        );
        _HASHED_NAME__REGISTRATION = hashedName;
        _HASHED_VERSION__REGISTRATION = hashedVersion;
        _CACHED_CHAIN_ID__REGISTRATION = block.chainid;
        _CACHED_DOMAIN_SEPARATOR__REGISTRATION = _buildDomainSeparatorRegistration(typeHash, hashedName, hashedVersion);
        _CACHED_THIS__REGISTRATION = address(this);
        _TYPE_HASH__REGISTRATION = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4Registration() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS__REGISTRATION && block.chainid == _CACHED_CHAIN_ID__REGISTRATION) {
            return _CACHED_DOMAIN_SEPARATOR__REGISTRATION;
        } else {
            return
                _buildDomainSeparatorRegistration(
                    _TYPE_HASH__REGISTRATION,
                    _HASHED_NAME__REGISTRATION,
                    _HASHED_VERSION__REGISTRATION
                );
        }
    }

    function _buildDomainSeparatorRegistration(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this), _SALT__REGISTRATION));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4Registration(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4Registration(), structHash);
    }
}
