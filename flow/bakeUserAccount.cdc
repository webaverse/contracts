import FungibleToken from FUNGIBLETOKENADDRESS
import WebaverseToken from WEBAVERSETOKENADDRESS
import NonFungibleToken from NONFUNGIBLETOKENADDRESS
import WebaverseNFT from WEBAVERSENFTADDRESS
import WebaverseAccount from WEBAVERSEACCOUNTADDRESS

transaction {

    prepare(account: AuthAccount) { // begin prepare

        if account.borrow<&WebaverseToken.Vault>(from: /storage/webaverseTokenVault) == nil {
            // Create a new exampleToken Vault and put it in storage
            account.save(<-WebaverseToken.createEmptyVault(), to: /storage/webaverseTokenVault)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            account.link<&WebaverseToken.Vault{FungibleToken.Receiver}>(
                /public/exampleTokenReceiver,
                target: /storage/webaverseTokenVault
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            account.link<&WebaverseToken.Vault{FungibleToken.Balance}>(/public/exampleTokenBalance, target: /storage/webaverseTokenVault)
        }

        // If the account doesn't already have a collection
        if account.borrow<&WebaverseNFT.Collection>(from: /storage/NFTCollection) == nil {

            // Create a new empty collection
            let collection <- WebaverseNFT.createEmptyCollection() as! @WebaverseNFT.Collection
            // collection.setAddress(account: account)
            
            // save it to the account
            account.save(<-collection, to: /storage/NFTCollection)

            // create a public capability for the collection
            account.link<&{NonFungibleToken.CollectionPublic}>(/public/NFTCollection, target: /storage/NFTCollection)
            account.link<&{WebaverseNFT.CollectionPublic}>(/public/WebaverseNFTCollection, target: /storage/NFTCollection)
        }

        // If the account doesn't already have a collection
        if account.borrow<&WebaverseAccount.State>(from: /storage/AccountCollection) == nil {

            // Create a new empty collection
            let state <- WebaverseAccount.createState() as! @WebaverseAccount.State

            // save it to the account
            account.save(<-state, to: /storage/AccountCollection)

            // create a public capability for the collection
            account.link<&{WebaverseAccount.WebaverseAccountStatePublic}>(/public/AccountCollection, target: /storage/AccountCollection)
        }
    } // end prepare
}
