import ByteNextLaunchpad from "../../contracts/ByteNextLaunchpad.cdc";

pub fun main(padAddress: Address, id: Int, userAddress: Address): {String: UFix64} {
  let launchpad = getAccount(padAddress)
    .getCapability<&ByteNextLaunchpad.Launchpad{ByteNextLaunchpad.LaunchpadPublic}>(
      ByteNextLaunchpad.LaunchpadPublicPath
    ).borrow() 
    ?? panic("Could not borrow launchpad from address");

  let launchpadInfo = launchpad.getLaunchpadInfo(id: id) ?? panic("Launchpad is invalid");
  let claimable = launchpad.getClaimable(id: id, userAddress);

  var startIndex = 0;
  var endIndex: Int = launchpadInfo._claimingCounts[userAddress] ?? 0;

  var claimed: UFix64 = 0.0;
  if(startIndex < endIndex){
    var index: Int = startIndex;

    let userBought: UFix64 = launchpadInfo._userBoughts[userAddress] ?? 0.0;
    while(index < endIndex){
        let claimingTime: UFix64 = launchpadInfo._claimingTimes[index];
        claimed = claimed + userBought * launchpadInfo._claimingPercents[index] / 100.0;
        index = index + 1;
    }
  }

  return {
    "claimable": claimable ,
    "claimed": claimed
  }
}