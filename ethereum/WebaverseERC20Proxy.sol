// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC20.sol";
import './IERC721Receiver.sol';

contract WebaverseERC20Proxy {
    address signer; // signer oracle address
    uint256 chainId; // unique chain id
    WebaverseERC20 parent; // managed ERC20 contract
    uint256 deposits; // amount deposited in this contract
    mapping (bytes32 => bool) usedWithdrawHashes; // deposit hashes that have been used up (replay protection)
    
    // 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
    constructor (address parentAddress, address signerAddress, uint256 _chainId) public {
        signer = signerAddress;
        chainId = _chainId;
        parent = WebaverseERC20(parentAddress);
    }

    event Withdrew(address indexed from, uint256 indexed amount, uint256 indexed timestamp); // logs the fact that we withdrew oracle-signed fungible tokens
    event Deposited(address indexed from, uint256 indexed amount); // used by the oracle when signing
    
    function setSigner(address newSigner) public {
        require(msg.sender == signer, "new signer can only be set by old signer");
        signer = newSigner;
    }
    
    // 0x08E242bB06D85073e69222aF8273af419d19E4f6, 1, 10, 0xc336b0bb5cac4584d79e77b1680ab789171ebc95f44f68bb1cc0a7b1174058ad, 0x72b888e952c0c39a8054f2b6dc41df645f5d4dc3d9cc6118535d88aa34945440, 0x1c
    function withdraw(address to, uint256 amount, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(to, amount, timestamp, chainId);
        bytes32 messageHash = keccak256(message);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, messageHash));
        require(ecrecover(prefixedHash, v, r, s) == signer, "invalid signature");
        require(!usedWithdrawHashes[prefixedHash], "hash already used");
        usedWithdrawHashes[prefixedHash] = true;

        bool needsMint = deposits < amount;
        uint256 balanceNeeded = amount - deposits;
        if (needsMint) {
            deposits += balanceNeeded;
        }
        deposits -= amount;

        emit Withdrew(to, amount, timestamp);

        if (needsMint) {
          address contractAddress = address(this);
          parent.mint(contractAddress, balanceNeeded);
        }

        require(parent.transfer(to, amount), "transfer failed");
    }
    function deposit(address to, uint256 amount) public {
        deposits += amount;

        emit Deposited(to, amount);

        address from = msg.sender;
        address contractAddress = address(this);
        require(parent.transferFrom(from, contractAddress, amount), "transfer failed");
    }
    
    function withdrawNonceUsed(address to, uint256 amount, uint256 timestamp) public view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(to, amount, timestamp, chainId);
        bytes32 messageHash = keccak256(message);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, messageHash));
        return usedWithdrawHashes[prefixedHash];
    }
}
