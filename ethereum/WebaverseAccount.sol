// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract WebaverseAccount {
    mapping (address => mapping(string => string)) private addressToMetadata;

    constructor() public {}

    function getMetadata(address owner, string memory key) public view returns (string memory) {
        return addressToMetadata[owner][key];
    }
    function setMetadata(address owner, string memory key, string memory value) public {
        require(msg.sender == owner);
        addressToMetadata[owner][key] = value;
    }
}
