import FUSD from "../../contracts/FUSD.cdc"

// This script returns the total amount of FUSD currently in existence.

pub fun main(): UFix64 {

    let supply = FUSD.totalSupply

    log(supply)

    return supply
}