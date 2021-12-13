
import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc";

pub fun main(padAddress: Address, padId: Int, userAddress: Address): {String: AnyStruct} {
  let launchpad = getAccount(padAddress)
    .getCapability<&ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}>(
      ByteNextLaunchpad.LaunchpadPublicPath
    ).borrow() 
    ?? panic("Could not borrow launchpad from address");

  let info = launchpad.getLaunchpadInfo(id: padId);

  if info != nil {
    let purchased = (info!._userBoughts[userAddress] ?? 0.0) ;
    return {
      "purchased": purchased,
      "tokenPaid": purchased * info!._tokenPrice,
      "price": info!._tokenPrice
    }
  }

  return  {};
}