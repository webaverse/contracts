// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./WebaverseVoucher.sol";

contract WebaverseERC1155 is
    ERC1155Upgradeable,
    WebaverseVoucher,
    OwnableUpgradeable
{
    using ECDSA for bytes32;

    string private _name;
    string private _symbol;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _tokenBalances;
    mapping(address => bool) private _allowedMinters; // Mapping of white listed minters
    string private _webaBaseURI; // Base URI of the collection for Webaverse
    uint256 public currentTokenId; // State variable for storing the latest minted token id
    bool internal isPublicallyMintable; // whether anyone can mint tokens in this copy of the contract
    mapping(uint256 => attribute[]) internal tokenIdToAttributes; // map of token id to attributes (additional attributes) key-value store
    mapping(uint256 => address) internal minters; // map of tokens to minters

    struct attribute {
        string trait_type;
        string value;
        string display_type;
    }

    event AttributeSet(
        uint256 tokenId,
        string trait_type,
        string value,
        string display_type
    );
    event Claim(address signer, address claimer, uint256 indexed id);
    event ExternalClaim(
        address indexed externalContract,
        address signer,
        address claimer,
        uint256 indexed id
    );

    modifier onlyMinter() {
        require(isAllowedMinter(msg.sender), "ERC1155: unauthorized call");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address minter
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        __Ownable_init_unchained();
        __ERC1155_init(baseURI_);
        _webaBaseURI = baseURI_;
        _webaverse_voucher_init();
        _allowedMinters[minter] = true;
    }

    /**
     * @return Returns the name of the collection.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return Returns the symbol of the collection.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return Returns the base URI of the host to fetch the attributes from (default empty).
     */
    function baseURI() public view returns (string memory) {
        return _webaBaseURI;
    }

    /**
     * @dev Update or change the Base URI of the collection for Webaverse NFTs
     * @param baseURI_ The base URI of the host to fetch the attributes from e.g. https://ipfs.io/ipfs/.
     */
    function setBaseURI(string memory baseURI_) public onlyMinter {
        _webaBaseURI = baseURI_;
    }

    /**
     * @param tokenId The id of the token for which the balance is being fetched.
     * @return Returns the total balance of the token.
     */
    function getTokenBalance(uint256 tokenId) public view returns (uint256) {
        return _tokenBalances[tokenId];
    }

    /**
     * @return Returns the token URI against a particular token id.
     * e.g. [baseURI]/[cid]?attributes=[{"trait_type": "power", "display_type": "boost_number", "value": "100"}]
     */
    function uri(uint256 _id) public view override returns (string memory) {
        string memory _baseURI = baseURI();
        string memory _cid = _tokenURIs[_id];
        string memory attributes;
        string memory _uri;
        if (tokenIdToAttributes[_id].length > 0) {
            attributes = "[";
            for (uint256 i = 0; i < tokenIdToAttributes[_id].length; i++) {
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        '{"trait_type":',
                        '"',
                        tokenIdToAttributes[_id][i].trait_type,
                        '"',
                        ',"value":',
                        '"',
                        tokenIdToAttributes[_id][i].value,
                        '"'
                    )
                );
                if (
                    bytes(tokenIdToAttributes[_id][i].display_type).length > 0
                ) {
                    attributes = string(
                        abi.encodePacked(
                            attributes,
                            ',"display_type":',
                            tokenIdToAttributes[_id][i].display_type,
                            "}"
                        )
                    );
                }
                if (i < tokenIdToAttributes[_id].length - 1) {
                    attributes = string(abi.encodePacked(attributes, "},"));
                } else {
                    attributes = string(abi.encodePacked(attributes, "}]"));
                }
            }
            if (bytes(_baseURI).length > 0) {
                _uri = string(
                    abi.encodePacked(
                        _baseURI,
                        "/",
                        _cid,
                        "?",
                        "attributes=",
                        attributes
                    )
                );
            } else {
                _uri = string(
                    abi.encodePacked(_cid, "?", "attributes=", attributes)
                );
            }
        } else {
            if (bytes(_baseURI).length > 0) {
                _uri = string(abi.encodePacked(_baseURI, "/", _cid));
            } else {
                _uri = _cid;
            }
        }
        return _uri;
    }

    /**
     * @dev Set attributes for the token. attributes is a key-value store that can be set by owners and collaborators
     * @param tokenId Token id to set the uri to
     * @param _uri The uri to set for the token
     */
    /// _uri === [cid] or https://[linktofile]
    function setTokenURI(uint256 tokenId, string memory _uri)
        public
        onlyMinter
    {
        require(bytes(_uri).length > 0, "ERC1155: URI must not be empty");
        _tokenURIs[tokenId] = _uri;
    }

    function getTokenIdsByOwner(address owner) public view returns (uint256[] memory, uint256) {
        uint256[] memory ids = new uint256[](currentTokenId);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentTokenId; i++) {
            if(minters[i] == owner) 
            {
                ids[index] = i;
                index++;
            }
        }
        return (ids, index);
    }

    function getTokenAttr(uint256 tokenId) public view returns (string memory, string memory, string memory) {
        string memory url = _tokenURIs[tokenId];
        string memory tokenName = getAttribute(tokenId, "name");
        string memory tokenLevel = getAttribute(tokenId, "level");
        
        return (url, tokenName, tokenLevel);
    }

    /**
     * @notice Mints a single NFT with given parameters.
     * @param to The address on which the NFT will be minted.
     **/
    function mint(
        address to,
        uint256 balance,
        string memory _uri,
        string memory _name,
        bytes memory data
    ) public onlyMinter {
        uint256 tokenId = getNextTokenId();
        _mint(to, tokenId, balance, data);
        setTokenURI(tokenId, _uri);
        setAttribute(tokenId, "name", _name, "");
        setAttribute(tokenId, "level", "1", "");
        _incrementTokenId();
        _tokenBalances[tokenId] = balance;
        minters[tokenId] = to;
    }

    /**
     * @notice Mints batch of NFTs with given parameters.
     * @param to The address to which the NFTs will be minted in batch.
     * @param uris The URIs of all the the NFTs.
     * @param balances The balances of all the NFTs as per the ERC1155 standard.
     **/
    function mintBatch(
        address to,
        string[] memory uris,
        uint256[] memory balances,
        bytes memory data
    ) public onlyMinter {
        require(
            uris.length == balances.length,
            "WBVRSERC1155: URIs and balances length mismatch"
        );
        uint256[] memory ids = new uint256[](uris.length);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenId = getNextTokenId();
            ids[i] = tokenId;
            setTokenURI(ids[i], uris[i]);
            minters[tokenId] = to;
        }
        _mintBatch(to, ids, balances, data);
    }

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner.
     * @param signer The address of the account which signed the NFT Voucher.
     * @param claimer The address of the account which will receive the NFT upon success.
     * @param dropName The name to store.
     * @param dropLevel The level to store.
     * @param data The data to store.
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function mintServerDropNFT(address signer, address claimer, string memory dropName, string memory dropLevel, bytes memory data, NFTVoucher calldata voucher)
        public
        virtual
        onlyMinter
    {
        require(owner() == signer, "Wrong signature!");

        uint256 tokenId = getNextTokenId();
        _mint(claimer, tokenId, voucher.balance, data);

        // setURI with metadataurl of verified voucher
        setTokenURI(tokenId, voucher.metadataurl);
        setAttribute(tokenId, "name", dropName, "");
        setAttribute(tokenId, "level", dropLevel, "");
        _incrementTokenId();
        _tokenBalances[tokenId] = voucher.balance;
        minters[tokenId] = claimer;
    }

    /**
     * @dev Get attributes for the token. attribute is a key-value store that can be set by owners and collaborators
     * @param tokenId Token id to query for attribute
     * @param trait_type Key to query for a value
     * @return Value corresponding to attribute key
     */
    function getAttribute(uint256 tokenId, string memory trait_type)
        public
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < tokenIdToAttributes[tokenId].length; i++) {
            if (streq(tokenIdToAttributes[tokenId][i].trait_type, trait_type)) {
                return
                    string(
                        abi.encodePacked(
                            tokenIdToAttributes[tokenId][i].value,
                            tokenIdToAttributes[tokenId][i].display_type
                        )
                    );
            }
        }
        return "";
    }

    /**
     * @dev Set attributes for the token. attributes is a key-value store that can be set by owners and collaborators
     * @param trait_type Key to store value at
     * @param value Value to store
     */
    function setAttribute(
        uint256 tokenId,
        string memory trait_type,
        string memory value,
        string memory display_type
    ) public onlyMinter {
        require(tokenId > 0, "ERC1155: invalid token id");
        require(
            bytes(trait_type).length > 0,
            "ERC1155: Attribute name must not be empty"
        );
        require(
            bytes(value).length > 0,
            "ERC1155: Attribute value must not be empty"
        );
        bool keyFound = false;
        for (uint256 i = 0; i < tokenIdToAttributes[tokenId].length; i++) {
            if (streq(tokenIdToAttributes[tokenId][i].trait_type, trait_type)) {
                tokenIdToAttributes[tokenId][i].value = value;
                tokenIdToAttributes[tokenId][i].display_type = display_type;
                keyFound = true;
                break;
            }
        }
        if (!keyFound) {
            tokenIdToAttributes[tokenId].push(
                attribute(trait_type, value, display_type)
            );
        }
        emit AttributeSet(tokenId, trait_type, value, display_type);
    }

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner.
     * @param signer The address of the account which signed the NFT Voucher.
     * @param claimer The address of the account which will receive the NFT upon success.
     * @param data The data to store.
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function claim(address signer, address claimer, bytes memory data, NFTVoucher calldata voucher)
        public
        virtual
        onlyMinter
    {
        // make sure signature is valid and get the address of the signer
        // address signer = verifyVoucher(voucher);

        require(
            balanceOf(signer, voucher.tokenId) != 0,
            "WBVRS: Authorization failed: Invalid signature"
        );

        require(
            minters[voucher.tokenId] == signer,
            "WBVRS: Authorization failed: Invalid signature"
        );

        minters[voucher.tokenId] = claimer;
        // transfer the token to the claimer
        _safeTransferFrom(
            signer,
            claimer,
            voucher.tokenId,
            voucher.balance,
            "0x01"
        );
    }

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner from an external contract.
     * @param claimer The address of the account which will receive the NFT upon success.
     * @param contractAddress The address of the contract from which the token is being transferred
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function externalClaim(
        address claimer,
        address contractAddress,
        NFTVoucher calldata voucher
    ) public returns (uint256) {
        IERC1155Upgradeable externalContract = IERC1155Upgradeable(
            contractAddress
        );
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        require(
            externalContract.balanceOf(signer, voucher.tokenId) != 0,
            "WBVRS: Authorization failed: Invalid signature"
        );
        require(
            externalContract.isApprovedForAll(signer, address(this)),
            "WBVRS: Aprroval not set for WebaverseERC1155"
        );

        // transfer the token to the claimer
        externalContract.safeTransferFrom(
            signer,
            claimer,
            voucher.tokenId,
            voucher.balance,
            "0x01"
        );
        return voucher.tokenId;
    }

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner from an external contract.
     * @param to The address of the account which will receive the NFT.
     * @param id The token id of the NFT to be transferred.
     * @param amount The balance of the token to be transffered.
     **/
    function safeTransfer(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        safeTransferFrom(_msgSender(), to, id, amount, data);
    }

    /**
     * @dev Checks if an address is allowed to mint ERC20 tokens
     * @param account address to check for the white listing for
     * @return true if address is allowed to mint
     */
    function isAllowedMinter(address account) public view returns (bool) {
        return _allowedMinters[account];
    }

    /**
     * @dev Add an account to the list of accounts allowed to create ERC20 tokens
     * @param minter address to whitelist
     */
    function addMinter(address minter) public onlyOwner {
        require(!isAllowedMinter(minter), "ERC20: Minter already added");
        _allowedMinters[minter] = true;
    }

    /**
     * @dev Remove an account from the list of accounts allowed to create ERC20 tokens
     * @param minter address to remove from whitelist
     */
    function removeMinter(address minter) public onlyOwner {
        require(isAllowedMinter(minter), "ERC20: Minter does not exist");
        _allowedMinters[minter] = false;
    }

    /**
     * @dev returns the next token id to be minted
     */
    function getNextTokenId() public view returns (uint256) {
        return currentTokenId + 1;
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() internal {
        currentTokenId++;
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
     * @notice Using low level assembly call to fetch the chain id of the blockchain.
     * @return Returns the chain id of the current blockchain.
     **/
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable)
        returns (bool)
    {
        return ERC1155Upgradeable.supportsInterface(interfaceId);
    }
}
