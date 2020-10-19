// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC20.sol";

contract WebaverseERC20Proxy {
    address globalOwner;
    uint256 chainId;
    WebaverseERC20 parent;
    mapping (bytes32 => bool) usedWithdrawHashes;
    
    constructor (address parentAddress, uint256 _chainId) public {
        globalOwner = msg.sender;
        chainId = _chainId;
        parent = WebaverseERC20(parentAddress);
    }

    event Withdrew(address from, uint256 amount, uint256 timestamp);
    event Deposited(address to, uint256 amount, uint256 timestamp);
    
    function withdraw(address to, uint256 amount, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(to, amount, timestamp, chainId);
        bytes32 messageHash = keccak256(message);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, messageHash));
        address contractAddress = address(this);
        require(ecrecover(prefixedHash, v, r, s) == globalOwner, "invalid signature");
        require(!usedWithdrawHashes[prefixedHash]);
        usedWithdrawHashes[prefixedHash] = true;

        parent.transferFrom(contractAddress, to, amount);
        
        emit Withdrew(to, amount, timestamp);
    }
    function deposit(address from, uint256 amount, uint256 timestamp) public {
        address contractAddress = address(this);
        parent.transferFrom(from, contractAddress, amount);

        emit Deposited(from, amount, timestamp);
    }
}
