import FungibleToken from "../../contracts/FungibleToken.cdc"
import BNU from "../../contracts/BNU.cdc"

// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the BNU

transaction {

    prepare(signer: AuthAccount) {

        if signer.borrow<&BNU.Vault>(from: BNU.StorageVaultPath) == nil {
            // Create a new BNU Vault and put it in storage
            signer.save(<-BNU.createEmptyVault(), to: BNU.StorageVaultPath)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&BNU.Vault{FungibleToken.Receiver}>(
                BNU.ReceiverPath,
                target: BNU.StorageVaultPath
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&BNU.Vault{FungibleToken.Balance}>(
                BNU.BalancePublicPath,
                target: BNU.StorageVaultPath
            )
        }
    }
}