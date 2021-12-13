import ByteNextStaking from "../../contracts/ByteNextStaking.cdc";
import FungibleToken from "../../contracts/FungibleToken.cdc";
import BNU from "../../contracts/BNU.cdc"


transaction(amount: UFix64) {
  prepare(signer: AuthAccount) {
    if signer.borrow<&ByteNextStaking.StakingProxy>(from: ByteNextStaking.StakingProxyStoragePath) == nil {
        signer.save(<-ByteNextStaking.createStakingProxy(), to: ByteNextStaking.StakingProxyStoragePath)
    }

    let proxy = signer.borrow<&ByteNextStaking.StakingProxy>(from: ByteNextStaking.StakingProxyStoragePath)!;

    // Setup BNU
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
            /public/bnuBalance01,
            target: BNU.StorageVaultPath
        )
    }

    let vault <- proxy.withdraw(amount: amount);
    let mainBNUVault = signer.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)!;
    mainBNUVault.deposit(from: <- vault);
  }
}