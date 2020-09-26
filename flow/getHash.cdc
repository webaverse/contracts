import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import ExampleNFT from EXAMPLENFTADDRESS

pub fun main() : String? {
    let id : UInt64 = ARG0

    return ExampleNFT.idToHashMap[id]
}