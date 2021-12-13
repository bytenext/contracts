import BNU from "../../contracts/BNU.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

// This script returns an account's BNU balance.

pub fun main(address: Address): UFix64 {
    let account = getAccount(address)
    
    let vaultRef = account.getCapability(BNU.BalancePublicPath)!.borrow<&BNU.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}