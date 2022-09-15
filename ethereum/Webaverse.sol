// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./WebaverseERC1155.sol";
import "./WebaverseERC20.sol";

contract Webaverse is WebaverseVoucher, OwnableUpgradeable {
    WebaverseERC1155 private _nftContract;
    WebaverseERC20 private _silkContract;
    uint256 private _mintFee; // ERC20 fee to mint ERC721
    address private _treasuryAddress;
    using ECDSA for bytes32;

    /**
     * @dev Creates the Upgradeable Webaverse contract
     * @param _nftAddress WebaverseERC721 contract address for Non-fungible tokens
     * @param _silkAddress WebaverseERC20 contract address for fungible tokens
     * @param mintFee_ The amount of WebaverseERC20 tokens required to mint a single NFT
     * @param treasuryAddress_ Address of the treasury account
     */
    function initialize(
        address _nftAddress,
        address _silkAddress,
        uint256 mintFee_,
        address treasuryAddress_
    ) public initializer {
        __Ownable_init();
        _webaverse_voucher_init();
        _nftContract = WebaverseERC1155(_nftAddress);
        _silkContract = WebaverseERC20(_silkAddress);
        _mintFee = mintFee_;
        _treasuryAddress = treasuryAddress_;
    }

    /**
     * @return The amount of ERC20 tokens required to mint the ERC721 NFT
     */
    function mintFee() public view returns (uint256) {
        return _mintFee;
    }

    /**
     * @return The address of Webaverse ERC721 contract
     */
    function nftContractAddress() public view returns (address) {
        return address(_nftContract);
    }

    /**
     * @return The address of Webaverse ERC20 contract
     */
    function silkContractAddress() public view returns (address) {
        return address(_silkContract);
    }

    /**
     * @dev Set the contract instance for ERC721
     * @param _nftContractAddress The address of the ERC721 contract that needs to be set
     */
    function setNftAddress(address _nftContractAddress) public onlyOwner {
        _nftContract = WebaverseERC1155(_nftContractAddress);
    }

    /**
     * @dev Set the contract instance for ERC20
     * @param _silkAddress The address of the ERC20 contract that needs to be set
     */
    function setSilkAddress(address _silkAddress) public onlyOwner {
        _silkContract = WebaverseERC20(_silkAddress);
    }

    /**
     * @dev Set the price to mint
     * @param mintFee_ Minting fee, default is 10 FT
     */
    function setMintFee(uint256 mintFee_) public onlyOwner {
        _mintFee = mintFee_;
    }

    /**
     * @return The address that is used for receiving mint fee (ERC20 tokens)
     */
    function treasuryAddress() public view returns (address) {
        return _treasuryAddress;
    }

    /**
     * @dev Set the treasury address
     * @param treasuryAddress_ Account address of the treasurer
     */
    function setTreasuryAddress(address treasuryAddress_) public onlyOwner {
        _treasuryAddress = treasuryAddress_;
    }

    /**
     * @notice Mints the a single NFT with given parameters.
     * @param to The address on which the NFT will be minted.
     * @param balance Total amount for the given token.
     * @param uri URI of the NFT.
     **/
    function mint(
        address to,
        uint256 balance,
        string memory uri,
        string memory name,
        bytes memory data
    ) public {
        if (mintFee() != 0) {
            require(
                _silkContract.transferFrom(
                    msg.sender,
                    treasuryAddress(),
                    mintFee()
                ),
                "Webaverse: Mint transfer failed"
            );
        }
        _nftContract.mint(to, balance, uri, name, data);
    }

    /**
     * @notice Claims(Mints) the a single NFT with given parameters.
     * @param to The address on which the NFT will be minted(claimed).
     * @param data The data to store when claim.
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     **/
    function claim_NFT(
        address to,
        bytes memory data,
        NFTVoucher calldata voucher
    ) public {
        address signer = verifyVoucher(voucher);

        if (mintFee() != 0) {
            require(
                _silkContract.transferFrom(
                    msg.sender,
                    treasuryAddress(),
                    mintFee()
                ),
                "Webaverse: Mint transfer failed"
            );
        }
        _nftContract.claim(signer, to, data, voucher);
    }

    /**
     * @notice Claims(Mints) the a FT with given parameters.
     * @param to The address on which the FT will be minted(claimed).
     * @param voucher A signed NFTVoucher(FTVoucher) that describes the FT to be redeemed.
     **/
    function claim_FT(
        address to,
        NFTVoucher calldata voucher
    ) public {
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        _silkContract.claim(signer, to, voucher);
    }

    /**
     * @notice Claims(Mints) the a single Server Drop NFT with given parameters.
     * @param to The address on which the NFT will be minted(claimed).
     * @param data The data to store when claim.
     * @param name The name to store when claim.
     * @param level The level to store when claim.
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     **/
    function claimServerDropNFT(
        address to,
        string memory name,
        string memory level,
        bytes memory data,
        NFTVoucher calldata voucher
    ) public {
        if (mintFee() != 0) {
            require(
                _silkContract.transferFrom(
                    msg.sender,
                    treasuryAddress(),
                    mintFee()
                ),
                "Webaverse: Mint transfer failed"
            );
        }

        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        _nftContract.mintServerDropNFT(signer, to, name, level, data, voucher);
    }

    /**
     * @notice Claims(Mints) the a single Server Drop FT with given parameters.
     * @param to The address on which the FT will be minted(claimed).
     * @param voucher A signed NFTVoucher(FTVoucher) that describes the FT to be redeemed.
     **/
    function claimServerDropFT(
        address to,
        NFTVoucher calldata voucher
    ) public {
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        _silkContract.mintServerDropFT(signer, to, voucher);
    }

    /**
     * @notice Mints the a single NFT with given parameters.
     * @param tokenId The id of the token.
     * @param trait_type Name of the attribute (as per opensea metadata standard).
     * @param value String value of the atrribute being added or set (as per opensea metadata standard).
     * @param display_type Display type of the attribute (as per opensea metadata standard).
     **/
    function setAttribute(
        uint256 tokenId,
        string memory trait_type,
        string memory value,
        string memory display_type
    ) public {
        require(
            _nftContract.balanceOf(msg.sender, tokenId) ==
                _nftContract.getTokenBalance(tokenId),
            "Webaverse: Only owner can set attributes"
        );
        _nftContract.setAttribute(tokenId, trait_type, value, display_type);
    }
}
