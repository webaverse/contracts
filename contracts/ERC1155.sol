pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Address.sol";
import "./Common.sol";
import "./IERC1155Metadata.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, ERC165, ERC1155Metadata_URI, CommonConstants
{
    using SafeMath for uint256;
    using Address for address;

    address owner;
    string tokenName = "Gunt";
    string uriPrefix = "https://tokens.gunt.one/";
    uint256 nonce = 0;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;
    
    mapping(uint256 => mapping(address => bool)) internal minterApproval;
    // localId -> contractAddress -> remoteId -> value
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) assets;
    mapping(uint256 => mapping(string => string)) metadata;
    mapping(string => mapping(string => uint256)) reverseMetadata;
    mapping(uint256 => string[]) metadataKeys;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function name() public view returns (string memory _name) {
        return tokenName;
    }
    function setName(string memory newTokenName) public {
        tokenName = newTokenName;
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
      function uint2hex(uint256 ui) public pure returns (string memory) {
            bytes32 value = bytes32(ui);
            bytes memory alphabet = "0123456789abcdef";
        
            bytes memory str = new bytes(32*2);
            /*( str[0] = '0';
            str[1] = 'x'; */
            for (uint i = 0; i < 32; i++) {
                str[/*2+*/i*2] = alphabet[uint8(value[i] >> 4)];
                str[/*3+*/i*2+1] = alphabet[uint8(value[i] & 0x0f)];
            }
            return string(str);
        }
      function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
      }
      
    function _uri(uint256 _id) internal view returns (string memory) {
        return strConcat(uriPrefix, uint2hex(_id));
    }
    function setUriPrefix(string memory newUriPrefix) public {
        uriPrefix = newUriPrefix;
        for (uint256 id = 1; id <= nonce; id++) {
          emit URI(_uri(id), id);
        }
    }
    function uri(uint256 _id) external view returns (string memory) {
        return _uri(_id);
    }
    
    function recoverSignerAddress(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        // Check the signature length
        if (signature.length != 65) {
          return (address(0));
        }
    
        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
          r := mload(add(signature, 0x20))
          s := mload(add(signature, 0x40))
          v := byte(0, mload(add(signature, 0x60)))
        }
    
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
          v += 27;
        }
    
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
          return (address(0));
        } else {
          // solium-disable-next-line arg-overflow
          return ecrecover(hash, v, r, s);
        }
    }
    function toEthSignedMessageHash(string memory s)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
          abi.encodePacked("\x19Ethereum Signed Message:\n", uint2str(bytes(s).length), s)
        );
    }  
    function checkSignature(uint256 _id, bytes memory signature) internal view returns (bool) {
      string memory s = strConcat(tokenName, uint2str(_id));
      bytes32 h = toEthSignedMessageHash(s);
      address signerAddress = recoverSignerAddress(h, signature);
      return balances[_id][signerAddress] > 0;
    }
    function mintInternal(uint256 id, address addr, uint256 count) internal returns (uint256) {
        require(id == 0 || minterApproval[id][addr]);

        if (id == 0) {
          id = ++nonce;
        }
        minterApproval[id][addr] = true;
        balances[id][addr] += count;
        
        emit TransferSingle(msg.sender, address(0), addr, id, count);
        emit URI(_uri(id), id);
        
        return id;
    }
    function setMetadataInternal(uint256 _id, string memory _key, string memory _value) internal {
      string storage oldValue = metadata[_id][_key];
      if (bytes(oldValue).length > 0) {
        reverseMetadata[_key][oldValue] = 0;
        
        string[] storage keys = metadataKeys[_id];
        for (uint256 i = 0; i < keys.length; i++) {
          if (keccak256(bytes(keys[i])) == keccak256(bytes(_key))) {
             delete keys[i];
             break;
          }
        }
      }
      metadata[_id][_key] = _value;
      if (bytes(_value).length > 0) {
        require(reverseMetadata[_key][_value] == 0);
        reverseMetadata[_key][_value] = _id;
        
        string[] storage keys = metadataKeys[_id];
        uint256 i;
        for (i = 0; i < keys.length; i++) {
          if (bytes(keys[i]).length == 0) {
             break;
          }
        }
        if (i < keys.length) {
          keys[i] = _key;
        } else {
          keys.push(_key);
        }
      }
    }

    function mint(uint256 id, address addr, uint256 count) external returns (uint256) {
        return mintInternal(id, addr, count);
    }
    function mintWithMetadata(uint256 id, address addr, uint256 count, string calldata _key, string calldata _value) external returns (uint256) {
        id = mintInternal(id, addr, count);
        setMetadataInternal(id, _key, _value);
        return id;
    }
    function isMinted(uint256 id) external view returns (bool) {
        return id >= nonce;
    }
    function getNonce() external view returns (uint256) {
        return nonce;
    }
    
    function deposit(address remoteContractAddress, uint256 _toId, uint256 _id, uint256 _value, bytes calldata _data) external {
        assets[_toId][remoteContractAddress][_id] += _value;
        IERC1155 remoteContract = IERC1155(remoteContractAddress);
        address localContractAddress = address(this);
        remoteContract.safeTransferFrom(msg.sender, localContractAddress, _id, _value, _data);
    }
    function withdraw(address remoteContractAddress, uint256 _fromId, uint256 _id, uint256 _value, bytes calldata _data) external {
        require(balances[_fromId][msg.sender] > 0);
        uint256 oldValue = assets[_fromId][remoteContractAddress][_id];
        require(oldValue >= _value);
        assets[_fromId][remoteContractAddress][_id] -= _value;
        IERC1155 remoteContract = IERC1155(remoteContractAddress);
        address localContractAddress = address(this);
        remoteContract.safeTransferFrom(localContractAddress, msg.sender, _id, _value, _data);
    }
    function getMetadata(uint256 _id, string memory _key) public view returns (string memory) {
      return metadata[_id][_key];
    }
    function setMetadata(uint256 _id, string calldata _key, string calldata _value) external {
      require(balances[_id][msg.sender] > 0);
      setMetadataInternal(_id, _key, _value);
    }
    function setMetadataFromSignature(uint256 _id, string calldata _key, string calldata _value, bytes calldata signature) external {
      require(checkSignature(_id, signature));
      setMetadataInternal(_id, _key, _value);
    }
    function getMetadataKeys(uint256 _id) public view returns (string[] memory) {
      return metadataKeys[_id];
    }
    function getIdFromMetadata(string calldata _key, string calldata _value) external view returns (uint256) {
      return reverseMetadata[_key][_value];
    }
    /* function approveMint(uint256 hash, address addr) external {
        require(minterApproval[hash][msg.sender]);
        minterApproval[hash][addr] = true;
    }
    function revokeMint(uint256 hash, address addr) external {
        require(minterApproval[hash][msg.sender]);
        minterApproval[hash][addr] = true;
    }
    function isMinted(uint256 hash) external view returns (bool) {
        return hashToId[hash] != 0;
    }
    function getId(uint256 hash) external view returns (uint256) {
        return hashToId[hash];
    }
    function getHash(uint256 id) external view returns (uint256) {
        return idToHash[id];
    } */

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256('supportsInterface(bytes4)'));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId)
    public
    view
    returns (bool) {
         if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
             _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
            return true;
         }

         return false;
    }

/////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        // MUST emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        // Now that the balance is updated and the event was emitted,
        // call onERC1155Received if the destination is a contract.
        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {

        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array lenght must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
        }

        // Note: instead of the below batch versions of event and acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.

        // MUST emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // Now that the balances are updated and the events are emitted,
        // call onERC1155BatchReceived if the destination is a contract.
        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        return balances[_id][_owner];
    }


    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

/////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.


        // Note: if the below reverts in the onERC1155Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
        require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155BatchReceived function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_BATCH_ACCEPTED test.
        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }
}
