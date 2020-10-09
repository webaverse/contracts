import FungibleToken from FUNGIBLETOKENADDRESS
import WebaverseToken from WEBAVERSETOKENADDRESS

transaction {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {
        let amount : UFix64 = ARG0

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&WebaverseToken.Vault>(from: /storage/webaverseTokenVault)
      ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        let to : Address = ARG1

        // Get the recipient's public account object
        let recipient = getAccount(to)

        // Get a reference to the recipient's Receiver
        let receiverRef = recipient.getCapability(/public/exampleTokenReceiver)!.borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-self.sentVault)
    }
}
