import Tickets from "../../contracts/mu/Tickets.cdc"
import Ticket from "../../contracts/mu/Ticket.cdc"

pub fun main(): {String: UInt64} {
    let tickets = Tickets.getMaxTickets()
    
    return {
      "one": tickets[Ticket.Level.One] ?? 0,
      "two": tickets[Ticket.Level.Two] ?? 0,
      "three": tickets[Ticket.Level.Three] ?? 0
    }
}