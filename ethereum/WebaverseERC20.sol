// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./WebaverseVoucher.sol";

contract WebaverseERC20 is
    ERC20Upgradeable,
    WebaverseVoucher,
    OwnableUpgradeable
{
    // Mapping of addresses that are allowed to mint tokens
    mapping(address => bool) private _whitelistedMinters;

    // Max supply of tokens
    uint256 private _maxSupply;

    // url of tokens
    string private _tokenuri;

    // Event occuring when a token is redeemed by a user in the webaverse world for the native smart contract
    event Claim(address signer, address claimer, uint256 balance);

    // Event occuring when a token is redeemed by a user in the webaverse world for the external smart contract
    event ExternalClaim(
        address indexed externalContract,
        address signer,
        address claimer,
        uint256 balance
    );

    modifier onlyMinter() {
        require(
            isAllowedMinter(_msgSender()),
            "ERC20: Only white listed minters are allowed to mint"
        );
        _;
    }

    /**
     * @dev Create a new fungible token
     * @param name Name of the token
     * @param symbol Token identifier
     * @param maxSupply_ Sets the token market cap. This value is immutable, it can only be
     * set once during construction.
     * Default cap: 2147483648000000000000000000 or (2**31) + '000000000000000000'
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 maxSupply_
    ) public initializer {
        __Ownable_init_unchained();
        __ERC20_init(name, symbol);
        _webaverse_voucher_init();
        _maxSupply = maxSupply_;
        _whitelistedMinters[msg.sender] = true;
    }

    /**
     * @return Maximum number of tokens that can be minted
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Mint ERC20 tokens
     * @param to Tokens created for this account
     * @param amount Number of tokens to mint for this call
     */
    function mint(address to, uint256 amount) public onlyMinter {
        require(
            totalSupply() + amount <= maxSupply(),
            "ERC20: Max supply reached"
        );
        _mint(to, amount);
    }
    
    /**
     * @dev Mint ERC20 tokens
     * @param signer The address of the account which signed the NFT Voucher.
     * @param to Tokens created for this account
     * @param voucher A signed NFTVoucher(FTVoucher) that describes the FT to be redeemed.
     */
    function mintServerDropFT(address signer, address to, NFTVoucher calldata voucher) public onlyMinter {
        require(
            totalSupply() + voucher.balance <= maxSupply(),
            "ERC20: Max supply reached"
        );

        require(owner() == signer, "Wrong signature!");

        _mint(to, voucher.balance);
    }

    /**
     * @dev Checks if an address is allowed to mint ERC20 tokens
     * @param account address to check for the white listing for
     * @return true if address is allowed to mint
     */
    function isAllowedMinter(address account) public view returns (bool) {
        return _whitelistedMinters[account];
    }

    /**
     * @dev Add an account to the list of accounts allowed to create ERC20 tokens
     * @param minter address to whitelist
     */
    function addMinter(address minter) public onlyOwner {
        require(!isAllowedMinter(minter), "ERC20: Minter already added");
        _whitelistedMinters[minter] = true;
    }

    /**
     * @dev Remove an account from the list of accounts allowed to create ERC20 tokens
     * @param minter address to remove from whitelist
     */
    function removeMinter(address minter) public onlyOwner {
        require(isAllowedMinter(minter), "ERC20: Minter does not exist");
        _whitelistedMinters[minter] = false;
    }

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner.
     * @param signer The address of the account which signed the NFT Voucher.
     * @param claimer The address of the account which will receive the NFT upon success.
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     */
    function claim(address signer, address claimer, NFTVoucher calldata voucher)
        public
        virtual
        returns (uint256)
    {
        require(
            balanceOf(signer) != 0,
            "WBVRS: Authorization failed: Invalid signature"
        );

        // transfer the token to the claimer
        _transfer(signer, claimer, voucher.balance);
        emit Claim(signer, claimer, voucher.balance);
        return voucher.balance;
    }

    /**
     * @notice Redeems an Voucher for actual ERC20 tokens, authorized by the owner from an external contract.
     * @param claimer The address of the account which will receive the balance upon success.
     * @param contractAddress The address of the contract from which the token is being transferred
     * @param voucher A signed Voucher that describes the ERC20 tokens to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     */
    function externalClaim(
        address claimer,
        address contractAddress,
        NFTVoucher calldata voucher
    ) public returns (uint256) {
        IERC20Upgradeable externalContract = IERC20Upgradeable(contractAddress);
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        require(
            externalContract.balanceOf(signer) != 0,
            "WBVRS: Authorization failed: Invalid signature"
        );
        require(
            externalContract.allowance(signer, address(this)) > 0,
            "WBVRS: Aprroval not set for WebaverseERC20"
        );

        // transfer the token to the claimer
        externalContract.transferFrom(signer, claimer, voucher.balance);
        emit ExternalClaim(contractAddress, signer, claimer, voucher.balance);
        return voucher.balance;
    }
}
