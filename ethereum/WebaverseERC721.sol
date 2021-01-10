// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./EnumerableSet.sol";
import "./Math.sol";
import "./WebaverseERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
contract WebaverseERC721 is ERC721 {
    using EnumerableSet for EnumerableSet.UintSet;

    WebaverseERC20 internal erc20Contract; // ERC20 contract for fungible tokens
    uint256 internal mintFee; // ERC20 fee to mint ERC721
    address internal treasuryAddress; // address into which we deposit minting fees
    bool internal isSingleIssue; // whether the token is single issue (name based) or no (hash based)
    bool internal isPublicallyMintable; // whether anyone can mint tokens in this copy of the contract
    mapping (address => bool) internal allowedMinters; // addresses allowed to mint in this copy of the contract
    uint256 internal nextTokenId = 0; // the next token id to use (increases linearly)
    mapping (uint256 => string) internal tokenIdToHash; // map of token id to hash it represents
    mapping (string => uint256) internal hashToStartTokenId; // map of hashes to start of token ids for it
    mapping (string => uint256) internal hashToTotalSupply; // map of hash to total number of tokens for it
    mapping (string => Metadata[]) internal hashToMetadata; // map of hash to metadata key-value store
    mapping (string => address[]) internal hashToCollaborators; // map of hash to addresses that can change metadata
    mapping (uint256 => uint256) internal tokenIdToBalance; // map of tokens to packed balance
    mapping (uint256 => address) internal minters; // map of tokens to minters
    mapping (uint256 => Metadata[]) internal tokenIdToMetadata; // map of token id to metadata key-value store
    mapping (uint256 => address[]) internal tokenIdToCollaborators; // map of token id to addresses that can change metadata

    struct Metadata {
        string key;
        string value;
    }
    struct Token {
        uint256 id;
        string hash;
        string name;
        string ext;
        address minter;
        address owner;
        uint256 balance;
        uint256 totalSupply;
    }
    
    // 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
    constructor (
        string memory name,
        string memory symbol,
        string memory baseUri,
        WebaverseERC20 _erc20Contract,
        uint256 _mintFee,
        address _treasuryAddress,
        bool _isSingleIssue,
        bool _isPublicallyMintable
    ) public ERC721(name, symbol) {
        _setBaseURI(baseUri);
        erc20Contract = _erc20Contract;
        mintFee = _mintFee;
        treasuryAddress = _treasuryAddress;
        isSingleIssue = _isSingleIssue;
        isPublicallyMintable = _isPublicallyMintable;
        allowedMinters[msg.sender] = true;
    }

    function setMintFee(uint256 _mintFee) public {
        require(msg.sender == treasuryAddress, "must be set from treasury address");
        mintFee = _mintFee;
    }
    function setTreasuryAddress(address _treasuryAddress) public {
        require(msg.sender == treasuryAddress, "must be set from treasury address");
        treasuryAddress = _treasuryAddress;
    }

    function getPackedBalance(uint256 tokenId) public view returns (uint256) {
        return tokenIdToBalance[tokenId];
    }
    function pack(address from, uint256 tokenId, uint256 amount) public {
        require(_exists(tokenId), "token id does not exist");

        tokenIdToBalance[tokenId] = SafeMath.add(tokenIdToBalance[tokenId], amount);

        require(erc20Contract.transferFrom(from, address(this), amount), "transfer failed");
    }
    function unpack(address to, uint256 tokenId, uint256 amount) public {
        require(ownerOf(tokenId) == msg.sender, "not your token");
        require(tokenIdToBalance[tokenId] >= amount, "insufficient balance");

        tokenIdToBalance[tokenId] = SafeMath.sub(tokenIdToBalance[tokenId], amount);

        require(erc20Contract.transfer(to, amount), "transfer failed");
    }

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
    
    // 0x08E242bB06D85073e69222aF8273af419d19E4f6, 0x1, "lol", 1
    function mint(address to, string memory hash, string memory name, string memory ext, string memory description, uint256 count) public {
        require(!isSingleIssue, "wrong mint method called");
        require(isPublicallyMintable || isAllowedMinter(msg.sender), "not allowed to mint");
        require(bytes(hash).length > 0, "hash cannot be empty");
        require(count > 0, "count must be greater than zero");
        require(hashToTotalSupply[hash] == 0, "hash already exists");

        hashToStartTokenId[hash] = nextTokenId + 1;

        uint256 i = 0;
        while (i < count) {
            nextTokenId = SafeMath.add(nextTokenId, 1);
            uint256 tokenId = nextTokenId;

            _mint(to, tokenId);
            minters[tokenId] = to;

            tokenIdToHash[tokenId] = hash;
            i++;
        }
        hashToTotalSupply[hash] = count;
        hashToMetadata[hash].push(Metadata("name", name));
        hashToMetadata[hash].push(Metadata("ext", ext));
        hashToMetadata[hash].push(Metadata("description", description));
        hashToCollaborators[hash].push(to);

        if (mintFee != 0) {
            require(erc20Contract.transferFrom(msg.sender, treasuryAddress, mintFee), "mint transfer failed");
        }
    }
    function mintSingle(address to, string memory hash) public {
        require(isSingleIssue, "wrong mint method called");
        require(isPublicallyMintable || isAllowedMinter(msg.sender), "not allowed to mint");

        nextTokenId = SafeMath.add(nextTokenId, 1);
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        minters[tokenId] = to;

        tokenIdToHash[tokenId] = hash;
        hashToTotalSupply[hash] = 1;
        
        if (mintFee != 0) {
            require(erc20Contract.transferFrom(msg.sender, treasuryAddress, mintFee), "mint transfer failed");
        }
    }
    function getMinter(uint256 tokenId) public view returns (address) {
        return minters[tokenId];
    }
    function streq(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    function mintTokenId(address to, uint256 tokenId) public {
        require(isAllowedMinter(msg.sender), "minter not allowed");

        _mint(to, tokenId);
    }

    function setBaseURI(string memory baseURI_) public {
        require(allowedMinters[msg.sender], "only minters can set the base uri");
        setBaseURI(baseURI_);
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI(), uint2str(tokenId)));
    }
    
    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    function isAllowedMinter(address a) public view returns (bool) {
        return allowedMinters[a];
    }
    function addAllowedMinter(address a) public {
        require(isAllowedMinter(msg.sender));
        require(!isAllowedMinter(a), "target is already a minter");
        allowedMinters[a] = true;
    }
    function removeAllowedMinter(address a) public {
        require(isAllowedMinter(msg.sender), "sender is not a minter");
        require(isAllowedMinter(a), "target is not a minter");
        allowedMinters[a] = false;
    }

    function isCollaborator(string memory hash, address a) public view returns (bool) {
        for (uint256 i = 0; i < hashToCollaborators[hash].length; i++) {
            if (hashToCollaborators[hash][i] == a) {
                return true;
            }
        }
        return false;
    }
    function addCollaborator(string memory hash, address a) public {
        require(isCollaborator(hash, msg.sender), "you are not a collaborator");
        require(!isCollaborator(hash, a), "they are already a collaborator");
        hashToCollaborators[hash].push(a);
    }
    function removeCollaborator(string memory hash, address a) public {
        require(isCollaborator(hash, msg.sender), "you are not a collaborator");
        require(isCollaborator(hash, msg.sender), "they are not a collaborator");
        
        uint256 newSize = 0;
        for (uint256 i = 0; i < hashToCollaborators[hash].length; i++) {
            if (hashToCollaborators[hash][i] != a) {
                newSize++;
            }
        }

        address[] memory newCollaborators = new address[](newSize);
        uint256 index = 0;
        for (uint256 i = 0; i < hashToCollaborators[hash].length; i++) {
            address oldCollaborator = hashToCollaborators[hash][i];
            if (oldCollaborator != a) {
                newCollaborators[index++] = oldCollaborator;
            }
        }
        hashToCollaborators[hash] = newCollaborators;
    }

    function isSingleCollaborator(uint256 tokenId, address a) public view returns (bool) {
        for (uint256 i = 0; i < tokenIdToCollaborators[tokenId].length; i++) {
            if (tokenIdToCollaborators[tokenId][i] == a) {
                return true;
            }
        }
        return false;
    }
    function addSingleCollaborator(uint256 tokenId, address a) public {
        require(isSingleCollaborator(tokenId, msg.sender), "you are not a collaborator");
        require(!isSingleCollaborator(tokenId, a), "they are already a collaborator");
        tokenIdToCollaborators[tokenId].push(a);
    }
    function removeSingleCollaborator(uint256 tokenId, address a) public {
        require(isSingleCollaborator(tokenId, msg.sender), "you are not a collaborator");
        require(isSingleCollaborator(tokenId, msg.sender), "they are not a collaborator");
        
        uint256 newSize = 0;
        for (uint256 i = 0; i < tokenIdToCollaborators[tokenId].length; i++) {
            if (tokenIdToCollaborators[tokenId][i] != a) {
                newSize++;
            }
        }

        address[] memory newTokenIdCollaborators = new address[](newSize);
        uint256 index = 0;
        for (uint256 i = 0; i < tokenIdToCollaborators[tokenId].length; i++) {
            address oldTokenIdCollaborator = tokenIdToCollaborators[tokenId][i];
            if (oldTokenIdCollaborator != a) {
                newTokenIdCollaborators[index++] = oldTokenIdCollaborator;
            }
        }
        tokenIdToCollaborators[tokenId] = newTokenIdCollaborators;
    }

    function seal(string memory hash) public {
        require(isCollaborator(hash, msg.sender), "not a collaborator");
        delete hashToCollaborators[hash];
    }

    function getHash(uint256 tokenId) public view returns (string memory) {
        return tokenIdToHash[tokenId];
    }

    // 0x08E242bB06D85073e69222aF8273af419d19E4f6, 0x1
    function balanceOfHash(address owner, string memory hash) public view returns (uint256) {
        uint256 count = 0;
        uint256 balance = balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            string memory h = tokenIdToHash[tokenId];
            if (streq(h, hash)) {
                count++;
            }
        }
        return count;
    }
    function totalSupplyOfHash(string memory hash) public view returns (uint256) {
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
    function tokenByIdFull(uint256 tokenId) public view returns (Token memory) {
        string memory hash;
        string memory name;
        string memory ext;
        if (isSingleIssue) {
            hash = getSingleMetadata(tokenId, "hash");
            name = tokenIdToHash[tokenId];
            ext = getSingleMetadata(tokenId, "ext");
        } else {
            hash = tokenIdToHash[tokenId];
            name = getMetadata(hash, "name");
            ext = getMetadata(hash, "ext");
        }
        address minter = minters[tokenId];
        address owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);
        uint256 totalSupply = hashToTotalSupply[hash];
        return Token(tokenId, hash, name, ext, minter, owner, 0, totalSupply);
        
    }
    function tokenOfOwnerByIndexFull(address owner, uint256 index) public view returns (Token memory) {
        uint256 tokenId = tokenOfOwnerByIndex(owner, index);
        string memory hash;
        string memory name;
        string memory ext;
        if (isSingleIssue) {
            hash = getSingleMetadata(tokenId, "hash");
            name = tokenIdToHash[tokenId];
            ext = getSingleMetadata(tokenId, "ext");
        } else {
            hash = tokenIdToHash[tokenId];
            name = getMetadata(hash, "name");
            ext = getMetadata(hash, "ext");
        }
        address minter = minters[tokenId];
        uint256 balance = balanceOfHash(owner, hash);
        uint256 totalSupply = hashToTotalSupply[hash];
        return Token(tokenId, hash, name, ext, minter, owner, balance, totalSupply);
    }
    
    function getMetadata(string memory hash, string memory key) public view returns (string memory) {
        for (uint256 i = 0; i < hashToMetadata[hash].length; i++) {
            if (streq(hashToMetadata[hash][i].key, key)) {
                return hashToMetadata[hash][i].value;
            }
        }
        return "";
    }
    function setMetadata(string memory hash, string memory key, string memory value) public {
        require(isCollaborator(hash, msg.sender), "not a collaborator");
        
        bool keyFound = false;
        for (uint256 i = 0; i < hashToMetadata[hash].length; i++) {
            if (streq(hashToMetadata[hash][i].key, key)) {
                hashToMetadata[hash][i].value = value;
                keyFound = true;
                break;
            }
        }
        if (!keyFound) {
            hashToMetadata[hash].push(Metadata(key, value));
        }
    }
    
    function getSingleMetadata(uint256 tokenId, string memory key) public view returns (string memory) {
        for (uint256 i = 0; i < tokenIdToMetadata[tokenId].length; i++) {
            if (streq(tokenIdToMetadata[tokenId][i].key, key)) {
                return tokenIdToMetadata[tokenId][i].value;
            }
        }
        return "";
    }
    function setSingleMetadata(uint256 tokenId, string memory key, string memory value) public {
        require(ownerOf(tokenId) == msg.sender || isSingleCollaborator(tokenId, msg.sender), "not an owner or collaborator");
        
        bool keyFound = false;
        for (uint256 i = 0; i < tokenIdToMetadata[tokenId].length; i++) {
            if (streq(tokenIdToMetadata[tokenId][i].key, key)) {
                tokenIdToMetadata[tokenId][i].value = value;
                keyFound = true;
                break;
            }
        }
        if (!keyFound) {
            tokenIdToMetadata[tokenId].push(Metadata(key, value));
        }
    }
    
    function updateHash(string memory oldHash, string memory newHash) public {
        require(hashToTotalSupply[oldHash] > 0, "old hash does not exist");
        require(hashToTotalSupply[newHash] == 0, "new hash already exists");
        require(isCollaborator(oldHash, msg.sender), "not a collaborator");

        uint256 startTokenId = hashToStartTokenId[oldHash];
        uint256 totalSupply = hashToTotalSupply[oldHash];
        for (uint256 i = 0; i < totalSupply; i++) {
            tokenIdToHash[startTokenId + i] = newHash;
        }

        hashToStartTokenId[newHash] = hashToStartTokenId[oldHash];
        hashToTotalSupply[newHash] = hashToTotalSupply[oldHash];
        hashToMetadata[newHash] = hashToMetadata[oldHash];
        hashToCollaborators[newHash] = hashToCollaborators[oldHash];

        delete hashToStartTokenId[oldHash];
        delete hashToTotalSupply[oldHash];
        delete hashToMetadata[oldHash];
        delete hashToCollaborators[oldHash];
    }
}
