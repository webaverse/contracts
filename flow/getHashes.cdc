import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import WebaverseNFT from WEBAVERSENFTADDRESS

// This transaction returns an array of all the nft ids in the collection

pub struct Entry {
    pub let id : UInt64
    pub let hash : String
    pub let filename : String
    pub let balance : UInt64
    pub let totalSupply : UInt64

    init(id: UInt64, hash: String, filename: String, balance: UInt64, totalSupply: UInt64) {
        self.id = id
        self.hash = hash
        self.filename = filename
        self.balance = balance
        self.totalSupply = totalSupply
    }
}
pub fun main() : [Entry] {
    let acct = getAccount(ARG0)
    let collectionRef = acct.getCapability(/public/NFTCollection)!.borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability 1 from public collection")
    let collectionRef2 = acct.getCapability(/public/ExampleNFTCollection)!.borrow<&{ExampleNFT.CollectionPublic}>()
        ?? panic("Could not borrow capability 2 from public collection")
    
    let ids : [UInt64] = collectionRef.getIDs()
    let res : [Entry] = []
    for id in ids {
      let hash = ExampleNFT.idToHashMap[id] ?? ""
      let filename = ExampleNFT.getMetadata(id: id, key: "filename") ?? ""
      let balance = collectionRef2.getBalance(id: id)
      let totalSupply = ExampleNFT.hashToTotalSupply[hash] ?? UInt64(0)
      let e : Entry = Entry(id: id, hash: hash, filename: filename, balance: balance, totalSupply: totalSupply)
      res.append(e)
    }
    return res
}
