/*
▄▄▌ ▐ ▄▌▄▄▄ .▄▄▄▄·  ▄▄▄·  ▌ ▐·▄▄▄ .▄▄▄  .▄▄ · ▄▄▄ .
██· █▌▐█▀▄.▀·▐█ ▀█▪▐█ ▀█ ▪█·█▌▀▄.▀·▀▄ █·▐█ ▀. ▀▄.▀·
██▪▐█▐▐▌▐▀▀▪▄▐█▀▀█▄▄█▀▀█ ▐█▐█•▐▀▀▪▄▐▀▀▄ ▄▀▀▀█▄▐▀▀▪▄
▐█▌██▐█▌▐█▄▄▌██▄▪▐█▐█ ▪▐▌ ███ ▐█▄▄▌▐█•█▌▐█▄▪▐█▐█▄▄▌
 ▀▀▀▀ ▀▪ ▀▀▀ ·▀▀▀▀  ▀  ▀ . ▀   ▀▀▀ .▀  ▀ ▀▀▀▀  ▀▀▀ 
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./EnumerableSet.sol";
import "./Math.sol";
import "./Strings.sol";
import "./WebaverseERC20.sol";

/**
 * @title Extension of {ERC721} for Webaverse non-fungible tokens
 * @dev NFTs can be packed with fungible tokens, and can have special features
 * I.E. collaborators and separate creatorship and ownership
 */
contract WebaverseERC721 is ERC721 {
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for *;

    WebaverseERC20 internal erc20Contract; // ERC20 contract for fungible tokens
    uint256 internal mintFee; // ERC20 fee to mint ERC721
    address internal treasuryAddress; // address into which we deposit minting fees
    address internal marketplaceAddress; // address of the marketplace contract 
    bool internal isPublicallyMintable; // whether anyone can mint tokens in this copy of the contract
    mapping(address => bool) internal allowedMinters; // addresses allowed to mint in this copy of the contract
    uint256 internal nextTokenId = 0; // the next token id to use (increases linearly)
    mapping(uint256 => uint256) internal tokenIdToBalance; // map of tokens to packed balance
    mapping(uint256 => address) internal minters; // map of tokens to minters
    mapping(uint256 => Metadata[]) internal tokenIdToMetadata; // map of token id to metadata key-value store
    mapping(uint256 => Metadata[]) internal tokenIdToSecureMetadata; // map of token id to secure metadata key-value store
    mapping(uint256 => address[]) internal tokenIdToCollaborators; // map of token id to addresses that can change metadata
    mapping(uint256 => address[]) internal tokenIdToSecureCollaborators; // map of token id to addresses that can change metadata

    struct Metadata {
        string key;
        string value;
    }

    struct Token {
        uint256 id;
        string name;
        string ext;
        address minter;
        address owner;
        uint256 royaltyPercentage;
        string isTransferLocked;
    }

    event SecureMetadataSet(uint256 tokenId, string key, string value);
    event MetadataSet(uint256 tokenId, string key, string value);
    event CollaboratorAdded(uint256 tokenId, address a);
    event CollaboratorRemoved(uint256 tokenId, address a);
    event SecureCollaboratorAdded(uint256 tokenId, address a);
    event SecureCollaboratorRemoved(uint256 tokenId, address a);

    /**
     * @dev Create this ERC721 contract
     * @param name Name of the contract (default is "NFT")
     * @param symbol Symbol for the token (default is ???)
     * @param baseUri Base URI (example is http://)
     * @param _erc20Contract ERC20 contract attached to fungible tokens
     * @param _treasuryAddress Address of the treasury account
     * @param _isPublicallyMintable Whether anyone can mint tokens with this contract
     * I.E. collaborators and separate creatorship and ownership
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri,
        WebaverseERC20 _erc20Contract,
        uint256 _mintFee,
        address _treasuryAddress,
        bool _isPublicallyMintable
    ) public ERC721(name, symbol) {
        _setBaseURI(baseUri);
        erc20Contract = _erc20Contract;
        mintFee = _mintFee;
        treasuryAddress = _treasuryAddress;
        isPublicallyMintable = _isPublicallyMintable;
        allowedMinters[msg.sender] = true;
    }

    /**
     * @dev Set the price to mint
     * @param _mintFee Minting fee, default is 10 FT
     */
    function setMintFee(uint256 _mintFee) public {
        require(
            msg.sender == treasuryAddress,
            "must be set from treasury address"
        );
        mintFee = _mintFee;
    }

    /**
     * @dev Set the treasury address
     * @param _treasuryAddress Account address of the treasurer
     */
    function setTreasuryAddress(address _treasuryAddress) public {
        require(
            msg.sender == treasuryAddress,
            "must be set from treasury address"
        );
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @dev Set the marketplace address
     * @param _marketplaceAddress Account address of the marketplace 
     */
    function setMarketplaceAddress(address _marketplaceAddress) public {
        require(
            msg.sender == treasuryAddress,
            "must be set from treasury address"
        );
        marketplaceAddress = _marketplaceAddress;
        setApprovalForAll(marketplaceAddress, true);
    }

    /**
     * @dev Get the balance of fungible tokens packed into this non-fungible token
     * @param tokenId ID of the non-fungible ERC721 token
     */
    function getPackedBalance(uint256 tokenId) public view returns (uint256) {
        return tokenIdToBalance[tokenId];
    }

    /**
     * @dev Pack fungible tokens into this non-fungible token
     * @param from Address of who is packing the token
     * @param tokenId ID of the token
     * @param amount Amount to pack
     */
    function pack(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public {
        require(_exists(tokenId), "token id does not exist");

        tokenIdToBalance[tokenId] = SafeMath.add(
            tokenIdToBalance[tokenId],
            amount
        );

        require(
            erc20Contract.transferFrom(from, address(this), amount),
            "transfer failed"
        );
    }

    /**
     * @dev Unpack fungible tokens from this non-fungible token
     * @param to Address of who is packing the token
     * @param tokenId ID of the token
     * @param amount Amount to unpack
     */
    function unpack(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public {
        require(ownerOf(tokenId) == msg.sender, "not your token");
        require(tokenIdToBalance[tokenId] >= amount, "insufficient balance");

        tokenIdToBalance[tokenId] = SafeMath.sub(
            tokenIdToBalance[tokenId],
            amount
        );

        require(erc20Contract.transfer(to, amount), "transfer failed");
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        string memory isTransferLocked = getSecureMetadata(tokenId, "isTransferLocked");

        require(
            keccak256(bytes(isTransferLocked)) != keccak256(bytes("true")),
            "Cannot transfer when transfer lock is enabled"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Mint one non-fungible token with this contract
     * @param to Address of who is receiving the token on mint
     * Example: 0x08E242bB06D85073e69222aF8273af419d19E4f6
     * @param name Name of the token
     * @param ext File extension of the token
     * Example: "png"
     * @param description Description of the token (set by user)
     */
    function mint(
        address to,
        string memory name,
        string memory ext,
        string memory description,
        uint256 royaltyPercentage,
        string memory isTransferLocked
    ) public {
        require(
            isPublicallyMintable || isAllowedMinter(msg.sender),
            "not allowed to mint"
        ); // Only allowed minters can mint

        nextTokenId = SafeMath.add(nextTokenId, 1);
        uint256 tokenId = nextTokenId;

        _mint(to, tokenId);
        minters[tokenId] = to;

        string memory royalty = royaltyPercentage.toString();

        tokenIdToSecureMetadata[tokenId].push(
            Metadata("royaltyPercentage", royalty)
        );

        if (keccak256(bytes(isTransferLocked)) == keccak256(bytes("true"))) {
            require(
                to == msg.sender,
                "Can only mint transfer locked NFTs to your own address"
            );
            tokenIdToSecureMetadata[tokenId].push(Metadata("isTransferLocked", "true"));
        }

        tokenIdToMetadata[tokenId].push(Metadata("name", name));
        tokenIdToMetadata[tokenId].push(Metadata("ext", ext));
        tokenIdToMetadata[tokenId].push(Metadata("description", description));

        tokenIdToCollaborators[tokenId].push(to);

        setApprovalForAll(marketplaceAddress, true);

        // Unless the mint free, transfer fungible tokens and attempt to pay the fee
        if (mintFee != 0) {
            require(
                erc20Contract.transferFrom(
                    msg.sender,
                    treasuryAddress,
                    mintFee
                ),
                "mint transfer failed"
            );
        }
    }

    /**
     * @dev Get the address for for the minter of the token
     * @param tokenId ID of the token we are querying
     * @return Address of the minter
     */
    function getMinter(uint256 tokenId) public view returns (address) {
        return minters[tokenId];
    }

    /**
     * @dev Check if two strings are equal
     * @param a First string to compare
     * @param b Second string to compare
     * @return Returns true if strings are equal
     */
    function streq(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

        /**
     * @dev Mint a token with a specific ID
     * @param to Who should receive the minted token
     * @param tokenId ID of the token to mint (ie: 250)
     */
    function mintTokenId(address to, uint256 tokenId) public {
        require(isAllowedMinter(msg.sender), "minter not allowed");

        _mint(to, tokenId);
    }

    /**
     * @dev Set the base URI for this contract
     * @param baseURI_ Base URI to send to
     */
    function setBaseURI(string memory baseURI_) public {
        require(
            allowedMinters[msg.sender],
            "only minters can set the base uri"
        );
        _setBaseURI(baseURI_);
    }

    /**
     * @dev Get the URI of a token
     * @param tokenId Token to get the URI from (ie: 250)
     * @return URI of the token to retrieve
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI(), uint2str(tokenId)));
    }

    /**
     * @dev Check if the token exists
     * @param tokenId Token to test
     * @return Returns true if the token exists
     */
    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Check if an account is allowed to mint tokens
     * @param a Address to check
     * @return Returns true if the acount can mint
     */
    function isAllowedMinter(address a) public view returns (bool) {
        return allowedMinters[a];
    }

    /**
     * @dev Add a minter to the approved list to mint tokens
     * @param a Address to whitelist
     */
    function addAllowedMinter(address a) public {
        require(isAllowedMinter(msg.sender));
        require(!isAllowedMinter(a), "target is already a minter");
        allowedMinters[a] = true;
    }

    /**
     * @dev Remove a minter from the approved list to mint tokens
     * @param a Address to remove from whitelist
     */
    function removeAllowedMinter(address a) public {
        require(isAllowedMinter(msg.sender), "sender is not a minter");
        require(isAllowedMinter(a), "target is not a minter");
        allowedMinters[a] = false;
    }

    /**
     * @dev Check if this address is a collaborator on a token
     * @param tokenId ID of the token
     * @param a Address to check
     * @return Returns true if the address is a collaborator on the token
     */
    function isCollaborator(uint256 tokenId, address a)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIdToCollaborators[tokenId].length; i++) {
            if (tokenIdToCollaborators[tokenId][i] == a) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev List collaborators for a token
     * @param tokenId Token ID of the token to get collaborators for
     */
    function getCollaborators(uint256 tokenId) public view returns (address[] memory) {
        address[] memory collaborators = tokenIdToCollaborators[tokenId];
        return collaborators;
    }

    /**
     * @dev Add a collaborator to a token
     * @param tokenId ID of the token
     * @param a Address to whitelist
     */
    function addCollaborator(uint256 tokenId, address a) public {
        require(
            ownerOf(tokenId) == a || isCollaborator(tokenId, msg.sender),
            "you are not a collaborator"
        );
        require(
            !isCollaborator(tokenId, a),
            "they are already a collaborator"
        );
        tokenIdToCollaborators[tokenId].push(a);
        
        emit CollaboratorAdded(tokenId, a);
    }

    /**
     * @dev Remove a collaborator from a token
     * @param tokenId ID of the token
     * @param a Address to remove from whitelist
     */
    function removeCollaborator(uint256 tokenId, address a) public {
        require(
            ownerOf(tokenId) == a || isCollaborator(tokenId, msg.sender),
            "you are not a collaborator"
        );
        require(
            isCollaborator(tokenId, a),
            "they are not a collaborator"
        );

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
        
        emit CollaboratorRemoved(tokenId, a);
    }

     /**
     * @dev Check if this address is a secure collaborator on a token
     * @param tokenId ID of the token
     * @param a Address to check
     * @return Returns true if the address is a secure collaborator on the token
     */
    function isSecureCollaborator(uint256 tokenId, address a)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIdToSecureCollaborators[tokenId].length; i++) {
            if (tokenIdToSecureCollaborators[tokenId][i] == a) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev List secure collaborators for a token
     * @param tokenId Token ID of the token to get secure collaborators for
     */
    function getSecureCollaborators(uint256 tokenId) public view returns (address[] memory) {
        address[] memory collaborators = tokenIdToSecureCollaborators[tokenId];
        return collaborators;
    }

    /**
     * @dev Add a secure collaborator to a token
     * @param tokenId ID of the token
     * @param a Address to whitelist
     */
    function addSecureCollaborator(uint256 tokenId, address a) public {
        require(
            msg.sender == treasuryAddress,
            "only treasury address can set secure collaborator"
        );
        require(
            !isSecureCollaborator(tokenId, a),
            "they are already a secure collaborator"
        );
        tokenIdToSecureCollaborators[tokenId].push(a);
        
        emit SecureCollaboratorAdded(tokenId, a);
    }

    /**
     * @dev Remove a secure collaborator from a token
     * @param tokenId ID of the token
     * @param a Address to remove from whitelist
     */
    function removeSecureCollaborator(uint256 tokenId, address a) public {
        require(
            msg.sender == treasuryAddress,
            "only treasury address can set secure collaborator"
        );
        require(
            isCollaborator(tokenId, a),
            "they are not a collaborator"
        );

        uint256 newSize = 0;
        for (uint256 i = 0; i < tokenIdToSecureCollaborators[tokenId].length; i++) {
            if (tokenIdToSecureCollaborators[tokenId][i] != a) {
                newSize++;
            }
        }

        address[] memory newTokenIdCollaborators = new address[](newSize);
        uint256 index = 0;
        for (uint256 i = 0; i < tokenIdToSecureCollaborators[tokenId].length; i++) {
            address oldTokenIdCollaborator = tokenIdToSecureCollaborators[tokenId][i];
            if (oldTokenIdCollaborator != a) {
                newTokenIdCollaborators[index++] = oldTokenIdCollaborator;
            }
        }
        tokenIdToSecureCollaborators[tokenId] = newTokenIdCollaborators;
        
        emit SecureCollaboratorRemoved(tokenId, a);
    }



    /**
     * @dev Seal the token forever and remove collaborators so that it can't be altered
     * @param tokenId id of the collaborative token
     */
    function seal(uint256 tokenId) public {
        require(isCollaborator(tokenId, msg.sender), "not a collaborator");
        delete tokenIdToCollaborators[tokenId];
    }

    /**
     * @dev List the tokens IDs owned by an account
     * @param owner Address to query
     * @return Array of token IDs
     */
    function getTokenIdsOf(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    /**
     * @dev Get the complete information for a token from it's ID
     * @param tokenId Token ID to query
     * @return Token struct containing token data
     */
    function tokenByIdFull(uint256 tokenId) public view returns (Token memory) {
        string memory name;
        string memory ext;
        string memory royalty;
        uint256 royaltyPercentage;
        string memory isTransferLocked;

        name = getMetadata(tokenId, "name");
        ext = getMetadata(tokenId, "ext");
        royalty = getSecureMetadata(tokenId, "royaltyPercentage");

        royaltyPercentage = royalty.parseInt();
        isTransferLocked = getSecureMetadata(tokenId, "isTransferLocked");

        address minter = minters[tokenId];
        address owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);
        return Token(tokenId, name, ext, minter, owner, royaltyPercentage, isTransferLocked);
    }

    /**
     * @dev Get the full Token struct from an owner address at a specific index
     * @param owner Owner to query
     * @param index Index in owner's balance to query
     * @return Token struct containing token data
     */
    function tokenOfOwnerByIndexFull(address owner, uint256 index)
        public
        view
        returns (Token memory)
    {
        uint256 tokenId = tokenOfOwnerByIndex(owner, index);
        string memory name;
        string memory ext;
        string memory royalty;
        uint256 royaltyPercentage;
        string memory isTransferLocked;

        name = getMetadata(tokenId, "name");
        ext = getMetadata(tokenId, "ext");

        royalty = getSecureMetadata(tokenId, "royaltyPercentage");
        royaltyPercentage = royalty.parseInt();

        isTransferLocked = getSecureMetadata(tokenId, "isTransferLocked");

        address minter = minters[tokenId];
        return Token(tokenId, name, ext, minter, owner, royaltyPercentage, isTransferLocked);
    }

    /**
     * @dev Get metadata for a token
     * @param tokenId Token id to add metadata to
     * @param key Key to retrieve value for
     * @return Returns the value stored for the key
     */
    function getMetadata(uint256 tokenId, string memory key)
        public
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < tokenIdToMetadata[tokenId].length; i++) {
            if (streq(tokenIdToMetadata[tokenId][i].key, key)) {
                return tokenIdToMetadata[tokenId][i].value;
            }
        }
        return "";
    }

    /**
     * @dev Set metadata for a token
     * @param tokenId Token id to add metadata to
     * @param key Key to store value at
     * @param value Value to store
     */
    function setMetadata(
        uint256 tokenId,
        string memory key,
        string memory value
    ) public {
        require(
            ownerOf(tokenId) == msg.sender ||
                isCollaborator(tokenId, msg.sender),
            "not an owner or collaborator"
        );

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

        emit MetadataSet(tokenId, key, value);
    }

    /**
     * @dev Get secure metadata for a token
     * @param tokenId Token id to add metadata to
     * @param key Key to retrieve value for
     * @return Returns the value stored for the key
     */
    function getSecureMetadata(uint256 tokenId, string memory key)
        public
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < tokenIdToSecureMetadata[tokenId].length; i++) {
            if (streq(tokenIdToSecureMetadata[tokenId][i].key, key)) {
                return tokenIdToSecureMetadata[tokenId][i].value;
            }
        }
        return "";
    }

    /**
     * @dev Set secure metadata for a token
     * @param tokenId Token id to add metadata to
     * @param key Key to store value at
     * @param value Value to store
     */
    function setSecureMetadata(
        uint256 tokenId,
        string memory key,
        string memory value
    ) public {
        require(
            isSecureCollaborator(tokenId, msg.sender),
            "not an secure collaborator"
        );

        bool keyFound = false;
        for (uint256 i = 0; i < tokenIdToSecureMetadata[tokenId].length; i++) {
            if (streq(tokenIdToSecureMetadata[tokenId][i].key, key)) {
                tokenIdToSecureMetadata[tokenId][i].value = value;
                keyFound = true;
                break;
            }
        }
        if (!keyFound) {
            tokenIdToSecureMetadata[tokenId].push(Metadata(key, value));
        }

        emit SecureMetadataSet(tokenId, key, value);
    }

    /**@dev Helper function to convert a uint to a string
     * @param _i uint to convert
     * @return _uintAsString string converted from uint
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}
