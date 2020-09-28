import ExampleAccount from EXAMPLEACCOUNTADDRESS
import ExampleNFT from EXAMPLENFTADDRESS

pub fun parseUInt64(s: String?) : UInt64? {
    var res : UInt64 = 0
    if (s != nil) {
        let s2 = s!
        if (s2.length > 0) {
	        var i = 0
	        while i < s2.length {
	            if (i != 0) {
	                res = res * UInt64(10)
	            }
	            let c = s2[i]
	            let char0 : Character = "0"
	            let char1 : Character = "1"
	            let char2 : Character = "2"
	            let char3 : Character = "3"
	            let char4 : Character = "4"
	            let char5 : Character = "5"
	            let char6 : Character = "6"
	            let char7 : Character = "7"
	            let char8 : Character = "8"
	            let char9 : Character = "9"

	            if c == char0 {
	                res = res + UInt64(0)
	            } else if c == char1 {
	                res = res + UInt64(1)
	            } else if c == char2 {
	                res = res + UInt64(2)
	            } else if c == char3 {
	                res = res + UInt64(3)
	            } else if c == char4 {
	                res = res + UInt64(4)
	            } else if c == char5 {
	                res = res + UInt64(5)
	            } else if c == char6 {
	                res = res + UInt64(6)
	            } else if c == char7 {
	                res = res + UInt64(7)
	            } else if c == char8 {
	                res = res + UInt64(8)
	            } else if c == char9 {
	                res = res + UInt64(9)
	            } else {
	                return nil
	            }
	            i = i + 1
	        }
        } else {
            return nil
        }
    }
    return res
}

pub fun main() : [String?] {
    let acct = getAccount(0x0911253774d38330)
    
    let collectionRef = acct.getCapability(/public/AccountCollection)!.borrow<&{ExampleAccount.ExampleAccountStatePublic}>()
      ?? panic("Could not borrow capability from public collection")

    var avatarIdString : String? = collectionRef.keyValueMap["avatar"]
    var avatarId : UInt64? = nil
    if (avatarIdString != nil) {
        avatarId = parseUInt64(s: avatarIdString!)
    }
    var avatarHash : String? = nil
    if (avatarId != nil) {
        avatarHash = ExampleNFT.idToHashMap[avatarId!]
    }
    return [
      collectionRef.keyValueMap["name"],
      avatarHash
    ]
}