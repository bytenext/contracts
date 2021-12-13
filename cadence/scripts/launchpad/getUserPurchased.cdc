
import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc";

pub fun main(padAddress: Address, padId: Int, userAddress: Address): {String: AnyStruct} {
  let launchpad = getAccount(padAddress)
    .getCapability<&ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}>(
      ByteNextLaunchpad.LaunchpadPublicPath
    ).borrow() 
    ?? panic("Could not borrow launchpad from address");

  let info = launchpad.getLaunchpadInfo(id: padId);

  if info != nil {
    let userBought = (info!._userBoughts[userAddress] ?? 0.0) ;
    return {
      "purchased": userBought / info!._tokenPrice,
      "tokenPaid": userBought,
      "price": info!._tokenPrice
    }
  }

  return  {};
}