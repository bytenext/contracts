
import ByteNextStaking from "../../contracts/ByteNextStaking.cdc";
import BNU from "../../contracts/BNU.cdc";
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction(receiver: Address, amount: UFix64) {
  prepare(signer: AuthAccount) {
    let admin = signer.borrow<&ByteNextStaking.Administrator>(from: ByteNextStaking.AdminStoragePath)
              ?? panic("You are not admin")

    let tokenReceiver = getAccount(receiver).getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath).borrow()
        ?? panic("Could not borrow launchpad BNU");

    let vault <- admin.withdrawRewardPool(amount: amount)
    tokenReceiver.deposit(from: <- vault)
  }
}