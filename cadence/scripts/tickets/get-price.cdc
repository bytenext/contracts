
import Tickets from "../../contracts/mu/Tickets.cdc"

pub fun main(level: UInt8): UFix64 {
  return  Tickets.getTicketPrice(level: level)
}