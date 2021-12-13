import ByteNextStaking from "../../contracts/ByteNextStaking.cdc";
import BNU from "../../contracts/BNU.cdc";

transaction(amount: UFix64) {

  prepare(signer: AuthAccount) {
    let admin = signer.borrow<&ByteNextStaking.Administrator>(from: ByteNextStaking.AdminStoragePath)
              ?? panic("You are not admin")

    let mainBNUVault = signer.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
            ?? panic("Cannot borrow BNU vault from account storage")
    let bnu <- mainBNUVault.withdraw(amount: amount) as! @BNU.Vault

    admin.depositToRewardPool(vault: <- bnu)
  }
}