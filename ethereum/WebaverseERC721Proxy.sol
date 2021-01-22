// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC721.sol";

contract WebaverseERC721Proxy /* is IERC721Receiver */ {
    // bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    
    address internal signer; // signer oracle address
    uint256 internal chainId; // unique chain id
    WebaverseERC721 internal parent; // managed ERC721 contract
    mapping (uint256 => bool) internal deposits; // whether the token has been deposited in this contract
    mapping (bytes32 => bool) internal usedWithdrawHashes; // deposit hashes that have been used up (replay protection)

    bytes internal prefix = "\x19Ethereum Signed Message:\n32";

    // 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656
    // 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
    constructor (address parentAddress, address signerAddress, uint256 _chainId) public {
        signer = signerAddress;
        chainId = _chainId;
        parent = WebaverseERC721(parentAddress);
    }

    event Withdrew(address indexed from, uint256 indexed tokenId, uint256 indexed timestamp); // logs the fact that we withdrew an oracle-signed token
    event Deposited(address indexed to, uint256 indexed tokenId); // used by the oracle when signing
    
    function setSigner(address newSigner) public {
        require(msg.sender == signer, "new signer can only be set by old signer");
        signer = newSigner;
    }
    
    function setERC721Parent(address newParent) public {
        require(msg.sender == signer, "must be signer");
        parent = WebaverseERC721(newParent);
    }
    
    function withdraw(address to, uint256 tokenId, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked(to, tokenId, timestamp, chainId))));
        address contractAddress = address(this);
        require(ecrecover(prefixedHash, v, r, s) == signer, "invalid signature");
        require(!usedWithdrawHashes[prefixedHash], "hash already used");
        usedWithdrawHashes[prefixedHash] = true;

        bool oldDeposits = deposits[tokenId];

        deposits[tokenId] = false;

        emit Withdrew(to, tokenId, timestamp);

        if (!oldDeposits) {
            parent.mintTokenId(contractAddress, tokenId);
        }

        parent.transferFrom(contractAddress, to, tokenId);
    }
    function deposit(address to, uint256 tokenId) public {
        deposits[tokenId] = true;

        emit Deposited(to, tokenId);

        address from = msg.sender;
        address contractAddress = address(this);
        parent.transferFrom(from, contractAddress, tokenId);
    }
    
    function withdrawNonceUsed(address to, uint256 tokenId, uint256 timestamp) public view returns (bool) {
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked(to, tokenId, timestamp, chainId))));
        return usedWithdrawHashes[prefixedHash];
    }
}
