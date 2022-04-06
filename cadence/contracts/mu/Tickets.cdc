import FlowToken from "../core/FlowToken.cdc"
import FungibleToken from "../core/FungibleToken.cdc"
import NonFungibleToken from "../core/NonFungibleToken.cdc"
import Whitelist from "./Whitelist.cdc"
import VnMiss from "./VnMiss.cdc"
import VnMissCandidate from "./VnMissCandidate.cdc"
import Ticket from "./Ticket.cdc"

pub contract Tickets {
    access(contract) let ticketPrices: {Ticket.Level: UFix64}
    access(contract) let maxTickets: {Ticket.Level: UInt64}
    access(contract) let boughtTickets: {Ticket.Level: UInt64}
    access(contract) var saleCuts: [SaleCut]

    access(self) let candidateDept: { UInt64: UFix64 }
    access(self) var minted: {UInt64: { Ticket.Level: UInt64 }}
    access(self) let candidateFund: @FungibleToken.Vault

    pub var candidateFundRate: UFix64

    pub let discountRate: UFix64
    pub var whitelistStartAt: UFix64
    pub var whitelistEndAt: UFix64
    pub var ticketStartAt: UFix64
    pub var ticketEndAt: UFix64

    pub let AdminStoragePath: StoragePath
    pub let FlowReceiverPath: PublicPath
    pub let ProxyPath: StoragePath

    pub struct PaymentCut {
        pub let recipient: Address

        // Can be the percentage of the cut, or amount of FungibleToken
        pub let rateOrAmount: UFix64

        init(recipient: Address, rateOrAmount: UFix64) {
            self.recipient = recipient
            self.rateOrAmount = rateOrAmount
        }
    }

    pub struct SaleCut {
        pub let recipient: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
        pub let rate: UFix64

        init(recipient: Capability<&FlowToken.Vault{FungibleToken.Receiver}>, rate: UFix64) {
            self.recipient = recipient
            self.rate = rate
        }
    }

    pub event PriceChange(level: UInt8, price: UFix64)
    pub event MaxQtyChange(level: UInt8, qty: UInt64)
    pub event PaymentCutChanged(cuts: [PaymentCut])
    pub event Payout(cuts: [PaymentCut])
    pub event TicketBought(level: UInt8, buyer: Address, qty: UInt64, discount: UFix64)
    pub event WhitelistTimeChange(startAt: UFix64, endAt: UFix64)
    pub event TimeChange(startAt: UFix64, endAt: UFix64)
    pub event SwapForNFT(ticketID: UInt64, level: UInt8, candidateID: UInt64)

    pub resource Admin {
        pub fun setPrice(level: UInt8, price: UFix64) {
            Tickets.ticketPrices[Ticket.Level(level)!] = price

            emit PriceChange(level: level, price: price)
        }

        pub fun setMaxTickets(level: UInt8, qty: UInt64) {
            Tickets.maxTickets[Ticket.Level(level)!] = qty

            emit MaxQtyChange(level: level, qty: qty)
        }

        pub fun setPaymentCut(cuts: [PaymentCut]) {
            var rate = 0.0
            let saleCuts: [SaleCut] = []
            for cut in cuts {
                rate = rate + cut.rateOrAmount

                let cap = getAccount(cut.recipient)
                    .getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(Tickets.FlowReceiverPath)
                
                cap.borrow()
                    ?? panic("Missing or mis-typed flow token receiver of ".concat(cut.recipient.toString()))
                saleCuts.append(SaleCut(recipient: cap, rate: cut.rateOrAmount))
            }

            assert(rate < 1.0, message: "The total rate of cuts should be 1.0")
            Tickets.candidateFundRate = 1.0 - rate

            Tickets.saleCuts = saleCuts

            emit PaymentCutChanged(cuts: cuts)
        }

        pub fun setWhitelistTime(startAt: UFix64, endAt: UFix64) {
            Tickets.whitelistStartAt = startAt
            Tickets.whitelistEndAt = endAt

            emit WhitelistTimeChange(startAt: startAt, endAt: endAt)
        }

        pub fun setTime(startAt: UFix64, endAt: UFix64) {
            Tickets.ticketStartAt = startAt
            Tickets.ticketEndAt = endAt

            emit TimeChange(startAt: startAt, endAt: endAt)
        }

        pub fun withdrawCandidateFunds(amount: UFix64): @FungibleToken.Vault {
            return <- Tickets.candidateFund.withdraw(amount: amount)
        }
    }

    pub fun buyTickets(
        recipient: Capability<&{NonFungibleToken.CollectionPublic}>,
        level: UInt8,
        qty: UInt64,
        payment: @FungibleToken.Vault
    ) {
        let now = getCurrentBlock().timestamp
        assert(Tickets.ticketStartAt <= now && Tickets.ticketEndAt >= now, message: "Not open")

        Tickets.buy(recipient: recipient, level: Ticket.Level(level)!, qty: qty, payment: <- payment, discountRate: 0.0)
    }

    pub fun buyWhitelist(
        recipient: Capability<&{NonFungibleToken.CollectionPublic}>,
        payment: @FungibleToken.Vault
    ) {
        let now = getCurrentBlock().timestamp
        assert(Tickets.whitelistStartAt <= now && Tickets.whitelistEndAt >= now, message: "Not open")

        let buyer = recipient.address
        assert(Whitelist.hasBought(address: buyer) == false, message: "Only buy 1 ticket discount")

        let price = Tickets.ticketPrices[Ticket.Level.One]!
        if Whitelist.whitelisted(address: buyer) == false {
            panic("You are not whitelisted")
        }

        self.buy(recipient: recipient, level: Ticket.Level.One, qty: 1, payment: <- payment, discountRate: self.discountRate)
        Whitelist.markAsBought(address: buyer)
    }
    
    access(self) fun payout(payment: @FungibleToken.Vault) {
        var residualReceiver: &{FungibleToken.Receiver}? = nil
        let total = payment.balance
        let payouts: [PaymentCut] = []

        self.candidateFund.deposit(from: <- payment.withdraw(amount: self.candidateFundRate * total))
        payouts.append(PaymentCut(recipient: self.account.address, rateOrAmount: self.candidateFundRate * total))

        for cut in self.saleCuts {
            if let receiver = cut.recipient.borrow() {
                let amount = cut.rate * total
                let paymentCut <- payment.withdraw(amount: amount)
                receiver.deposit(from: <-paymentCut)

                payouts.append(PaymentCut(recipient: cut.recipient.address, rateOrAmount: amount))

                if (residualReceiver == nil) {
                    residualReceiver = receiver
                }
            }
        }

        assert(residualReceiver != nil, message: "No valid payment receivers")

        // At this point, if all recievers were active and availabile, then the payment Vault will have
        // zero tokens left, and this will functionally be a no-op that consumes the empty vault

        if payment.balance > 0.0 {
            payouts.append(PaymentCut(recipient: residualReceiver?.owner?.address!, rateOrAmount: payment.balance))
        }

        residualReceiver!.deposit(from: <-payment)

        emit Payout(cuts: payouts)
    }

    access(self) fun mintTicket(
        recipient: Capability<&{NonFungibleToken.CollectionPublic}>,
        issuePrice: UFix64,
        level: Ticket.Level,
        qty: UInt64
    ) {
        var i = 0 as UInt64

        let minter = self.account.borrow<&Ticket.NFTMinter>(from: Ticket.MinterStoragePath)!
        let receiver = recipient.borrow() ?? panic("Collection ticket broken")
        while i < qty {
            i = i + 1
            minter.mintNFT(recipient: receiver, issuePrice: issuePrice, level: level)
        }
    }

    access(self) fun buy(
        recipient: Capability<&{NonFungibleToken.CollectionPublic}>,
        level: Ticket.Level,
        qty: UInt64,
        payment: @FungibleToken.Vault,
        discountRate: UFix64
    ) {
        pre {
            payment.isInstance(Type<@FlowToken.Vault>()): "Should use Flow as payment"
            level.rawValue < Ticket.Level.Three.rawValue: "Can not bought level 3. Use auction"
            qty > 0 && qty < 30: "Qty should be > 0 adn <= 30"
            (self.boughtTickets[level] ?? 0) + qty <= (self.maxTickets[level] ?? 0):
                "Sold out ticket for this level"
        }

        let price = self.ticketPrices[level]! - self.ticketPrices[level]! * discountRate
        assert(price * UFix64(qty) == payment.balance, message: "Insufficient funds")

        self.payout(payment: <-payment)
        self.mintTicket(recipient: recipient, issuePrice: price, level: level, qty: qty)

        emit TicketBought(level: level.rawValue, buyer: recipient.address, qty: qty, discount: discountRate)
    }

    access(account) fun payAndRewardDiamond(
        recipient: Capability<&{NonFungibleToken.CollectionPublic}>,
        payment: @FungibleToken.Vault
    ) {
        pre {
            (self.boughtTickets[Ticket.Level.Three] ?? 0) + 1 <= (self.maxTickets[Ticket.Level.Three] ?? 0):
                "Sold out ticket for this level"
        }

        let issuePrice = payment.balance

        self.payout(payment: <- payment)
        self.mintTicket(recipient: recipient, issuePrice: issuePrice, level: Ticket.Level.Three, qty: 1)

        emit TicketBought(level: Ticket.Level.Three.rawValue, buyer: recipient.address, qty: 1, discount: 0.0)
    }

    access(self) fun mapToVnMissTicketLevel(level: Ticket.Level): VnMiss.Level {
        switch level {
            case Ticket.Level.One:
                return VnMiss.Level.Bronze

            case Ticket.Level.Two:
                return VnMiss.Level.Silver

            case Ticket.Level.Three:
                return VnMiss.Level.Diamond
        }

        panic("Ticket.Level case miss")
    }

    access(self) fun fundForCandidate(c: VnMissCandidate.Candidate, issuePrice: UFix64) {
        let recipient = getAccount(c.fundAdress)
                            .getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(Tickets.FlowReceiverPath)
                            .borrow()
        let amount = self.candidateFundRate * issuePrice
        if let recipient = recipient {
            recipient.deposit(from: <- self.candidateFund.withdraw(amount: amount))
            return
        }

        self.candidateDept[c.id] = self.candidateDept[c.id] ?? 0.0 + amount
    }

    access(self) fun canMint(candidateID: UInt64, level: Ticket.Level): Bool {
        let minted = self.minted[candidateID]![level] ?? 0

        switch level {
            case Ticket.Level.One:
                return minted < 195

            case Ticket.Level.Two:
                return minted < 4

            case Ticket.Level.One:
                return minted < 1
        }

        return  false
    }

    pub fun levelAsString(level: Ticket.Level): String {
        switch level {
            case Ticket.Level.One:
                return "Bronze"

            case Ticket.Level.Two:
                return "Silver"

            case Ticket.Level.Three:
                return "Diamond"
        }

        return  ""
    }


    pub fun swapForNFT(ticket: @Ticket.NFT, candidateID: UInt64, recipient: &{NonFungibleToken.CollectionPublic}) {
        let c = VnMissCandidate.getCandidate(id: candidateID) 
                    ?? panic("Candidate not exist")

        self.minted[candidateID] = self.minted[candidateID] ?? {}

        let level = ticket.level
        let ticketID = ticket.id

        assert(self.canMint(candidateID: candidateID, level: level), message: "Slot of this level are full")

        let minted = self.minted[candidateID]!
        minted[level] = minted[level] ?? 0 + 1
        self.minted[candidateID] = minted

        let minter = self.account.borrow<&VnMiss.NFTMinter>(from: VnMiss.MinterStoragePath)
                            ?? panic("Can not borrow")

        self.fundForCandidate(c: c, issuePrice: ticket.issuePrice) 
        let levelStr = self.levelAsString(level: level)

        let thumbnail = c.code.concat("/")
                            .concat(levelStr.toLower())
                            .concat("/")
                            .concat(minted[level]!.toString())
                                
        minter.mintNFT(
            recipient: recipient,
            candidateID: candidateID,
            level: self.mapToVnMissTicketLevel(level: level),
            name: c.buildName(level: levelStr, id: minted[level]!),
            thumbnail: thumbnail
        )

        destroy ticket
        emit SwapForNFT(ticketID: ticketID, level: level.rawValue, candidateID: candidateID)
    }

    pub fun getSaleCuts(): [SaleCut] {
        return self.saleCuts
    }

    pub fun getBoughtTickets(): {Ticket.Level: UInt64} {
        return self.boughtTickets
    }

    pub fun getMaxTickets() : {Ticket.Level: UInt64} {
        return self.maxTickets
    }

    pub fun getCandidateDept(id: UInt64): UFix64 {
        return self.candidateDept[id] ?? 0.0
    }

    init() {
        self.discountRate = 0.4
        self.candidateFundRate = 0.0

        self.whitelistStartAt = 1649054950.0
        self.whitelistEndAt = 1649055259.0
        self.ticketStartAt = 1649054950.0
        self.ticketEndAt = 1649055259.0

        self.ticketPrices = {
            Ticket.Level.One: 50.0,
            Ticket.Level.Two: 300.0,
            Ticket.Level.Three: 2000.0
        }

        self.maxTickets = {
            Ticket.Level.One: 13650,
            Ticket.Level.Two: 280,
            Ticket.Level.Three: 70 
        }

        self.boughtTickets = {}
        self.candidateDept = {}

        self.saleCuts = []

        self.AdminStoragePath = /storage/BNMUTicketsAdmin
        self.FlowReceiverPath = /public/flowTokenReceiver
        self.ProxyPath = /storage/BNMUTicketsProxy

        self.minted = {}
        self.candidateFund <- FlowToken.createEmptyVault()


        self.account.save(<- create Admin(), to: self.AdminStoragePath)
    }
}