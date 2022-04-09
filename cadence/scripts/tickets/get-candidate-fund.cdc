import Tickets from "../../contracts/mu/Tickets.cdc"

pub fun main(): UFix64 {
  return  Tickets.getCandidateFundBalance()
}