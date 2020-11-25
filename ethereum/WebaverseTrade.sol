// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WebaverseERC20.sol";
import "./WebaverseERC721.sol";

contract WebaverseTrade {
    struct Store {
        uint256 id;
        address seller;
        uint256 tokenId;
        uint256 price;
        bool live;
    }
    event Sell(uint256 id,
        address seller,
        uint256 tokenId,
        uint256 price
    );
    event Unsell(uint256 id);

    WebaverseERC20 parentERC20; // managed ERC20 contract
    WebaverseERC721 parentERC721; // managed ERC721 contract
    address signer; // signer oracle address
    uint256 nextBuyId; // next buy id
    mapping(uint256 => Store) stores;

    // 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
    constructor (address parentERC20Address, address parentERC721Address, address signerAddress) public {
        parentERC20 = WebaverseERC20(parentERC20Address);
        parentERC721 = WebaverseERC721(parentERC721Address);
        signer = signerAddress;
        nextBuyId = 0;
    }
    
    function setSigner(address newSigner) public {
        require(msg.sender == signer, "new signer can only be set by old signer");
        signer = newSigner;
    }

    function addStore(uint256 tokenId, uint256 price) public {
        uint256 buyId = ++nextBuyId;
        stores[buyId] = Store(buyId, msg.sender, tokenId, price, true);

        emit Sell(buyId, msg.sender, tokenId, price);

        address contractAddress = address(this);
        parentERC721.transferFrom(msg.sender, contractAddress, tokenId);
    }
    function removeStore(uint256 buyId) public {
        Store storage store = stores[buyId];
        require(store.seller == msg.sender, "not your sale");
        require(store.live, "sale not live");
        store.live = false;
        
        emit Unsell(buyId);

        address contractAddress = address(this);
        parentERC721.transferFrom(contractAddress, store.seller, store.tokenId);
    }
    function buy(uint256 buyId) public {
        Store storage store = stores[buyId];
        require(store.live, "sale not live");
        store.live = false;

        parentERC20.transferFrom(msg.sender, store.seller, store.price);
        address contractAddress = address(this);
        parentERC721.transferFrom(contractAddress, msg.sender, store.tokenId);
    }
    function numStores() public view returns (uint256) {
        return nextBuyId;
    }
    function getStoreByIndex(uint256 buyId) public view returns (Store memory) {
        return stores[buyId];
    }

    function trade(
        address from, address to,
        uint256 fromFt, uint256 toFt,
        uint256 a1, uint256 b1,
        uint256 a2, uint256 b2,
        uint256 a3, uint256 b3
    ) public {
        require(msg.sender == signer, "unauthorized signer");
        if (fromFt != 0) require(parentERC20.transferFrom(from, to, fromFt), "transfer ft from -> to failed");
        if (toFt != 0) require(parentERC20.transferFrom(to, from, toFt), "transfer ft from <- to failed");
        if (a1 != 0) parentERC721.transferFrom(from, to, a1);
        if (b1 != 0) parentERC721.transferFrom(to, from, b1);
        if (a2 != 0) parentERC721.transferFrom(from, to, a2);
        if (b2 != 0) parentERC721.transferFrom(to, from, b2);
        if (a3 != 0) parentERC721.transferFrom(from, to, a3);
        if (b3 != 0) parentERC721.transferFrom(to, from, b3);
    }
}
