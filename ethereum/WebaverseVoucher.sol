//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract WebaverseVoucher is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "Webaverse-voucher";
    string private constant SIGNATURE_VERSION = "1";

    // mapping to store the bunred nonces for the signers to prevent replay attacks
    mapping(uint256 => bool) public burnedNonces;

    function _webaverse_voucher_init() public initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    /// @dev Represents a schema to claim an NFT, which has already been minted on blockchain. A signed voucher can be redeemed for a real NFT using the claim function.
    struct NFTVoucher {
        // The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the claim function will revert.
        uint256 tokenId;
        // In case of ERC20 and ERC1155 the balance should be greater than 1. For ERC721 it must be set to 1.
        uint256 balance;
        // The valid nonce value of the NFT creator, fetched through _nonces mapping.
        uint256 nonce;
        // The time period for which the voucher is valid.
        uint256 expiry;
        // The EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by the owner account.
        bytes signature;
    }

    /**
     * @notice Verifies an NFTVoucher for an actual NFT, authorized by the owner.
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function verifyVoucher(NFTVoucher calldata voucher)
        public
        returns (address)
    {
        require(
            block.timestamp <= voucher.expiry,
            "Voucher has already expired"
        );

        require(burnedNonces[voucher.nonce] == false, "Invalid nonce value");
        // transfer the token to the claimer
        burnedNonces[voucher.nonce] = true;

        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        return signer;
    }

    /**
     * @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
     * @param voucher An NFTVoucher to hash.
     * @return bytes32 digest of the voucher used for the verification of the signature.
     **/
    function _hash(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 tokenId,uint256 balance,uint256 nonce,uint256 expiry)"
                        ),
                        voucher.tokenId,
                        voucher.balance,
                        voucher.nonce,
                        voucher.expiry
                    )
                )
            );
    }

    /**
     * @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
     * @param voucher An NFTVoucher describing an NFT.
     * @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
     * @return returns the address of the signer on succesful verification.
     **/
    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }
}
