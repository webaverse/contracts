// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./EnumerableSet.sol";
import "./Math.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
contract WebaverseERC721 is ERC721 {
    using EnumerableSet for EnumerableSet.UintSet;

    bool isDynamic = true;
    mapping (bytes32 => bool) usedWithdrawHashes;

    uint256 nextTokenId = 0;
    mapping (uint256 => uint256) private tokenIdToHash;
    mapping (uint256 => uint256) private hashToTotalSupply;
    mapping (uint256 => mapping(string => string)) private hashToMetadata;
    
    constructor (string memory name, string memory symbol) public ERC721(name, symbol) {
        _setBaseURI("https://tokens.webaverse.com/");
    }

    event Withdrew(address from, uint256 tokenId, uint256 timestamp);
    event Deposited(address to, uint256 tokenId, uint256 timestamp);
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    // 0x08E242bB06D85073e69222aF8273af419d19E4f6, 0x1, 1
    function mint(address to, uint256 hash, string memory filename, uint256 count) public {
        require(isDynamic);
        require(hash != 0);
        require(count > 0);
        require(hashToTotalSupply[hash] == 0);

        uint256 i = 0;
        while (i < count) {
            uint256 tokenId = ++nextTokenId;

            bytes memory _data;
            _safeMint(to, tokenId, _data);

            string memory _tokenURI = uint2str(hash);
            _setTokenURI(tokenId, _tokenURI);

            tokenIdToHash[tokenId] = hash;
            i++;
        }
        hashToTotalSupply[hash] = count;
        hashToMetadata[hash]["filename"] = filename;
    }
    
    function withdraw(address to, uint256 tokenId, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public {
        require(!isDynamic);

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory message = abi.encodePacked(to, tokenId, timestamp);
        bytes32 messageHash = keccak256(message);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, messageHash));
        // bytes32 hash = block.blockhash(block.number);
        address contractAddress = address(this);
        require(ecrecover(prefixedHash, v, r, s) == contractAddress, "invalid signature");
        require(!usedWithdrawHashes[prefixedHash]);
        usedWithdrawHashes[prefixedHash] = true;

        safeTransferFrom(contractAddress, to, tokenId);
        
        emit Withdrew(to, tokenId, timestamp);
    }
    function deposit(address from, uint256 tokenId, uint256 timestamp) public {
        require(!isDynamic);

        address contractAddress = address(this);
        safeTransferFrom(from, contractAddress, tokenId);

        emit Deposited(from, tokenId, timestamp);
    }
    
    function getHash(uint256 tokenId) public view returns (uint256) {
        return tokenIdToHash[tokenId];
    }
    
    // 0x08E242bB06D85073e69222aF8273af419d19E4f6, 0x1
    function balanceOfHash(address owner, uint256 hash) public view returns (uint256) {
        uint256 count = 0;
        uint256 balance = balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            uint256 h = tokenIdToHash[tokenId];
            if (h == hash) {
                count++;
            }
        }
        return count;
    }
    function totalSupplyOfHash(uint256 hash) public view returns (uint256) {
        return hashToTotalSupply[hash];
    }
    
    function getTokenIdsOf(address owner) public view returns (uint256[] memory) {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }
    /* function getToken(uint256 tokenId) public view returns (uint256, string memory) {
        uint256 hash = tokenIdToHash[tokenId];
        string memory filename = getMetadata(hash, "filename");
        return (hash, filename);
    } */
    
    function getMetadata(uint256 tokenId, string memory key) public view returns (string memory) {
        return hashToMetadata[tokenId][key];
    }
    function setMetadata(uint256 tokenId, string memory key, string memory value) public {
        uint256 hash = tokenIdToHash[tokenId];
        require(balanceOfHash(msg.sender, hash) == totalSupplyOfHash(hash));
        hashToMetadata[tokenId][key] = value;
    }
}
