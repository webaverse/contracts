// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract WebaverseAccount {
    mapping (address => mapping(string => string)) private addressToMetadata;

    constructor() public {}

    // 0x08E242bB06D85073e69222aF8273af419d19E4f6, "lol"
    function getMetadata(address owner, string memory key) public view returns (string memory) {
        return addressToMetadata[owner][key];
    }
    
    // 0x08E242bB06D85073e69222aF8273af419d19E4f6, "lol", "zol"
    function setMetadata(address owner, string memory key, string memory value) public {
        require(msg.sender == owner);
        addressToMetadata[owner][key] = value;
    }
}
