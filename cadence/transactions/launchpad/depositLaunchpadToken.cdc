import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import BNU from "../../contracts/BNU.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"

transaction(padId: Int, amount: UFix64) {
  let launchpad: &ByteNextLaunchpad.Launchpad;
  let launchpadVault: @FungibleToken.Vault;

  prepare(signer: AuthAccount) {
    self.launchpad = signer.borrow<&ByteNextLaunchpad.Launchpad>(from: ByteNextLaunchpad.LaunchpadStoragePath)
          ?? panic("Could not borrow launchpad from address");

    let tokenVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow Loka vault from account storage")
    self.launchpadVault <- tokenVault.withdraw(amount: amount)
  }

  execute {
    self.launchpad.depositLaunchpadToken(id: padId, newVault: <- self.launchpadVault)
  }
}