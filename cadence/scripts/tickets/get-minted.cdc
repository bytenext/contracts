import Tickets from "../../contracts/mu/Tickets.cdc"

pub fun main(id: UInt64, level: UInt8): UInt64 {
  return  Tickets.getMinted(id: id, level: level)
}