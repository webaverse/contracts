// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC20.sol";
import './IERC721Receiver.sol';

contract WebaverseERC20Proxy {
    address signer;
    uint256 chainId;
    WebaverseERC20 parent;
    mapping (address => uint256) deposits;
    mapping (bytes32 => bool) usedWithdrawHashes;
    
    // 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
    constructor (address parentAddress, address signerAddress, uint256 _chainId) public {
        signer = signerAddress;
        chainId = _chainId;
        parent = WebaverseERC20(parentAddress);
    }

    event Withdrew(address from, uint256 amount, uint256 timestamp);
    event Deposited(address from, uint256 amount);
    
    function setSigner(address newSigner) public {
        require(msg.sender == signer, "new signer can only be set by old signer");
        signer = newSigner;
    }
    
    /* function addr2Bytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
       }
    }
    function bytes2addr(bytes memory b) internal pure returns (address) {
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            }
            if(c >= 65 && c<= 90) {
                result = result * 16 + (c - 55);
            }
            if(c >= 97 && c<= 122) {
                result = result * 16 + (c - 87);
            }
        }
        return address(result);
    }
    function xorMemory(bytes memory a, bytes memory b) internal pure returns (bytes memory) {
       bytes memory c = new bytes(a.length);
       for (uint i = 0; i < a.length; i++) {
           c[i] = a[i] ^ b[i];
       }
       return c;
    } */
    
    // 0x08E242bB06D85073e69222aF8273af419d19E4f6, 1, 10, 0xc336b0bb5cac4584d79e77b1680ab789171ebc95f44f68bb1cc0a7b1174058ad, 0x72b888e952c0c39a8054f2b6dc41df645f5d4dc3d9cc6118535d88aa34945440, 0x1c
    function withdraw(address to, uint256 amount, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(to, amount, timestamp, chainId);
        bytes32 messageHash = keccak256(message);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, messageHash));
        require(ecrecover(prefixedHash, v, r, s) == signer, "invalid signature");
        require(!usedWithdrawHashes[prefixedHash], "hash already used");
        usedWithdrawHashes[prefixedHash] = true;

        address contractAddress = address(this);
        uint256 contractBalance = deposits[to];
        if (contractBalance < amount) {
            uint256 balanceNeeded = amount - contractBalance;
            parent.mint(contractAddress, balanceNeeded);
            deposits[to] += balanceNeeded;
        }

        parent.transfer(to, amount);
        deposits[to] -= amount;
        
        emit Withdrew(to, amount, timestamp);
    }
    function deposit(uint256 amount) public {
        address from = msg.sender;
        address contractAddress = address(this);
        parent.transferFrom(from, contractAddress, amount);

        deposits[from] += amount;

        emit Deposited(from, amount);
    }
}
