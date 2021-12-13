import ByteNextStaking from "../../contracts/ByteNextStaking.cdc";

pub fun main(address: Address): {String: AnyStruct} {
  return {
    "stakingAmount": ByteNextStaking.getStakingAmount(user: address),
    "pendingReward": ByteNextStaking.pendingRewards(user: address)
  }
}
 