import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import WebaverseNFT from WEBAVERSENFTADDRESS

transaction {
    prepare(acct: AuthAccount) {
        let id : UInt64 = ARG0
        let key : String = "ARG1"
        let value : String = "ARG2"

        // borrow a reference to the signer's NFT collection
        let collectionRef = acct.borrow<&ExampleNFT.Collection>(from: /storage/NFTCollection)
            ?? panic("Could not borrow a reference to the owner's collection")

        collectionRef.setMetadata(id: id, key: key, value: value)
    }
}
