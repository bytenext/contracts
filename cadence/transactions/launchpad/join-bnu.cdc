
import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import BNU from "../../contracts/BNU.cdc";
import FlowToken from "../../contracts/FlowToken.cdc"

transaction(padAddress: Address, id: Int, amount: UFix64) {
  let paymentVault: @FungibleToken.Vault
  let launchpad: &ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}
  let tokenReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

  prepare(account: AuthAccount) {
    self.launchpad = getAccount(padAddress)
      .getCapability<&ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}>(
        ByteNextLaunchpad.LaunchpadPublicPath
      ).borrow() 
      ?? panic("Could not borrow launchpad from address");

    // let info = self.launchpad.getLaunchpadInfo(id: id) ?? panic("123");    
    // info._endTime = 1.0;


      if account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil {
         // Create a new Loka Vault and put it in storage
         account.save(<-FlowToken.createEmptyVault(), to: /storage/flowTokenVault)
      }

      account.unlink(/public/flowTokenReceiver);
      account.unlink(/public/flowTokenBalance);

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      account.link<&FlowToken.Vault{FungibleToken.Receiver}>(
          /public/flowTokenReceiver,
          target: /storage/flowTokenVault 
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      account.link<&FlowToken.Vault{FungibleToken.Balance}>(
          /public/flowTokenBalance,
          target: /storage/flowTokenVault 
      )

    self.tokenReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver);

    // Withdraw FUSD to contract
    let mainBNUVault = account.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
            ?? panic("Cannot borrow BNU vault from account storage")
    self.paymentVault <- mainBNUVault.withdraw(amount: amount)
  }

  execute {
    self.launchpad.join(id: id, paymentVault: <- self.paymentVault, tokenReceiver: self.tokenReceiver)
  }
} 