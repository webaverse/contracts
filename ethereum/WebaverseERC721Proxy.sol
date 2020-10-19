// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC721.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
contract WebaverseERC721Proxy {
    bool isDynamic = true;
    mapping (bytes32 => bool) usedWithdrawHashes;
    WebaverseERC721 parent;
    
    constructor (address parentAddress) public {
        parent = WebaverseERC721(parentAddress);
    }

    event Withdrew(address from, uint256 tokenId, uint256 timestamp);
    event Deposited(address to, uint256 tokenId, uint256 timestamp);
    
    function withdraw(address to, uint256 tokenId, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(to, tokenId, timestamp, isDynamic);
        bytes32 messageHash = keccak256(message);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, messageHash));
        address contractAddress = address(this);
        require(ecrecover(prefixedHash, v, r, s) == contractAddress, "invalid signature");
        require(!usedWithdrawHashes[prefixedHash]);
        usedWithdrawHashes[prefixedHash] = true;

        parent.safeTransferFrom(contractAddress, to, tokenId);
        
        emit Withdrew(to, tokenId, timestamp);
    }
    function deposit(address from, uint256 tokenId, uint256 timestamp) public {
        address contractAddress = address(this);
        parent.safeTransferFrom(from, contractAddress, tokenId);

        emit Deposited(from, tokenId, timestamp);
    }
}
