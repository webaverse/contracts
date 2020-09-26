import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import ExampleNFT from EXAMPLENFTADDRESS

pub fun main() : String? {
    let id : UInt64 = ARG0
    let key : String = "ARG1"
    
    return ExampleNFT.getMetadata(id: id, key: key)
}