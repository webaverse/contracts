// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC20.sol";
import "./WebaverseERC721.sol";

contract WebaverseTrade {
    WebaverseERC20 parentERC20;
    WebaverseERC721 parentERC721;

    // 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
    constructor (address parentERC20Address, address parentERC721Address) public {
        parentERC20 = WebaverseERC20(parentERC20Address);
        parentERC721 = WebaverseERC721(parentERC721Address);
    }
    
    function trade(
        address from, address to,
        uint256 fromFt, uint256 toFt,
        uint256 a1, uint256 b1,
        uint256 a2, uint256 b2,
        uint256 a3, uint256 b3
    ) public {
        if (fromFt != 0) parentERC20.transferFrom(from, to, fromFt);
        if (toFt != 0) parentERC20.transferFrom(to, from, toFt);
        if (a1 != 0) parentERC721.transferFrom(from, to, a1);
        if (b1 != 0) parentERC721.transferFrom(to, from, b1);
        if (a2 != 0) parentERC721.transferFrom(from, to, a2);
        if (b2 != 0) parentERC721.transferFrom(to, from, b2);
        if (a3 != 0) parentERC721.transferFrom(from, to, a3);
        if (b3 != 0) parentERC721.transferFrom(to, from, b3);
    }
}
