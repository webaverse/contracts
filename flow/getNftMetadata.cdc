import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import WebaverseNFT from WEBAVERSENFTADDRESS

pub fun main() : String? {
    let id : UInt64 = ARG0
    let key : String = "ARG1"
    
    return WebaverseNFT.getMetadata(id: id, key: key)
}
