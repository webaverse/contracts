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
    function setMetadata2(address owner, string memory key, string memory value, string memory key2, string memory value2) public {
        require(msg.sender == owner);
        addressToMetadata[owner][key] = value;
        addressToMetadata[owner][key2] = value2;
    }
    function setMetadata3(address owner, string memory key, string memory value, string memory key2, string memory value2, string memory key3, string memory value3) public {
        require(msg.sender == owner);
        addressToMetadata[owner][key] = value;
        addressToMetadata[owner][key2] = value2;
        addressToMetadata[owner][key3] = value3;
    }
    function setMetadata4(address owner, string memory key, string memory value, string memory key2, string memory value2, string memory key3, string memory value3, string memory key4, string memory value4) public {
        require(msg.sender == owner);
        addressToMetadata[owner][key] = value;
        addressToMetadata[owner][key2] = value2;
        addressToMetadata[owner][key3] = value3;
        addressToMetadata[owner][key4] = value4;
    }
    function setMetadata4(address owner, string memory key, string memory value, string memory key2, string memory value2, string memory key3, string memory value3, string memory key4, string memory value4, string memory key5, string memory value5) public {
        require(msg.sender == owner);
        addressToMetadata[owner][key] = value;
        addressToMetadata[owner][key2] = value2;
        addressToMetadata[owner][key3] = value3;
        addressToMetadata[owner][key4] = value4;
        addressToMetadata[owner][key5] = value5;
    }
}
