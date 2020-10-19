// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Capped.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
contract WebaverseERC20 is ERC20Capped {
    mapping (address => bool) allowedMinters;
    
    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (string memory name, string memory symbol) public ERC20(name, symbol) ERC20Capped(1e27) {
        addAllowedMinter(msg.sender);
    }
    
    function mint(address account, uint256 amount) public {
        require(isAllowedMinter(msg.sender));
        _mint(account, amount);
    }
    
    function isAllowedMinter(address a) public view returns (bool) {
        return allowedMinters[a];
    }
    function addAllowedMinter(address a) public {
        require(isAllowedMinter(msg.sender));
        allowedMinters[a] = true;
    }
    function removeAllowedMinter(address a) public {
        require(isAllowedMinter(msg.sender));
        allowedMinters[a] = false;
    }
}
