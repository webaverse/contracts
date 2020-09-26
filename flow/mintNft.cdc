import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import ExampleNFT from EXAMPLENFTADDRESS

// This script uses the NFTMinter resource to mint a new NFT
// It must be run with the account that has the minter resource
// stored in /storage/NFTMinter

transaction {

    execute {
        let hash : String = "ARG0"
        let filename : String = "ARG1"
        let recipient : Address = ARG2

        let contractAcct = getAccount(EXAMPLENFTADDRESS)
        let minterRef = contractAcct.getCapability(/public/NFTMinter)!.borrow<&{ExampleNFT.PublicNFTMinter}>()
            ?? panic("Could not borrow nft minter capability")

        // Get the public account object for the recipient
        let acct = getAccount(recipient)

        // Borrow the recipient's public NFT collection reference
        let receiver = acct
            .getCapability(/public/NFTCollection)!
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

        // Mint the NFT and deposit it to the recipient's collection
        minterRef.mintNFT(hash: hash, filename: filename, recipient: receiver)
    }
}