import ByteNextStaking from "../../contracts/ByteNextStaking.cdc";

pub fun main(): {String: AnyStruct} {
  return {
    "rewardPerBlock": ByteNextStaking.rewardPerBlock,
    "startBlock": ByteNextStaking.startBlock,
    "endBlock": ByteNextStaking.endBlock,
    "currentBlock": getCurrentBlock().height,
    "totalStaked": ByteNextStaking.totalStaked()
  }
}
 