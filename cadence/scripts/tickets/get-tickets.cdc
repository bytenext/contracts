import Tickets from "../../contracts/mu/Tickets.cdc"
import Ticket from "../../contracts/mu/Ticket.cdc"

pub fun main(address: Address): {String: UInt64} {
    let one = Tickets.getTickets(owner: address, level: Ticket.Level.One)
    let two = Tickets.getTickets(owner: address, level: Ticket.Level.Two)
    let three = Tickets.getTickets(owner: address, level: Ticket.Level.Three)
    
    return {
      "one": one,
      "two": two,
      "three": three
    }
}