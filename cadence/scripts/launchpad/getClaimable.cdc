
import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc";

pub fun main(padAddress: Address, padId: Int, userAddress: Address): UFix64 {
  let launchpad = getAccount(padAddress)
    .getCapability<&ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}>(
      ByteNextLaunchpad.LaunchpadPublicPath
    ).borrow() 
    ?? panic("Could not borrow launchpad from address");

  return launchpad.getClaimable(id: padId, userAddress);
}