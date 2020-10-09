import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import WebaverseNFT from WEBAVERSENFTADDRESS

// This script uses the NFTMinter resource to mint a new NFT
// It must be run with the account that has the minter resource
// stored in /storage/NFTMinter

transaction {

    prepare(acct: AuthAccount) {
        let hash : String = "ARG0"
        let filename : String = "ARG1"
        let quantity : UInt64 = ARG2

        let contractAcct = getAccount(WEBAVERSENFTADDRESS)
        let minterRef = contractAcct.getCapability(/public/NFTMinter)!.borrow<&{ExampleNFT.PublicNFTMinter}>()
            ?? panic("Could not borrow nft minter capability")

        // Borrow the recipient's public NFT collection reference
        let receiver = acct
            .getCapability(/public/NFTCollection)!
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

        // Mint the NFT and deposit it to the recipient's collection
        minterRef.mintNFT(hash: hash, filename: filename, quantity: quantity, recipient: receiver)
    }
}
