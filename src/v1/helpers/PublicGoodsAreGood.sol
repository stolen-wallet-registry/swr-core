// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract ENS {
    function resolver(bytes32 node) public view virtual returns (ENSResolver);
}

abstract contract ENSResolver {
    function addr(bytes32 node) public view virtual returns (address);
}

/// @author TODO
/// @title Public goods are good.
library PublicGoodsAreGood {
    enum SOURCE {
        OPTIMISM,
        PROTOCOL_GUILD
    }

    address public constant ENS_RESOVLER_ADDRESS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    bytes32 public constant PROTOCOL_GUILD_ENS = "protocolguild.eth";
    bytes32 public constant OP_RETROACTIVE_GOODS_ENS = "OP-retro-goods.eth";
    address public constant PROTOCOL_GUILD_ADRESS = 0x1230f3c6B9Cdf2f4b7D406EBC010E71dFb20eEF4; // vanity address
    address public constant OP_RETROACTIVE_GOODS_ADRESS = 0x9876644568157Cc35c0aD942B4Ca2de2124b3732; // vanity address

    ENS public constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    // function getOptimismFundingAddress() public view returns (address) {
    //     return getFundingAddress(SOURCE.OPTIMISM);
    // }

    // function geProtocolGoodsFundingAddress() public view returns (address) {
    //     return getFundingAddress(SOURCE.PROTOCOL_GUILD);
    // }

    // function getFundingAddress(SOURCE source) public returns (address) {
    //     if (source == SOURCE.OPTIMISM) {
    //         return resolveOptimismRetroactiveAddress();
    //     } else {
    //         return resolveProtcolGuildAddress();
    //     }
    // }

    // /// @notice Explain to an end user what this does
    // /// @dev Explain to a developer any extra details
    // function resolveProtcolGuildAddress() internal view returns (address) {
    //     ENSResolver resolver = ens.resolver(PROTOCOL_GUILD_ENS);
    //     return resolver.addr(PROTOCOL_GUILD_ENS);
    // }

    // function resolveOptimismRetroactiveAddress() internal view returns (address) {
    //     ENSResolver resolver = ens.resolver(OP_RETROACTIVE_GOODS_ENS);
    //     return resolver.addr(OP_RETROACTIVE_GOODS_ENS);
    // }
}
