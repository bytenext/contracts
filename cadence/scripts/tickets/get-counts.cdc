import Ticket from "../../contracts/mu/Ticket.cdc"

pub fun main(owner: Address): {String: UInt64} {
    let collection = getAccount(owner).getCapability<&{Ticket.TicketCollectionPublic}>(Ticket.CollectionPublicPath)
              .borrow()

    if collection == nil {
        return {}
    }
    let tickets = collection!.getCounts()
    
    return {
      "one": tickets[Ticket.Level.One.rawValue] ?? 0,
      "two": tickets[Ticket.Level.Two.rawValue] ?? 0,
      "three": tickets[Ticket.Level.Three.rawValue] ?? 0
    }
}