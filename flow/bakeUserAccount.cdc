import FungibleToken from FUNGIBLETOKENADDRESS
import ExampleToken from EXAMPLETOKENADDRESS
import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import ExampleNFT from EXAMPLENFTADDRESS
import ExampleAccount from EXAMPLEACCOUNTADDRESS

transaction {

    prepare(account: AuthAccount) { // begin prepare

        if account.borrow<&ExampleToken.Vault>(from: /storage/exampleTokenVault) == nil {
            // Create a new exampleToken Vault and put it in storage
            account.save(<-ExampleToken.createEmptyVault(), to: /storage/exampleTokenVault)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            account.link<&ExampleToken.Vault{FungibleToken.Receiver}>(
                /public/exampleTokenReceiver,
                target: /storage/exampleTokenVault
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            account.link<&ExampleToken.Vault{FungibleToken.Balance}>(
                /public/exampleTokenBalance,
                target: /storage/exampleTokenVault
            )
        }

        // If the account doesn't already have a collection
        if account.borrow<&ExampleNFT.Collection>(from: /storage/NFTCollection) == nil {

            // Create a new empty collection
            let collection <- ExampleNFT.createEmptyCollection() as! @ExampleNFT.Collection
            // collection.setAddress(account: account)
            
            // save it to the account
            account.save(<-collection, to: /storage/NFTCollection)

            // create a public capability for the collection
            account.link<&{NonFungibleToken.CollectionPublic}>(/public/NFTCollection, target: /storage/NFTCollection)
        }

        // If the account doesn't already have a collection
        if account.borrow<&ExampleAccount.State>(from: /storage/AccountCollection) == nil {

            // Create a new empty collection
            let state <- ExampleAccount.createState() as! @ExampleAccount.State

            // save it to the account
            account.save(<-state, to: /storage/AccountCollection)

            // create a public capability for the collection
            account.link<&{ExampleAccount.ExampleAccountStatePublic}>(/public/AccountCollection, target: /storage/AccountCollection)
        }
    } // end prepare
}