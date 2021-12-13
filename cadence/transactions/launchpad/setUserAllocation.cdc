import FungibleToken from "../../contracts/FungibleToken.cdc"
import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc"
import BNU from "../../contracts/BNU.cdc"

transaction(id: Int, account: Address, allocation: UFix64) {
  prepare(signer: AuthAccount) {
      let launchpad = signer.borrow<&ByteNextLaunchpad.Launchpad>(from: ByteNextLaunchpad.LaunchpadStoragePath)
          ?? panic("Could not borrow launchpad from address");

      launchpad.setUserAllocation(id: id, account: account, allocation: allocation)
  }
}