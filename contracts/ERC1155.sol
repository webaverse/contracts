pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Address.sol";
import "./Common.sol";
import "./IERC1155Metadata.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";

interface IRealityScriptEngine {
  function getOwner() external view returns (address);
}
interface IRealityScript {
  struct Transform {
      int256 x;
      int256 y;
      int256 z;
  }
  struct Object {
      uint256 id;
      Transform transform;
  }
}

contract RealityScript is IRealityScript {
  struct State {
      address addr;
      Transform transform;
      uint256 hp;
  }

  function abs(int x) internal pure returns (uint) {
      if (x < 0) {
          x *= -1;
      }
      return uint(x);
  }
  function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
  /* function collides(Transform memory p1, Transform memory p2) internal pure returns (bool) {
      return sqrt(abs(p1.x - p2.x)**2 + abs(p1.y - p2.y)**2 + abs(p1.z - p2.z)**2) <= 1;
  } */
  function stringEquals(string memory a, string memory b) internal pure returns (bool) {
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
  }
  function transformEquals(Transform memory a, Transform memory b) internal pure returns (bool) {
      return a.x == b.x && a.y == b.y && a.z == b.z;
  }
  function someTransformEquals(Transform memory t, Object[] memory os) internal pure returns (bool) {
      for (uint256 i = 0; i < os.length; i++) {
          if (transformEquals(t, os[i].transform)) {
              return true;
          }
      }
      return false;
  }

  IRealityScriptEngine parent;
  uint256 id;
  uint256 hp;
  constructor(IRealityScriptEngine _parent, uint256 _id) public payable {
      parent = _parent;
      id = _id;
      hp = 100;
  }
  function initState(address a, Transform memory t) public view returns (State memory) {
      return State(a, t, hp);
  }
  function update(Transform memory t, Object[] memory os, State memory state) public pure returns (bool, State memory) {
      bool doApply = false;
      if (
        state.hp > 0 &&
        !transformEquals(t, state.transform) &&
        someTransformEquals(t, os)
      ) {
          state.hp--;
          doApply = true;
      }
      state.transform = t;
      return (doApply, state);
  }
  function applyState(State memory state) public {
      require(msg.sender == parent.getOwner());
      
      hp = state.hp;
  }
  function getHp() public view returns (uint256) {
      return hp;
  }
}

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, ERC165, ERC1155Metadata_URI, CommonConstants, IRealityScriptEngine
{
    using SafeMath for uint256;
    using Address for address;

    address owner;
    string tokenName = "Cryptopolys";
    string uriPrefix = "https://tokens.cryptopolys.com/";
    uint256 nonce = 0;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;
    
    mapping(uint256 => mapping(address => bool)) internal minterApproval;
    // localId -> contractAddress -> remoteId -> value
    mapping(uint256 => int256[]) sizes;
    mapping(uint256 => address) contracts;
    // mapping(uint256 => mapping(address => mapping(uint256 => uint256))) assets;
    mapping(uint256 => mapping(string => string)) metadata;
    mapping(string => mapping(string => uint256)) reverseMetadata;
    mapping(uint256 => string[]) metadataKeys;

    // grid
    mapping(int256 => mapping(int256 => uint256)) grid;
    mapping(uint256 => int256[]) bindings;
    mapping(uint256 => mapping(uint256 => uint256)) subtokens;
    mapping(uint256 => uint256[]) subtokenIds;
    mapping(uint256 => uint256) subtokenBindings;
    int256[] gridSize;
    int256[] maxTokenSize;
    
    constructor() public {
        owner = msg.sender;

        gridSize = new int256[](6);
        gridSize[0] = -100;
        gridSize[1] = 0;
        gridSize[2] = -100;
        gridSize[3] = 100;
        gridSize[4] = 0;
        gridSize[5] = 100;
        
        maxTokenSize = new int256[](3);
        maxTokenSize[0] = 16;
        maxTokenSize[1] = 128;
        maxTokenSize[2] = 16;
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
      /* function getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
      } */
      
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
    
    /* function recoverSignerAddress(bytes32 hash, bytes memory signature)
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
    } */
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    // mint
    
    function mergeBytes(bytes memory param1, bytes memory param2) internal pure returns (bytes memory) {
        bytes memory merged = new bytes(param1.length + param2.length);
        uint k = 0;
        for (uint i = 0; i < param1.length; i++) {
            merged[k] = param1[i];
            k++;
        }
        for (uint i = 0; i < param2.length; i++) {
            merged[k] = param2[i];
            k++;
        }
        return merged;
    }
    /* function createExternal(bytes calldata bytecode, uint256 id) external returns (address addr) {
        // bytes memory bytecode = hex"6080604052604051610a85380380610a85833981810160405261002591908101906100a5565b816000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550806001819055506064600281905550505061015d565b60008151905061008a8161012f565b92915050565b60008151905061009f81610146565b92915050565b600080604083850312156100b857600080fd5b60006100c68582860161007b565b92505060206100d785828601610090565b9150509250929050565b60006100ec82610105565b9050919050565b60006100fe826100e1565b9050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b610138816100f3565b811461014357600080fd5b50565b61014f81610125565b811461015a57600080fd5b50565b6109198061016c6000396000f3fe608060405234801561001057600080fd5b506004361061004c5760003560e01c80635b6f61511461005157806374fb3c1114610081578063a38b9c781461009d578063abd708ef146100ce575b600080fd5b61006b600480360361006691908101906105ef565b6100ec565b60405161007891906107b4565b60405180910390f35b61009b6004803603610096919081019061062b565b61012f565b005b6100b760048036036100b29190810190610654565b610213565b6040516100c592919061078b565b60405180910390f35b6100d6610286565b6040516100e391906107cf565b60405180910390f35b6100f4610325565b60405180606001604052808473ffffffffffffffffffffffffffffffffffffffff168152602001838152602001600254815250905092915050565b6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663893d20e86040518163ffffffff1660e01b815260040160206040518083038186803b15801561019657600080fd5b505afa1580156101aa573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052506101ce91908101906105c6565b73ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461020557600080fd5b806040015160028190555050565b600061021d610325565b600080905060008460400151118015610241575061023f868560200151610290565b155b8015610253575061025286866102cb565b5b1561026e578360400180518091906001900381525050600190505b85846020018190525080849250925050935093915050565b6000600254905090565b6000816000015183600001511480156102b0575081602001518360200151145b80156102c3575081604001518360400151145b905092915050565b600080600090505b8251811015610319576102fd848483815181106102ec57fe5b602002602001015160200151610290565b1561030c57600191505061031f565b80806001019150506102d3565b50600090505b92915050565b6040518060600160405280600073ffffffffffffffffffffffffffffffffffffffff168152602001610355610362565b8152602001600081525090565b60405180606001604052806000815260200160008152602001600081525090565b60008135905061039281610891565b92915050565b6000815190506103a781610891565b92915050565b600082601f8301126103be57600080fd5b81356103d16103cc82610817565b6107ea565b915081818352602084019350602081019050838560808402820111156103f657600080fd5b60005b83811015610426578161040c8882610445565b8452602084019350608083019250506001810190506103f9565b5050505092915050565b60008135905061043f816108a8565b92915050565b60006080828403121561045757600080fd5b61046160406107ea565b90506000610471848285016105b1565b6000830152506020610485848285016104f1565b60208301525092915050565b600060a082840312156104a357600080fd5b6104ad60606107ea565b905060006104bd84828501610383565b60008301525060206104d1848285016104f1565b60208301525060806104e5848285016105b1565b60408301525092915050565b60006060828403121561050357600080fd5b61050d60606107ea565b9050600061051d84828501610430565b600083015250602061053184828501610430565b602083015250604061054584828501610430565b60408301525092915050565b60006060828403121561056357600080fd5b61056d60606107ea565b9050600061057d84828501610430565b600083015250602061059184828501610430565b60208301525060406105a584828501610430565b60408301525092915050565b6000813590506105c0816108bf565b92915050565b6000602082840312156105d857600080fd5b60006105e684828501610398565b91505092915050565b6000806080838503121561060257600080fd5b600061061085828601610383565b925050602061062185828601610551565b9150509250929050565b600060a0828403121561063d57600080fd5b600061064b84828501610491565b91505092915050565b6000806000610120848603121561066a57600080fd5b600061067886828701610551565b935050606084013567ffffffffffffffff81111561069557600080fd5b6106a1868287016103ad565b92505060806106b286828701610491565b9150509250925092565b6106c58161083f565b82525050565b6106d481610851565b82525050565b6106e38161085d565b82525050565b60a0820160008201516106ff60008501826106bc565b506020820151610712602085018261072b565b506040820151610725608085018261076d565b50505050565b60608201600082015161074160008501826106da565b50602082015161075460208501826106da565b50604082015161076760408501826106da565b50505050565b61077681610887565b82525050565b61078581610887565b82525050565b600060c0820190506107a060008301856106cb565b6107ad60208301846106e9565b9392505050565b600060a0820190506107c960008301846106e9565b92915050565b60006020820190506107e4600083018461077c565b92915050565b6000604051905081810181811067ffffffffffffffff8211171561080d57600080fd5b8060405250919050565b600067ffffffffffffffff82111561082e57600080fd5b602082029050602081019050919050565b600061084a82610867565b9050919050565b60008115159050919050565b6000819050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b61089a8161083f565b81146108a557600080fd5b50565b6108b18161085d565b81146108bc57600080fd5b50565b6108c881610887565b81146108d357600080fd5b5056fea365627a7a723158205ddbbc5d6302ab271b88fcaeac57025bd78ee33ad77231bf714823bfb81cea2c6c6578706572696d656e74616cf564736f6c63430005100040";
        bytes memory bytecode2 = abi.encodePacked(bytecode, abi.encode(address(this), id)); // constructor argument
        assembly {
            addr := create(0, add(bytecode2, 0x20), mload(bytecode2))
        }
        require(addr != address(0), "Contract creation failed.");
        contracts[id] = addr;
        return addr;
    } */
    function createInternal(bytes memory bytecode, uint256 id) internal returns (address addr) {
        // bytes memory bytecode = hex"6080604052604051610a85380380610a85833981810160405261002591908101906100a5565b816000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550806001819055506064600281905550505061015d565b60008151905061008a8161012f565b92915050565b60008151905061009f81610146565b92915050565b600080604083850312156100b857600080fd5b60006100c68582860161007b565b92505060206100d785828601610090565b9150509250929050565b60006100ec82610105565b9050919050565b60006100fe826100e1565b9050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b610138816100f3565b811461014357600080fd5b50565b61014f81610125565b811461015a57600080fd5b50565b6109198061016c6000396000f3fe608060405234801561001057600080fd5b506004361061004c5760003560e01c80635b6f61511461005157806374fb3c1114610081578063a38b9c781461009d578063abd708ef146100ce575b600080fd5b61006b600480360361006691908101906105ef565b6100ec565b60405161007891906107b4565b60405180910390f35b61009b6004803603610096919081019061062b565b61012f565b005b6100b760048036036100b29190810190610654565b610213565b6040516100c592919061078b565b60405180910390f35b6100d6610286565b6040516100e391906107cf565b60405180910390f35b6100f4610325565b60405180606001604052808473ffffffffffffffffffffffffffffffffffffffff168152602001838152602001600254815250905092915050565b6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663893d20e86040518163ffffffff1660e01b815260040160206040518083038186803b15801561019657600080fd5b505afa1580156101aa573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052506101ce91908101906105c6565b73ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461020557600080fd5b806040015160028190555050565b600061021d610325565b600080905060008460400151118015610241575061023f868560200151610290565b155b8015610253575061025286866102cb565b5b1561026e578360400180518091906001900381525050600190505b85846020018190525080849250925050935093915050565b6000600254905090565b6000816000015183600001511480156102b0575081602001518360200151145b80156102c3575081604001518360400151145b905092915050565b600080600090505b8251811015610319576102fd848483815181106102ec57fe5b602002602001015160200151610290565b1561030c57600191505061031f565b80806001019150506102d3565b50600090505b92915050565b6040518060600160405280600073ffffffffffffffffffffffffffffffffffffffff168152602001610355610362565b8152602001600081525090565b60405180606001604052806000815260200160008152602001600081525090565b60008135905061039281610891565b92915050565b6000815190506103a781610891565b92915050565b600082601f8301126103be57600080fd5b81356103d16103cc82610817565b6107ea565b915081818352602084019350602081019050838560808402820111156103f657600080fd5b60005b83811015610426578161040c8882610445565b8452602084019350608083019250506001810190506103f9565b5050505092915050565b60008135905061043f816108a8565b92915050565b60006080828403121561045757600080fd5b61046160406107ea565b90506000610471848285016105b1565b6000830152506020610485848285016104f1565b60208301525092915050565b600060a082840312156104a357600080fd5b6104ad60606107ea565b905060006104bd84828501610383565b60008301525060206104d1848285016104f1565b60208301525060806104e5848285016105b1565b60408301525092915050565b60006060828403121561050357600080fd5b61050d60606107ea565b9050600061051d84828501610430565b600083015250602061053184828501610430565b602083015250604061054584828501610430565b60408301525092915050565b60006060828403121561056357600080fd5b61056d60606107ea565b9050600061057d84828501610430565b600083015250602061059184828501610430565b60208301525060406105a584828501610430565b60408301525092915050565b6000813590506105c0816108bf565b92915050565b6000602082840312156105d857600080fd5b60006105e684828501610398565b91505092915050565b6000806080838503121561060257600080fd5b600061061085828601610383565b925050602061062185828601610551565b9150509250929050565b600060a0828403121561063d57600080fd5b600061064b84828501610491565b91505092915050565b6000806000610120848603121561066a57600080fd5b600061067886828701610551565b935050606084013567ffffffffffffffff81111561069557600080fd5b6106a1868287016103ad565b92505060806106b286828701610491565b9150509250925092565b6106c58161083f565b82525050565b6106d481610851565b82525050565b6106e38161085d565b82525050565b60a0820160008201516106ff60008501826106bc565b506020820151610712602085018261072b565b506040820151610725608085018261076d565b50505050565b60608201600082015161074160008501826106da565b50602082015161075460208501826106da565b50604082015161076760408501826106da565b50505050565b61077681610887565b82525050565b61078581610887565b82525050565b600060c0820190506107a060008301856106cb565b6107ad60208301846106e9565b9392505050565b600060a0820190506107c960008301846106e9565b92915050565b60006020820190506107e4600083018461077c565b92915050565b6000604051905081810181811067ffffffffffffffff8211171561080d57600080fd5b8060405250919050565b600067ffffffffffffffff82111561082e57600080fd5b602082029050602081019050919050565b600061084a82610867565b9050919050565b60008115159050919050565b6000819050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b61089a8161083f565b81146108a557600080fd5b50565b6108b18161085d565b81146108bc57600080fd5b50565b6108c881610887565b81146108d357600080fd5b5056fea365627a7a723158205ddbbc5d6302ab271b88fcaeac57025bd78ee33ad77231bf714823bfb81cea2c6c6578706572696d656e74616cf564736f6c63430005100040";
        bytes memory bytecode2 = abi.encodePacked(bytecode, abi.encode(address(this), id)); // constructor argument
        assembly {
            addr := create(0, add(bytecode2, 0x20), mload(bytecode2))
        }
        require(addr != address(0), "Contract creation failed.");
        contracts[id] = addr;
        return addr;
    }
    function mintInternal(int256[] memory size, bytes memory bytecode) internal returns (uint256) {
        uint256 id = ++nonce;
        require(size.length == 3 && size[0] > 0 && size[0] < maxTokenSize[0] && size[1] > 0 && size[1] < maxTokenSize[1] && size[2] > 0 && size[2] < maxTokenSize[2], "Invalid size");
        minterApproval[id][msg.sender] = true;
        balances[id][msg.sender]++;
        sizes[id] = size;
        contracts[id] = createInternal(bytecode, id);
        operatorApproval[msg.sender][contracts[id]] = true;
        
        emit TransferSingle(msg.sender, address(0), msg.sender, id, 1);
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

    /* function mint(uint256 id, address addr, int256[] calldata size) external returns (uint256) {
        return mintInternal(id, size);
    } */
    function mint(int256[] calldata size, bytes calldata bytecode, string calldata _key, string calldata _value) external returns (uint256) {
        uint256 id = mintInternal(size, bytecode);
        setMetadataInternal(id, _key, _value);
        return id;
    }
    /* function mintWithMetadata1(uint256 id, address addr, uint256 count, string calldata _key1, string calldata _value1) external returns (uint256) {
        id = mintInternal(id, addr, count);
        setMetadataInternal(id, _key1, _value1);
        return id;
    }
    function mintWithMetadata2(uint256 id, address addr, uint256 count, string calldata _key1, string calldata _value1, string calldata _key2, string calldata _value2) external returns (uint256) {
        id = mintInternal(id, addr, count);
        setMetadataInternal(id, _key1, _value1);
        setMetadataInternal(id, _key2, _value2);
        return id;
    }
    function mintWithMetadata3(uint256 id, address addr, uint256 count, string calldata _key1, string calldata _value1, string calldata _key2, string calldata _value2, string calldata _key3, string calldata _value3) external returns (uint256) {
        id = mintInternal(id, addr, count);
        setMetadataInternal(id, _key1, _value1);
        setMetadataInternal(id, _key2, _value2);
        setMetadataInternal(id, _key3, _value3);
        return id;
    } */
    function isMinted(uint256 id) external view returns (bool) {
        return id <= nonce;
    }
    function getNonce() external view returns (uint256) {
        return nonce;
    }
    
    // grid
    
    function getSize(uint256 id) external view returns (int256[] memory) {
      return sizes[id];
    }
    function intersectsRect(int256 x1, int256 z1, int256 x2, int256 z2, int256 x3, int256 z3, int256 x4, int256 z4) internal pure returns (bool) {
        x2 += x1;
        z2 += z1;
        x4 += x3;
        z4 += z3;
        // If one rectangle is on left side of other 
        // l1.x, l1.y, r1.x, r1.y, l2.x, l2.y, r2.x, r2.y,
        if (x1 > x4 || x3 > x2) 
            return false; 
      
        // If one rectangle is above other 
        if (z1 < z4 || z3 < z2) 
            return false; 
      
        return true; 
    }
    function unbindFromGridInternal(uint256 id) internal {
        int256[] storage oldBinding = bindings[id];
        if (oldBinding.length > 0) {
            grid[oldBinding[0]][oldBinding[2]] = 0;
            oldBinding.length = 0;
        }
    }
    function bindToGrid(uint256 id, int256[] calldata location) external {
        require(balances[id][msg.sender] > 0, "Token not owned.");
        require(location.length == 3);
        
        unbindFromGridInternal(id);
        
        int256[] storage size = sizes[id];
        for (int256 x = location[0] - maxTokenSize[0]; x < location[0] + maxTokenSize[0]; x++) {
            for (int256 z = location[2] - maxTokenSize[2]; z < location[2] + maxTokenSize[2]; z++) {
                if (grid[x][z] != 0) {
                  require(!intersectsRect(x, z, sizes[grid[x][z]][0], sizes[grid[x][z]][2], location[0], location[2], size[0], size[2]));
                }
            }
        }

        grid[location[0]][location[2]] = id;
        bindings[id] = location;
    }
    function unbindFromGrid(uint256 id) external {
        require(bindings[id].length > 0, "Token not boudn to grid");
        unbindFromGridInternal(id);
    }
    function getGridTokenIds(int256[] calldata location, int256[] calldata range) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](256);
        uint256 index = 0;
        for (int256 x = location[0] - maxTokenSize[0]; x < location[0] + range[0] + maxTokenSize[0]; x++) {
            for (int256 z = location[2] - maxTokenSize[2]; x < location[2] + range[2] + maxTokenSize[2]; z++) {
                if (grid[x][z] != 0) {
                    if (intersectsRect(x, z, sizes[grid[x][z]][0], sizes[grid[x][z]][2], location[0], location[2], range[0], range[2])) {
                        result[index++] = grid[x][z];
                    }
                }
            }
        }
        uint256[] memory result2 = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            result2[i] = result[i];
        }
        return result2;
    }
    function unbindFromTokenInternal(uint256 to) internal {
        uint256 from = subtokenBindings[to];
        if (from != 0) {
            subtokens[from][to] = 0;
            uint256[] storage subtokenIdsList = subtokenIds[from];
            for (uint256 i = 0; i < subtokenIdsList.length; i++) {
                if (subtokenIdsList[i] == to) {
                  subtokenIdsList[i] = 0;
                }
            }
        }
    }
    function _getRootToken(uint256 id) internal view returns (uint256) {
        uint256 parentId = subtokenBindings[id];
        if (parentId != 0) {
            return parentId;
        } else {
            return _getRootToken(parentId);
        }
    }
    function bindToToken(uint256 from, uint256 to, uint256 location) external {
        require(from != to, "From and to tokens must be different");
        require(balances[from][msg.sender] > 0, "From token not owned");
        require(balances[to][msg.sender] > 0, "To token not owned");
        require(bindings[from].length > 0, "From token not bound to grid");

        unbindFromGridInternal(to);
        unbindFromTokenInternal(to);
        
        subtokens[from][to] = location;
        subtokenIds[from].push(to);
        subtokenBindings[to] = from;
        
        require(_getRootToken(to) == 0, "Could not find root token");
    }
    function unbindFromToken(uint256 id) external {
        require(subtokenBindings[id] != 0, "Token not bound to token");
        unbindFromTokenInternal(id);
    }
    function getSubtokenIds(uint256 id) external view returns (uint256[] memory) {
        return subtokenIds[id];
    }
    
    /* function deposit(uint256 _toId, address remoteContractAddress, uint256 _id, uint256 _value, bytes calldata _data) external {
        IERC1155 remoteContract = IERC1155(remoteContractAddress);
        address localContractAddress = address(this);
        require(remoteContract.isApprovedForAll(msg.sender, localContractAddress), "Need to approve this contract as operator for remote contract");
        remoteContract.safeTransferFrom(msg.sender, localContractAddress, _id, _value, _data);
        assets[_toId][remoteContractAddress][_id] += _value;
    }
    function withdraw(uint256 _fromId, address remoteContractAddress, uint256 _id, uint256 _value, bytes calldata _data) external {
        require(balances[_fromId][msg.sender] > 0);
        require(assets[_fromId][remoteContractAddress][_id] >= _value, "Insufficient tokens deposited");
        assets[_fromId][remoteContractAddress][_id] -= _value;
        IERC1155 remoteContract = IERC1155(remoteContractAddress);
        address localContractAddress = address(this);
        remoteContract.safeTransferFrom(localContractAddress, msg.sender, _id, _value, _data);
    }
    function depositAll(uint256 _toId, address[] calldata remoteContractAddresses, uint256[][] calldata _ids, uint256[][] calldata _values, bytes[] calldata _datas) external {
        address localContractAddress = address(this);
        for (uint256 i = 0; i < remoteContractAddresses.length; i++) {
            require(_ids[i].length == _values[i].length);
            IERC1155 remoteContract = IERC1155(remoteContractAddresses[i]);
            require(remoteContract.isApprovedForAll(msg.sender, localContractAddress), "Need to approve this contract as operator for remote contract");
            remoteContract.safeBatchTransferFrom(msg.sender, localContractAddress, _ids[i], _values[i], _datas[i]);
            for (uint256 j = 0; j < _ids[i].length; j++) {
                assets[_toId][remoteContractAddresses[i]][_ids[i][j]] += _values[i][j];
            }
        }
    }
    function withdrawAll(uint256 _toId, address[] calldata remoteContractAddresses, uint256[][] calldata _ids, uint256[][] calldata _values, bytes[] calldata _datas) external {
        address localContractAddress = address(this);
        for (uint256 i = 0; i < remoteContractAddresses.length; i++) {
            for (uint256 j = 0; j < _ids[i].length; j++) {
                require(_ids[i].length == _values[i].length);
                require(assets[_toId][remoteContractAddresses[i]][_ids[i][j]] >= _values[i][j], "Insufficient tokens");
            }
            IERC1155 remoteContract = IERC1155(remoteContractAddresses[i]);
            remoteContract.safeBatchTransferFrom(localContractAddress, msg.sender, _ids[i], _values[i], _datas[i]);
            for (uint256 j = 0; j < _ids[i].length; j++) {
                assets[_toId][remoteContractAddresses[i]][_ids[i][j]] -= _values[i][j];
            }
        }
    } */
    
    // metadata
    
    function getMetadata(uint256 _id, string memory _key) public view returns (string memory) {
      return metadata[_id][_key];
    }
    function setMetadata(uint256 _id, string calldata _key, string calldata _value) external {
      require(balances[_id][msg.sender] > 0);
      setMetadataInternal(_id, _key, _value);
    }
    /* function setMetadataFromSignature(uint256 _id, string calldata _key, string calldata _value, bytes calldata signature) external {
      require(checkSignature(_id, signature));
      setMetadataInternal(_id, _key, _value);
    } */
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
    
    // children

    function getContract(uint256 id) external view returns (address) {
        return contracts[id];
    }
    /* function setChildMetadata() external pure {} */
    /* function childChangeBalance(uint256 id, address addr, int256 value) external {
       require(contracts[id] == msg.sender);
       require(value != 0);

       int256 newBalance = int256(balances[id][addr]) + value;
       if (newBalance >= 0) {
            balances[id][addr] = uint256(newBalance);
       }
       if (value > 0) {
           emit TransferSingle(msg.sender, address(0), addr, id, uint256(value));
       } else {
           emit TransferSingle(msg.sender, addr, address(0), id, uint256(-value));
       }
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
    function safeTransferFromInternal(address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {
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
        
        for (uint256 i = 0; i < subtokenIds[_id].length; i++) {
          safeTransferFromInternal(_from, _to, subtokenIds[_id][i], _value, _data);
        }
    }
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {
        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        safeTransferFromInternal(_from, _to, _id, _value, _data);
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
        
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            for (uint256 j = 0; j < subtokenIds[id].length; j++) {
              safeTransferFromInternal(_from, _to, subtokenIds[id][j], value, _data);
            }
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
