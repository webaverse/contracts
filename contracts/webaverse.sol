pragma solidity ^0.5.10;

interface ERC721Metadata {
    // Required methods
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract Webaverse is ERC721Metadata {
  /*** CONSTANTS ***/

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

  // string public constant name = "Webaverse";
  // string public constant symbol = "WEBAVERSE";

  function name() public view returns (string memory _name) {
    return "Webaverse";
  }
  function symbol() public view returns (string memory _symbol) {
    return "WEBV";
  }
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return strConcat('https://token.webaverse.com/', uint2str(tokenId));
  }

  bytes4 constant InterfaceID_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceID_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)'));


  /*** DATA TYPES ***/

  struct Token {
    uint256 id;
    string name;
  } 
  struct TokenOwnership {
    uint256 tokenId;
    bool done;
  }
  
  event Mint(address owner, uint256 tokenId);

  /*** STORAGE ***/

  address[] public _owners;
  // uint256 public tokenIds = 0;
  uint256 public numTokens = 0;
  mapping (uint256 => Token) public tokens;
  mapping (string => uint256) public tokenNameToIndex;
  mapping (uint256 => address) public tokenIndexToOwner;
  mapping (address => TokenOwnership[]) public ownerToTokenOwnership;
  mapping (uint256 => address) public tokenIndexToApproved;

  /*** EVENTS ***/

  // event Mint(address owner, uint256 tokenId);

  /*** INTERNAL FUNCTIONS ***/

  constructor() public {
    _owners.push(msg.sender);
  }
  
  function isOwner(address addr) internal view returns (bool) {
    for (uint i = 0; i < _owners.length; i++) {
      if (_owners[i] == addr) {
        return true;
      }
    }
    return false;
  }
  
  function addOwner(address newOwner) public {
    require(isOwner(msg.sender) && !isOwner(newOwner));
    _owners.push(newOwner);
  }
  
  function removeOwner(address oldOwner) external {
    require(isOwner(msg.sender) && isOwner(oldOwner));
    address[] memory newOwners = new address[](_owners.length - 1);
    uint j = 0;
    for (uint i = 0; i < _owners.length; i++) {
      if (_owners[i] != oldOwner) {
        newOwners[j++] = _owners[i];
      }
    }
    _owners = newOwners;
  }

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenIndexToOwner[_tokenId] == _claimant;
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenIndexToApproved[_tokenId] == _claimant;
  }

  function _approve(address _to, uint256 _tokenId) internal {
    tokenIndexToApproved[_tokenId] = _to;

    emit Approval(tokenIndexToOwner[_tokenId], tokenIndexToApproved[_tokenId], _tokenId);
  }

  function _mint(uint256 tokenId, address owner, string memory _name) internal returns (uint256) {
    // uint tokenId = ++tokenIds;
    tokens[tokenId] = Token({
      id: tokenId,
      name: _name
    });
    tokenNameToIndex[_name] = tokenId;
    numTokens++;

    _transfer(address(0), owner, tokenId);

    emit Mint(owner, tokenId);
    
    return tokenId;
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    if (_from != address(0)) {
      TokenOwnership[] storage fromTokens = ownerToTokenOwnership[_from];
      for (uint i = 0; i < fromTokens.length; i++) {
        TokenOwnership storage tokenOwnership = fromTokens[i];
        if (tokenOwnership.tokenId == _tokenId) {
          tokenOwnership.done = true;
        }
      }
      delete tokenIndexToApproved[_tokenId];
    }
    
    TokenOwnership[] storage toTokens = ownerToTokenOwnership[_to];
    toTokens.push(TokenOwnership({
      tokenId: _tokenId,
      done: false
    }));
    tokenIndexToOwner[_tokenId] = _to;

    emit Transfer(_from, _to, _tokenId);
  }

  /*** ERC721 IMPLEMENTATION ***/

  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return ((_interfaceID == InterfaceID_ERC165) || (_interfaceID == InterfaceID_ERC721));
  }

  function totalSupply() public view returns (uint256) {
    // return tokenIds;
    return numTokens;
  }

  function balanceOf(address owner) public view returns (uint256) {
    uint256 result = 0;
    TokenOwnership[] storage tokenOwnerships = ownerToTokenOwnership[owner];
    for (uint i = 0; i < tokenOwnerships.length; i++) {
      TokenOwnership storage tokenOwnership = tokenOwnerships[i];
      if (!tokenOwnership.done) {
        result++;
      }
    }
    return result;
  }

  function ownerOf(uint256 _tokenId) external view returns (address addr) {
    addr = tokenIndexToOwner[_tokenId];
    require(addr != address(0));
  }

  function approve(address _to, uint256 _tokenId) external {
    require(_owns(msg.sender, _tokenId));

    _approve(_to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) external {
    // require(_to != address(0));
    // require(_to != address(this));
    require(_owns(msg.sender, _tokenId) || _approvedFor(msg.sender, _tokenId) || isOwner(msg.sender));

    _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    // require(_to != address(0));
    // require(_to != address(this));
    require(_approvedFor(msg.sender, _tokenId) || isOwner(msg.sender));
    require(_owns(_from, _tokenId));

    _transfer(_from, _to, _tokenId);
  }

  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    uint256 balance = balanceOf(owner);

    if (balance == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](balance);
      
      TokenOwnership[] storage tokenOwnerships = ownerToTokenOwnership[owner];
      for (uint i = 0; i < tokenOwnerships.length; i++) {
        TokenOwnership storage tokenOwnership = tokenOwnerships[i];
        if (!tokenOwnership.done) {
          result[i] = tokenOwnership.tokenId;
        }
      }

      return result;
    }
  }


  /*** OTHER EXTERNAL FUNCTIONS ***/

  function mintToken(uint256 tokenId, address addr, string calldata _name) external {
    require(isOwner(msg.sender));
    // require((tokenIds+1) == tokenId);
    require(tokenNameToIndex[_name] == 0);
    _mint(tokenId, addr, _name);
  }
  
  function renameToken(uint256 tokenId, string calldata _name) external {
    require(tokenIndexToOwner[tokenId] == msg.sender);
    require(tokenNameToIndex[_name] == 0);

    Token storage token = tokens[tokenId];
    tokenNameToIndex[token.name] = 0;
    token.name = _name;
    tokenNameToIndex[token.name] = tokenId;
  }

  function getTokenById(uint256 _tokenId) external view returns (address owner, uint256 id, string memory _name) {
    Token storage token = tokens[_tokenId];

    owner = tokenIndexToOwner[_tokenId];
    id = token.id;
    _name = token.name;
  }
  
  function getTokenByName(string calldata _name) external view returns (address owner, uint256 id, string memory _name2) {
    id = tokenNameToIndex[_name];
    if (id != 0) {
        Token storage token = tokens[id];

        owner = tokenIndexToOwner[id];
        id = token.id;
        _name2 = token.name;
    } else {
      owner = address(0);
      id = id;
      _name2 = "";
    }
  }
}
