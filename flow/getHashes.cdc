import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import ExampleNFT from EXAMPLENFTADDRESS

// This transaction returns an array of all the nft ids in the collection

pub struct Entry {
    pub let id : UInt64
    pub let hash : String

    init(id: UInt64, hash : String) {
        self.id = id
        self.hash = hash
    }
}
pub fun main() : [Entry] {
    let acct = getAccount(ARG0)
    let collectionRef = acct.getCapability(/public/NFTCollection)!.borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    let ids : [UInt64] = collectionRef.getIDs()
    let res : [Entry] = []
    for id in ids {
      let hash = ExampleNFT.idToHashMap[id] ?? ""
      let e : Entry = Entry(id: id, hash: hash);
      res.append(e)
    }
    return res
}