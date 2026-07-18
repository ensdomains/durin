// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ***********************************************
// ▗▖  ▗▖ ▗▄▖ ▗▖  ▗▖▗▄▄▄▖ ▗▄▄▖▗▄▄▄▖▗▄▖ ▗▖  ▗▖▗▄▄▄▖
// ▐▛▚▖▐▌▐▌ ▐▌▐▛▚▞▜▌▐▌   ▐▌     █ ▐▌ ▐▌▐▛▚▖▐▌▐▌
// ▐▌ ▝▜▌▐▛▀▜▌▐▌  ▐▌▐▛▀▀▘ ▝▀▚▖  █ ▐▌ ▐▌▐▌ ▝▜▌▐▛▀▀▘
// ▐▌  ▐▌▐▌ ▐▌▐▌  ▐▌▐▙▄▄▖▗▄▄▞▘  █ ▝▚▄▞▘▐▌  ▐▌▐▙▄▄▖
// ***********************************************

import {ENS} from "@ensdomains/ens-contracts/registry/ENS.sol";
import {IExtendedResolver} from "@ensdomains/ens-contracts/resolvers/profiles/IExtendedResolver.sol";
import {NameCoder} from "@ensdomains/ens-contracts/utils/NameCoder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {strings} from "@arachnid/string-utils/strings.sol";

import {IOperationRouter} from "./interfaces/IOperationRouter.sol";
import {SignatureVerifier} from "./lib/SignatureVerifier.sol";

interface IResolverService {
    function stuffedResolveCall(
        bytes calldata name,
        bytes calldata data,
        uint64 targetChainId,
        address targetRegistryAddress
    )
        external
        view
        returns (bytes memory result, uint64 expires, bytes memory sig);
}

interface IResolver {
    function addr(bytes32 node) external view returns (address);
}

interface INameWrapper {
    function ownerOf(uint256 id) external view returns (address owner);
}

interface IV2EthRegistry {
    function findOwner(string calldata label) external view returns (address owner);
}

/// @author NameStone
/// @notice ENS resolver that directs all queries to a CCIP Read gateway.
/// @dev Callers must implement EIP-3668 and ENSIP-10.
contract L1Resolver is IExtendedResolver, Ownable {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct L2Registry {
        uint64 chainId;
        address registryAddress;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    ENS public constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    IV2EthRegistry public constant v2EthRegistry = IV2EthRegistry(0xDEDB92913A25abE1f7BCDD85D8A344a43B398B67);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    string public url;
    address public signer;
    INameWrapper public immutable nameWrapper;

    mapping(bytes32 node => L2Registry l2Registry) public l2Registry;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event L2RegistrySet(
        bytes32 node,
        uint64 targetChainId,
        address targetRegistryAddress
    );
    event GatewayChanged(string url);
    event SignerChanged(address signer);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error InvalidSignature();
    error UnsupportedName();
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _url,
        address _signer,
        address _owner
    ) Ownable(_owner) {
        url = _url;
        emit GatewayChanged(_url);
        signer = _signer;
        emit SignerChanged(_signer);

        // Get the NameWrapper address from namewrapper.eth
        // This allows us to have the same deploy bytecode on mainnet and sepolia
        bytes32 _wrapperNode = 0xdee478ba2734e34d81c6adc77a32d75b29007895efa2fe60921f1c315e1ec7d9;
        address _wrapperResolver = ens.resolver(_wrapperNode);
        address _wrapperAddr = IResolver(_wrapperResolver).addr(_wrapperNode);
        nameWrapper = INameWrapper(_wrapperAddr);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Specify the L2 registry for a given ENSv2 name. Enter a 2LD label, e.g. "nick" for "nick.eth".
    function setL2RegistryV2(
        string calldata label,
        uint64 targetChainId,
        address targetRegistryAddress
    ) external {
        address owner = v2EthRegistry.findOwner(label);
        if (owner != msg.sender) {
            revert Unauthorized();
        }

        bytes32 labelhash = keccak256(bytes(label));
        bytes32 parentNode = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae; // .eth
        bytes32 node = keccak256(abi.encodePacked(parentNode, labelhash));
        
        l2Registry[node] = L2Registry({
            chainId: targetChainId,
            registryAddress: targetRegistryAddress
        });
        emit L2RegistrySet(node, targetChainId, targetRegistryAddress);
    }

    /// @notice Specify the L2 registry for a given ENSv1 name. Should only be used with 2LDs, e.g. "nick.eth".
    function setL2Registry(
        bytes32 node,
        uint64 targetChainId,
        address targetRegistryAddress
    ) external {
        address owner = ens.owner(node);

        if (owner == address(nameWrapper)) {
            owner = nameWrapper.ownerOf(uint256(node));
        }

        if (owner != msg.sender) {
            revert Unauthorized();
        }

        l2Registry[node] = L2Registry({
            chainId: targetChainId,
            registryAddress: targetRegistryAddress
        });
        emit L2RegistrySet(node, targetChainId, targetRegistryAddress);
    }

    /// @notice Resolves a name, as specified by ENSIP 10.
    /// @param name The DNS-encoded name to resolve.
    /// @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
    /// @return The return data, ABI encoded identically to the underlying function.
    function resolve(
        bytes calldata name,
        bytes calldata data
    ) external view override returns (bytes memory) {
        string memory decodedName = NameCoder.decode(name); // 'sub.name.eth'
        strings.slice memory s = strings.toSlice(decodedName);
        strings.slice memory delim = strings.toSlice(".");
        string[] memory parts = new string[](strings.count(s, delim) + 1);

        // Populate the parts array into ['sub', 'name', 'eth']
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = strings.toString(strings.split(s, delim));
        }

        // get the 2LD + TLD (final 2 parts), regardless of how many labels the name has
        string memory parentName = string.concat(
            parts[parts.length - 2],
            ".",
            parts[parts.length - 1]
        );

        // Encode the parent name
        bytes memory parentNameBytes = NameCoder.encode(parentName);
        bytes32 parentNode = NameCoder.namehash(parentNameBytes, 0);

        L2Registry memory targetL2Registry = l2Registry[parentNode];

        // If the calldata is intended for `getOperationHandler()`, throw the ERC-7884 error
        if (bytes4(data) == IOperationRouter.getOperationHandler.selector) {
            revert IOperationRouter.OperationHandledOnchain(
                targetL2Registry.chainId,
                targetL2Registry.registryAddress
            );
        }

        return
            stuffedResolveCall(
                name,
                data,
                targetL2Registry.chainId,
                targetL2Registry.registryAddress
            );
    }

    /// @notice Callback used by CCIP read compatible clients to parse and verify the response.
    function resolveWithProof(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns (bytes memory) {
        (address _signer, bytes memory result) = SignatureVerifier.verify(
            extraData,
            response
        );

        if (_signer != signer) {
            revert InvalidSignature();
        }

        return result;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IExtendedResolver).interfaceId ||
            interfaceId == 0x01ffc9a7; // ERC-165 interface
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the URL for the resolver service.
    function setURL(string calldata _url) external onlyOwner {
        url = _url;
        emit GatewayChanged(_url);
    }

    /// @notice Sets the signers for the resolver service.
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
        emit SignerChanged(_signer);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Add target registry info to the CCIP Read error.
    function stuffedResolveCall(
        bytes calldata name,
        bytes calldata data,
        uint64 targetChainId,
        address targetRegistryAddress
    ) internal view returns (bytes memory) {
        bytes memory callData = abi.encodeWithSelector(
            IResolverService.stuffedResolveCall.selector,
            name,
            data,
            targetChainId,
            targetRegistryAddress
        );

        string[] memory urls = new string[](1);
        urls[0] = url;

        revert OffchainLookup(
            address(this), // sender
            urls, // urls
            callData, // callData
            L1Resolver.resolveWithProof.selector, // callbackFunction
            callData // extraData
        );
    }
}
