import BNU from "../../contracts/BNU.cdc"

// This script returns the total amount of BNU currently in existence.

pub fun main(): UFix64 {

    let supply = BNU.totalSupply

    log(supply)

    return supply
}