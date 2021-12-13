
import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"

transaction(padAddress: Address, padId: Int, receiver: Address, amount: UFix64) {
  prepare(signer: AuthAccount) {
    let launchpad = signer.borrow<&ByteNextLaunchpad.Launchpad>(from: ByteNextLaunchpad.LaunchpadStoragePath)
          ?? panic("Could not borrow launchpad from address");

    let tokenReceiver = getAccount(receiver).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()
        ?? panic("Could not borrow launchpad BNU");

    let vault <- launchpad.withdrawLaunchpadToken(id: padId, amount: amount)
    tokenReceiver.deposit(from: <- vault)
  }
}