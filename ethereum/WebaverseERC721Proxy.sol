// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC721.sol";

contract WebaverseERC721Proxy {
    address globalOwner;
    uint256 chainId;
    WebaverseERC721 parent;
    mapping (bytes32 => bool) usedWithdrawHashes;
    
    constructor (address parentAddress, uint256 _chainId) public {
        globalOwner = msg.sender;
        chainId = _chainId;
        parent = WebaverseERC721(parentAddress);
    }

    event Withdrew(address from, uint256 tokenId, uint256 timestamp);
    // event Deposited(address to, uint256 tokenId, uint256 timestamp);
    
    function withdraw(address to, uint256 tokenId, uint256 hash, string memory filename, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(to, tokenId, hash, keccak256(abi.encodePacked(filename)), timestamp, chainId);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256(message)));
        address contractAddress = address(this);
        require(ecrecover(prefixedHash, v, r, s) == globalOwner, "invalid signature");
        require(!usedWithdrawHashes[prefixedHash], "hash already used");
        usedWithdrawHashes[prefixedHash] = true;

        if (!parent.tokenExists(tokenId)) {
            parent.mintTokenId(contractAddress, tokenId, hash, filename);
        }
        parent.safeTransferFrom(contractAddress, to, tokenId);
        
        emit Withdrew(to, tokenId, timestamp);
    }
    /* function deposit(address from, uint256 tokenId, uint256 timestamp) public {
        address contractAddress = address(this);
        parent.safeTransferFrom(from, contractAddress, tokenId);

        emit Deposited(from, tokenId, timestamp);
    } */
}
