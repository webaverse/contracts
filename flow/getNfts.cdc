import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import ExampleNFT from EXAMPLENFTADDRESS

// This transaction returns an array of all the nft ids in the collection

pub struct Entry {
    pub let id : UInt64
    pub let hash : String
    pub let filename : String
    pub let totalSupply : UInt64

    init(id: UInt64, hash: String, filename: String, totalSupply: UInt64) {
        self.id = id
        self.hash = hash
        self.filename = filename
        self.totalSupply = totalSupply
    }
}
pub fun main() : [Entry] {
    var start : UInt64 = ARG0
    var end : UInt64 = ARG1

    let res : [Entry] = []
    var id : UInt64 = start
    while id < end && id < ExampleNFT.totalSupply {
      let hash = ExampleNFT.idToHashMap[id] ?? ""
      let filename = ExampleNFT.getMetadata(id: id, key: "filename") ?? ""
      let totalSupply = ExampleNFT.hashToTotalSupply[hash] ?? UInt64(0)
      let e : Entry = Entry(id: id, hash: hash, filename: filename, totalSupply: totalSupply)
      res.append(e)
      id = id + UInt64(1)
    }
    return res
}