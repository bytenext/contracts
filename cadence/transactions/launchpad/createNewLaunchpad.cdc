
import FungibleToken from "../../contracts/FungibleToken.cdc"
import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import BNU from "../../contracts/BNU.cdc"

transaction(startTime: UFix64, endTime: UFix64, 
        tokenPrice: UFix64, receiverAddr: Address,
        claimingTimes: [UFix64], claimingPercents: [UFix64],
        totalRaise: UFix64) {
    
  prepare(signer: AuthAccount) {
      let launchpad = signer.borrow<&ByteNextLaunchpad.Launchpad>(from: ByteNextLaunchpad.LaunchpadStoragePath)
          ?? panic("Could not borrow launchpad from address");

      let tokenReceiver = getAccount(receiverAddr).getCapability<&BNU.Vault{FungibleToken.Receiver}>(/public/bnuReceiver01)
      if !tokenReceiver.check() {
        panic("Should setup your BNU Receiver")
      }

      launchpad.createNewLaunchpad(
        startTime: startTime, endTime: endTime,
        tokenPrice: tokenPrice, tokenType: Type<@FlowToken.Vault>(),
        paymentType: Type<@BNU.Vault>(), tokenReceiver: tokenReceiver,
        claimingTimes: claimingTimes, claimingPercents: claimingPercents,
        totalRaise: totalRaise
      )
  }
}