import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc";

pub fun main(padAddress: Address, id: Int, userAddress: Address): {String: AnyStruct} {
  let launchpad = getAccount(padAddress)
    .getCapability<&ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}>(
      ByteNextLaunchpad.LaunchpadPublicPath
    ).borrow() 
    ?? panic("Could not borrow launchpad from address");

  let launchpadInfo = launchpad.getLaunchpadInfo(id: id) ?? panic("Launchpad is invalid");
  let claimable = launchpad.getClaimable(id: id, userAddress);

  var endIndex: Int = launchpadInfo._claimingCounts[userAddress] ?? 0;
  let userBought: UFix64 = launchpadInfo._userBoughts[userAddress] ?? 0.0;
  var totalPercent = 0.0;

  var index: Int = 0;
  while(index < endIndex){
      totalPercent = launchpadInfo._claimingPercents[index];
      index = index + 1;
  }

  return {
    "claimable": claimable ,
    "claimed": totalPercent * userBought / launchpadInfo._tokenPrice / 100.0,
    "claimingTimes": launchpadInfo._claimingTimes,
    "claimingPercents": launchpadInfo._claimingPercents
  }
}