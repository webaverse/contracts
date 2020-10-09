import WebaverseAccount from WEBAVERSEACCOUNTADDRESS

pub fun main() : Bool {
    let acct = getAccount(ARG0)
    
    let collectionRef = acct.getCapability(/public/AccountCollection)!.borrow<&{WebaverseAccount.WebaverseAccountStatePublic}>() ?? nil

    return collectionRef != nil
}
