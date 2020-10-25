// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC721.sol";

contract WebaverseERC721Proxy /* is IERC721Receiver */ {
    // bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    
    address signer;
    uint256 chainId;
    WebaverseERC721 parent;
    mapping (uint256 => bool) deposits;
    mapping (bytes32 => bool) usedWithdrawHashes;

    // 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
    constructor (address parentAddress, address signerAddress, uint256 _chainId) public {
        signer = signerAddress;
        chainId = _chainId;
        parent = WebaverseERC721(parentAddress);
    }

    event Withdrew(address indexed from, uint256 indexed tokenId, uint256 indexed timestamp);
    event Deposited(address indexed to, uint256 indexed tokenId);
    
    function setSigner(address newSigner) public {
        require(msg.sender == signer, "new signer can only be set by old signer");
        signer = newSigner;
    }
    
    function withdraw(address to, uint256 tokenId, uint256 hash, string memory filename, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(to, tokenId, hash, keccak256(abi.encodePacked(filename)), timestamp, chainId);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256(message)));
        address contractAddress = address(this);
        require(ecrecover(prefixedHash, v, r, s) == signer, "invalid signature");
        require(!usedWithdrawHashes[prefixedHash], "hash already used");
        usedWithdrawHashes[prefixedHash] = true;

        if (!deposits[tokenId]) {
            parent.mintTokenId(contractAddress, tokenId, hash, filename);
            deposits[tokenId] = true;
        }

        parent.transferFrom(contractAddress, to, tokenId);
        deposits[tokenId] = false;
        
        emit Withdrew(to, tokenId, timestamp);
    }
    function deposit(address to, uint256 tokenId) public {
        address from = msg.sender;
        address contractAddress = address(this);
        parent.transferFrom(from, contractAddress, tokenId);

        deposits[tokenId] = true;

        emit Deposited(to, tokenId);
    }
    
    /* function onERC721Received(address, address, uint256, bytes memory) public override returns (bytes4) {
        return _ERC721_RECEIVED;
    } */
}
