
import ByteNextStaking from "../../contracts/ByteNextStaking.cdc";

pub fun main(): {String: UFix64} {
  return ByteNextStaking.getBalances();
}
 