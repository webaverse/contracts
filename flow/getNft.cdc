import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import WebaverseNFT from WEBAVERSENFTADDRESS

pub fun main() : [String?] {
    let id : UInt64 = ARG0

    return [
      WebaverseNFT.idToHashMap[id],
      WebaverseNFT.getMetadata(id: id, key: "filename")
    ]
}
