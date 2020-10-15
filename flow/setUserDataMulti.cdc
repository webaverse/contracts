import WebaverseAccount from WEBAVERSEACCOUNTADDRESS

transaction {

    let state: &WebaverseAccount.State

    prepare(signer: AuthAccount) {
        self.state = signer.borrow<&WebaverseAccount.State>(from: /storage/AccountCollection)
            ?? panic("Could not borrow a reference to the account state")
    }

    execute {
        let keys : [String] = ARG0
        let values : [String] = ARG1

        var i = 0
        while i < keys.length {
          let key : String = keys[i]
          let value : String = values[i]
          self.state.keyValueMap[key] = value
          i = i + 1
	    }
    }
}
