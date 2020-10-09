import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import WebaverseNFT from WEBAVERSENFTADDRESS

pub fun main() : [String?] {
    let id : UInt64 = ARG0

    return [
      ExampleNFT.idToHashMap[id],
      ExampleNFT.getMetadata(id: id, key: "filename")
    ]
}
