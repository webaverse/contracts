import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import WebaverseNFT from WEBAVERSENFTADDRESS

pub fun main() : Uint64? {
    let hash : String = ARG0

    return WebaverseNFT.hashToIdMap[hash];
}
