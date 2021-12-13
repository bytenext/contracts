import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"


transaction(padAddress: Address, id: Int) {
  let launchpad: &ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}
  let tokenReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

  prepare(account: AuthAccount) {
    self.launchpad = getAccount(padAddress)
      .getCapability<&ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}>(
        ByteNextLaunchpad.LaunchpadPublicPath
      ).borrow() 
      ?? panic("Could not borrow launchpad from address");

      if account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil {
         // Create a new Loka Vault and put it in storage
         account.save(<-FlowToken.createEmptyVault(), to: /storage/flowTokenVault)


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
              target: /public/flowTokenVault
          )
      }

      

      self.tokenReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver);
  }

  execute {
    self.launchpad.claim(id: id, address: self.tokenReceiver.address)
  }
}
