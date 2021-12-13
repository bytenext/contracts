import ByteNextStaking from "../../contracts/ByteNextStaking.cdc";
import BNU from "../../contracts/BNU.cdc"


transaction(amount: UFix64) {
  prepare(signer: AuthAccount) {
    if signer.borrow<&ByteNextStaking.StakingProxy>(from: ByteNextStaking.StakingProxyStoragePath) == nil {
        signer.save(<-ByteNextStaking.createStakingProxy(), to: ByteNextStaking.StakingProxyStoragePath)
    }

    let proxy = signer.borrow<&ByteNextStaking.StakingProxy>(from: ByteNextStaking.StakingProxyStoragePath)!;

    let mainBNUVault = signer.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
            ?? panic("Cannot borrow BNU vault from account storage")
    let vault <- mainBNUVault.withdraw(amount: amount) as! @BNU.Vault

    let reward <- proxy.deposit(vault: <- vault);
    if reward != nil {
      mainBNUVault.deposit(from: <- reward!)
    } else {
       destroy reward
    }
  }
}
