
import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc";

pub fun main(padAddress: Address, id: Int): UFix64 {
  let launchpad = getAccount(padAddress)
    .getCapability<&ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}>(
      ByteNextLaunchpad.LaunchpadPublicPath
    ).borrow() 
    ?? panic("Could not borrow launchpad from address");

  let info = launchpad.getLaunchpadInfo(id: id);

  if info != nil {
    return  info!._totalBought;
  }

  return 0.0;
}