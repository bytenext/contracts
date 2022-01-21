import FungibleToken from "./FungibleToken.cdc"

pub contract ByteNextOrderBook {
  access(self) let pairs: @{String: Pair}
  pub var totalPairs: UInt64

  pub enum OrderType: UInt8 {
    pub case Buy
    pub case Sell
  }

  pub enum OrderStatus: UInt8 {
    pub case Open
    pub case Filled
    pub case Cancelled
  }

  pub event OrderCreated(owner: Address, pairId: String, orderId: UInt64, type: UInt8, price: UFix64, qty: UFix64, fee: UFix64)
  pub event OrderCancelled(pairId: String, orderId: UInt64, type: UInt8)
  pub event PairCreated(pairId: String, token0: Type, token1: Type, minPrice: UFix64, maxPrice: UFix64)
  pub event OrderFilled(pairId: String, buyer: Address, buyOrderId: UInt64,  totalBuyFilled: UFix64, buyerFee: UFix64,
              price: UFix64, fillQty: UFix64, orderType: UInt8, tradeId: UInt64,
              seller: Address, sellOrderId: UInt64, totalSellFilled: UFix64, sellerFee: UFix64)

  pub struct Order {
    pub let orderId: UInt64
    pub let owner: Address
    pub let price: UFix64
    pub let qty: UFix64
    pub let time: UFix64
    pub let feePercent: UInt64
    pub let receiver: Capability<&{FungibleToken.Receiver}>
    pub var filledQty: UFix64
    pub var index: UInt64


    access(contract) fun setIndex(_ index: UInt64) {
      self.index = index
    }

    access(contract) fun setFilledQty(filledQty: UFix64) {
      self.filledQty = filledQty
    }

    init(
      orderId: UInt64,
      owner: Address,
      price: UFix64,
      qty: UFix64,
      filledQty: UFix64,
      time: UFix64,
      fee: UInt64,
      receiver: Capability<&{FungibleToken.Receiver}>
    ) {
      self.orderId = orderId
      self.owner = owner
      self.price = price
      self.qty = qty
      self.filledQty = filledQty
      self.time = time
      self.feePercent = fee

      self.receiver = receiver
      self.index = 0
    }
  }

  pub struct PairDetails {
    pub var isFrozen: Bool
    pub let minPrice: UFix64
    pub let maxPrice: UFix64
    pub let feePercent: UInt64

    init(isFrozen: Bool, minPrice: UFix64, maxPrice: UFix64, feePercent: UInt64) {
      self.isFrozen = isFrozen
      self.maxPrice = maxPrice
      self.minPrice = minPrice
      self.feePercent = feePercent
    }
  }
  
  pub resource interface PairPublic {
    pub fun getDetails(): PairDetails
    pub fun getSortedSellOrders(): [UInt64]
    pub fun getSortedBuyOrders(): [UInt64]
    pub fun getOpenSellOrdersForPrice(price: UFix64, qty: UFix64): [Order]
    pub fun getOpenBuyOrdersForPrice(price: UFix64, qty: UFix64): [Order]
    pub fun getOrder(orderId: UInt64, type: OrderType): Order?
  }

  pub resource Pair: PairPublic {
    pub let id: String
    pub var isFrozen: Bool
    pub let minPrice: UFix64
    pub let maxPrice: UFix64

    access(contract) let token0Vault: @FungibleToken.Vault
    access(contract) let token1Vault: @FungibleToken.Vault

    access(self) var totalOrder: UInt64
    access(self) var tradeId: UInt64

    access(self) let buyOrders: {UInt64: Order}
    access(self) let sellOrders: {UInt64: Order}

    // Sorted (desc) by order price
    access(self) let sortedBuyOrders: [UInt64] 
    // Sorted (asc) by order price
    access(self) let sortedSellOrders: [UInt64]

    access(self) var token0FeeReceiver: Capability<&{FungibleToken.Receiver}>
    access(self) var token1FeeReceiver: Capability<&{FungibleToken.Receiver}>
    access(self) var feePercent: UInt64


    init(
      id: String, isFrozen: Bool, minPrice: UFix64, maxPrice: UFix64,
      token0Vault: @FungibleToken.Vault, token1Vault: @FungibleToken.Vault,
      token0FeeReceiver: Capability<&{FungibleToken.Receiver}>, token1FeeReceiver: Capability<&{FungibleToken.Receiver}>,
      feePercent: UInt64
      ) {
      self.id = id
      self.isFrozen = isFrozen
      self.minPrice = minPrice
      self.maxPrice = maxPrice

      self.totalOrder = 0
      self.buyOrders = {}
      self.sortedBuyOrders = []
      self.sellOrders = {}
      self.sortedSellOrders = []

      self.token0Vault <- token0Vault
      self.token1Vault <- token1Vault
      self.feePercent = feePercent

      self.token0FeeReceiver = token0FeeReceiver
      self.token1FeeReceiver = token1FeeReceiver
      self.tradeId = 0
    }

    destroy() {
      destroy self.token0Vault
      destroy self.token1Vault
    }

    access(self) fun isValidPrice(price: UFix64): Bool {
      return  self.minPrice <= price && self.maxPrice >= price
    }

    /**
      * Example: BNU_FUSD, use FUSD to buy BNU
     */
    access(contract) fun buy(buyer: Address, vault: @FungibleToken.Vault, price: UFix64, receiver: Capability<&{FungibleToken.Receiver}>): @FungibleToken.Vault? {
      pre {
        !self.isFrozen: "Pair is frozen"
        price > 0.0: "Input invalid"
        self.isValidPrice(price: price): "Out of price range"
      }

      self.totalOrder = self.totalOrder + 1
      let orderId = self.totalOrder
      let vaultBalance = vault.balance
      let token0Qty = vault.balance / price

      emit OrderCreated(owner: buyer, pairId: self.id, orderId: orderId,
          type: OrderType.Buy.rawValue, price: price, qty: token0Qty, fee: 0.0)

      self.token1Vault.deposit(from: <- vault) 

      let sellOrders = self.getOpenSellOrdersForPrice(price: price, qty: token0Qty)

      var matchedQty = 0.0

      var totalPaidAmount = 0.0;

      if sellOrders.length > 0 {
        var needToMatchQty = token0Qty;
        var deleted = 0 as UInt64

        for sellOrder in sellOrders {

          let availableQty = sellOrder.qty - sellOrder.filledQty  
          var currentFilledQuantity = 0.0

          if needToMatchQty < availableQty {
            matchedQty = needToMatchQty

            //Increase filled quantity
            sellOrder.setFilledQty(filledQty: sellOrder.filledQty + needToMatchQty)
            self.sellOrders[sellOrder.orderId] = sellOrder

            currentFilledQuantity = needToMatchQty
            needToMatchQty = 0.0
          } else {
            matchedQty = matchedQty + availableQty
            needToMatchQty = needToMatchQty - availableQty
            currentFilledQuantity = availableQty

            // All qty of order filled
            sellOrder.setFilledQty(filledQty: sellOrder.qty)

            self.sellOrders.remove(key: sellOrder.orderId)
            self.sortedSellOrders.remove(at: sellOrder.index - deleted)
            deleted = deleted + 1
          }

          // Increase paid amount
          totalPaidAmount = totalPaidAmount + currentFilledQuantity * sellOrder.price

          // Fee of buyer (pay in token0)
          let buyerFee = UFix64(currentFilledQuantity) * UFix64(self.feePercent) / 10_000.0
          self.token0FeeReceiver.borrow()!.deposit(from: <- self.token0Vault.withdraw(amount: buyerFee))

          // Send token0 to buyer
          receiver.borrow()!.deposit(from: <- self.token0Vault.withdraw(amount: currentFilledQuantity - buyerFee))


          // Fee of seller (pay in token1)
          let sellerFee = UFix64(currentFilledQuantity) * sellOrder.price * UFix64(sellOrder.feePercent) / 10_000.0
          self.token1FeeReceiver.borrow()!.deposit(from: <- self.token1Vault.withdraw(amount: sellerFee))

          // Paid token1 to seller
          sellOrder.receiver.borrow()!.deposit(from: <- self.token1Vault.withdraw(amount: currentFilledQuantity * sellOrder.price - sellerFee))

          // Emit
          self.tradeId = self.tradeId + 1
          emit OrderFilled(pairId: self.id, buyer: buyer, buyOrderId: self.totalOrder, totalBuyFilled: matchedQty, buyerFee: buyerFee,
           price: sellOrder.price, fillQty: currentFilledQuantity, orderType: OrderType.Buy.rawValue, tradeId: self.tradeId,
           seller: sellOrder.owner, sellOrderId: sellOrder.orderId, totalSellFilled: sellOrder.filledQty, sellerFee: sellerFee)

          if needToMatchQty == 0.0 {
            break
          }

        }
      }

      // Paidback token1 to buyer if has any sell order matched with lower price
      let willUseAmount = totalPaidAmount + (token0Qty - matchedQty) * price
      assert(totalPaidAmount <= vaultBalance, message: "make sure used token1 always less than provided vault balance")

      var returnVault: @FungibleToken.Vault? <- nil
      if willUseAmount < vaultBalance {
        returnVault <-! self.token1Vault.withdraw(amount: vaultBalance - willUseAmount)
      }

      if matchedQty != token0Qty {
        let order = Order(
            orderId: orderId,
            owner: buyer,
            price: price,
            qty: token0Qty,
            filledQty: matchedQty,
            time: getCurrentBlock().timestamp,
            fee: self.feePercent,
            receiver: receiver
          )
        self.sortedBuyOrders.insert(at: self.sortedLastBuyIndex(order: order), order.orderId)
        self.buyOrders.insert(
          key: order.orderId,
          order
        )  
      }

      return <- returnVault
    }

    access(contract) fun sell(seller: Address, vault: @FungibleToken.Vault, price: UFix64, receiver: Capability<&{FungibleToken.Receiver}>) {
      pre {
        !self.isFrozen: "Pair is frozen"
        price > 0.0: "Input invalid"
        self.isValidPrice(price: price): "Out of price range"
      }

      let token0Qty = vault.balance;
      self.totalOrder = self.totalOrder + 1
      let orderId = self.totalOrder

      emit OrderCreated(owner: seller, pairId: self.id, orderId: orderId,
          type: OrderType.Sell.rawValue, price: price, qty: token0Qty, fee: 0.0)

      self.token0Vault.deposit(from: <- vault)

      let buyOrders = self.getOpenBuyOrdersForPrice(price: price, qty: token0Qty)

      var matchedQty = 0.0
      if buyOrders.length > 0 {
        var needToMatchQty = token0Qty;
        var deleted = 0 as UInt64

        for buyOrder in buyOrders {

          let orderQtyRemaining = buyOrder.qty - buyOrder.filledQty  
          var currentFilledQuantity = 0.0

          if needToMatchQty < orderQtyRemaining {
            matchedQty = needToMatchQty

            //Increase filled quantity
            buyOrder.setFilledQty(filledQty: buyOrder.filledQty + needToMatchQty)
            self.buyOrders[buyOrder.orderId] = buyOrder

            currentFilledQuantity = needToMatchQty
            needToMatchQty = 0.0
          } else {
            matchedQty = matchedQty + orderQtyRemaining
            needToMatchQty = needToMatchQty - orderQtyRemaining
            currentFilledQuantity = orderQtyRemaining

            // All qty of order filled
            buyOrder.setFilledQty(filledQty: buyOrder.qty)
            self.buyOrders.remove(key: buyOrder.orderId)
            self.sortedBuyOrders.remove(at: buyOrder.index - deleted)
            deleted = deleted + 1
          }


          // Fee of seller (pay in token0)
          let buyerFee = UFix64(currentFilledQuantity) * UFix64(buyOrder.feePercent) / 10_000.0
          self.token0FeeReceiver.borrow()!.deposit(from: <- self.token0Vault.withdraw(amount: buyerFee))

          // Send token0 to buyer
          buyOrder.receiver.borrow()!.deposit(from: <- self.token0Vault.withdraw(amount: UFix64(currentFilledQuantity) - buyerFee))


          // Fee of buyer (pay in token1)
          let sellerFee = UFix64(currentFilledQuantity) * buyOrder.price * UFix64(buyOrder.feePercent) / 10_000.0
          self.token1FeeReceiver.borrow()!.deposit(from: <- self.token1Vault.withdraw(amount: sellerFee))

          // Paid token1 to seller
          receiver.borrow()!.deposit(from: <- self.token1Vault.withdraw(amount: UFix64(currentFilledQuantity) * buyOrder.price - sellerFee))

          // Emit
          self.tradeId = self.tradeId + 1
          emit OrderFilled(pairId: self.id, buyer: buyOrder.owner, buyOrderId: buyOrder.orderId, totalBuyFilled: buyOrder.filledQty, buyerFee: buyerFee,
           price: buyOrder.price, fillQty: currentFilledQuantity, orderType: OrderType.Buy.rawValue, tradeId: self.tradeId,
           seller: seller, sellOrderId: self.totalOrder, totalSellFilled: matchedQty, sellerFee: sellerFee)

          if needToMatchQty == 0.0 {
            break
          }

        }
      }


      if matchedQty != token0Qty {
        let order = Order(
            orderId: orderId,
            owner: seller,
            price: price,
            qty: token0Qty,
            filledQty: matchedQty,
            time: getCurrentBlock().timestamp,
            fee: self.feePercent,
            receiver: receiver
          )

        self.sortedSellOrders.insert(at: self.sortedLastSellIndex(order: order), order.orderId)
        self.sellOrders.insert(
          key: order.orderId,
          order
        )  
      }

    }

    access(contract) fun cancel(sender: Address, orderId: UInt64, type: OrderType): @FungibleToken.Vault {
      if type == OrderType.Sell {
        if let order = self.sellOrders[orderId] {
          assert(order.owner == sender, message: "Forbidden")

          // Send token back
          let remainningVault <- self.token0Vault.withdraw(amount: UFix64(order.qty - order.filledQty))

          // Find index to delete
          let lastIndexSamePrice: UInt64 = self.sortedLastSellIndex(order: order) - 1
          var index = lastIndexSamePrice;
          while self.sellOrders[self.sortedSellOrders[index]]!.orderId != orderId {
            index = index - 1
          }

          // Delete from order list
          self.sellOrders.remove(key: order.orderId)
          assert(self.sellOrders[order.orderId] == nil, message: "Should be deleted")

          self.sortedSellOrders.remove(at: index)

          emit OrderCancelled(pairId: self.id, orderId: order.orderId, type: OrderType.Sell.rawValue)

          return <- remainningVault
        }
      }

      if type == OrderType.Buy {
        if let order = self.buyOrders[orderId] {
          assert(order.owner == sender, message: "Forbidden")

          // Send token back
          let remainningVault <- self.token1Vault.withdraw(amount: UFix64(order.qty - order.filledQty) * order.price )

          // Find index to delete
          let lastIndexSamePrice: UInt64 = self.sortedLastBuyIndex(order: order) - 1
          var index = lastIndexSamePrice;
          while self.buyOrders[self.sortedBuyOrders[index]]!.orderId != orderId {
            index = index - 1
          }

          // Delete from order list
          self.buyOrders.remove(key: order.orderId)
          assert(self.buyOrders[order.orderId] == nil, message: "Should be deleted")

          self.sortedBuyOrders.remove(at: index)

          emit OrderCancelled(pairId: self.id, orderId: order.orderId, type: OrderType.Buy.rawValue)

          return <- remainningVault
        }
      }

      panic("Order not found")
    }

    // Binary search in asc array
    access(self) fun sortedLastSellIndex(order: Order): UInt64 {
      var low: UInt64 = 0;
      var high = UInt64(self.sortedSellOrders.length)

      while low < high {
        var mid = (low + high) >> 1
        let orderId = self.sortedSellOrders[mid]

        if self.sellOrders.containsKey(orderId) && self.sellOrders[orderId]!.price <= order.price {
          low = mid + 1
        } else {
          high = mid
        }
      }

      return low
    }

    // Binary search in desc
    access(self) fun sortedLastBuyIndex(order: Order): UInt64 {
      var low: UInt64 = 0;
      var high = UInt64(self.sortedBuyOrders.length)

      while low < high {
        var mid = (low + high) >> 1
        let orderId = self.sortedBuyOrders[mid]

        if self.buyOrders.containsKey(orderId) && self.buyOrders[orderId]!.price >= order.price {
          low = mid + 1
        } else {
          high = mid
        }
      }

      return low
    }

    access(contract) fun setFee(feePercent: UInt64) {
      self.feePercent = feePercent 
    }

    access(contract) fun setFeeReceiver(
      token0Receiver: Capability<&{FungibleToken.Receiver}>,
      token1Receiver: Capability<&{FungibleToken.Receiver}>,
    ) {
      self.token0FeeReceiver = token0Receiver
      self.token1FeeReceiver = token1Receiver
    }

    access(contract) fun setFrozen(isFrozen: Bool) {
      self.isFrozen = isFrozen
    }


    /**
      * Get selling orders that can be filled with `price` of `token1`
    */
    pub fun getOpenSellOrdersForPrice(price: UFix64, qty: UFix64): [Order] {
      if self.sellOrders.length == 0 {
        return []
      }

      let orders: [Order] = []
      var filled: UFix64 = 0.0

      // Search for order which price asc, it mean order with lower price will be select first
      var index =  0 as UInt64
      for orderId in self.sortedSellOrders {
        let order = self.sellOrders[orderId]!;
        if order.price <= price {
          order.setIndex(index)
          orders.append(order)

          filled = filled + order.qty - order.filledQty

          // Stop find
          if filled >= qty {
            break
          }
        }

        index = index + 1
      }
      
      return orders
    }

    pub fun getOpenBuyOrdersForPrice(price: UFix64, qty: UFix64): [Order] {
      if self.buyOrders.length == 0 {
        return []
      }

      let orders: [Order] = []
      var filled = 0.0
      var index =  0 as UInt64

      // Search for order which price desc, it mean order with higher price will be select first
      for orderId in self.sortedBuyOrders {
        let order = self.buyOrders[orderId]!
        if order.price >= price {
          order.setIndex(index)
          orders.append(order)
          filled = filled + order.qty - order.filledQty

          // Stop find
          if filled >= qty {
            break
          }
        }

        index = index + 1
      }
      
      return orders
    }

    pub fun getDetails(): PairDetails {
      return PairDetails(isFrozen: self.isFrozen, minPrice: self.minPrice, maxPrice: self.maxPrice, feePercent: self.feePercent)
    }

    pub fun getSortedSellOrders(): [UInt64] {
      return self.sortedSellOrders
    }

    pub fun getSortedBuyOrders(): [UInt64] {
      return self.sortedBuyOrders
    }

    pub fun getOrder(orderId: UInt64, type: OrderType): Order? {
      switch type {
        case OrderType.Buy:
          return  self.buyOrders[orderId]
        case OrderType.Sell:
          return  self.sellOrders[orderId]
        default:
          return  nil
      }
    }

  }

  pub let AdminStoragePath: StoragePath
  pub let ProxyStoragePath: StoragePath

  pub resource ExchangeProxy {
    pub fun buy(pairId: String, vault: @FungibleToken.Vault, price: UFix64, receiver: Capability<&{FungibleToken.Receiver}>): @FungibleToken.Vault? { 
      pre {
        ByteNextOrderBook.pairs[pairId] != nil: "Pair not found"
        self.owner != nil: "Owner should not be nil"
      }

      let pair = &ByteNextOrderBook.pairs[pairId] as! &Pair
      return <- pair.buy(buyer: self.owner!.address, vault: <- vault, price: price, receiver: receiver)
    }


    pub fun sell(pairId: String, vault: @FungibleToken.Vault, price: UFix64, receiver: Capability<&{FungibleToken.Receiver}>) {
      pre {
        ByteNextOrderBook.pairs[pairId] != nil: "Pair not found"
        self.owner != nil: "Owner should not be nil"
      }

      let pair = &ByteNextOrderBook.pairs[pairId] as! &Pair
      pair.sell(seller: self.owner!.address, vault: <- vault, price: price, receiver: receiver)
    }

    pub fun cancel(pairId: String, orderId: UInt64, type: OrderType): @FungibleToken.Vault {
      pre {
        ByteNextOrderBook.pairs[pairId] != nil: "Pair not found"
        self.owner != nil: "Owner should not be nil"
      }

      let pair = &ByteNextOrderBook.pairs[pairId] as! &Pair
      return <- pair.cancel(sender: self.owner!.address, orderId: orderId, type: type)
    }

  }

  pub resource Administrator {
    pub fun createPair(
      id: String,isFrozen: Bool, minPrice: UFix64, maxPrice: UFix64,
      token0Vault: @FungibleToken.Vault, token1Vault: @FungibleToken.Vault, 
      token0FeeReceiver: Capability<&{FungibleToken.Receiver}>, token1FeeReceiver: Capability<&{FungibleToken.Receiver}>,
      feePercent: UInt64
    ) {
      pre {
        ByteNextOrderBook.pairs[id] == nil: "Pair already created"
      }

      ByteNextOrderBook.totalPairs = ByteNextOrderBook.totalPairs + 1
      let token0Type = token0Vault.getType()
      let token1Type = token1Vault.getType()

      let pair <- create Pair(id: id, isFrozen: isFrozen, minPrice: minPrice, maxPrice: maxPrice,
              token0Vault: <- token0Vault, token1Vault: <- token1Vault, 
              token0FeeReceiver: token0FeeReceiver, token1FeeReceiver: token1FeeReceiver, 
              feePercent: feePercent)

      let oldPair <- ByteNextOrderBook.pairs[id] <- pair
      destroy oldPair

      emit PairCreated(pairId: id, token0: token0Type, token1: token1Type,
              minPrice: minPrice, maxPrice: maxPrice)
    }

    pub fun setFee(pairId: String, feePercent: UInt64) {
      pre {
        ByteNextOrderBook.pairs[pairId] != nil: "Pair not found"
      } 

      let pair = &ByteNextOrderBook.pairs[pairId] as! &Pair
      pair.setFee(feePercent: feePercent)
    }

    pub fun setFeeReceiver(
      pairId: String, 
      token0Receiver: Capability<&{FungibleToken.Receiver}>,
      token1Receiver: Capability<&{FungibleToken.Receiver}>,
    ) {
      pre {
        ByteNextOrderBook.pairs[pairId] != nil: "Pair not found"
      } 

      let pair = &ByteNextOrderBook.pairs[pairId] as! &Pair
      pair.setFeeReceiver(token0Receiver: token0Receiver, token1Receiver: token1Receiver)
    }

    pub fun freeze(pairId: String) {
      pre {
        ByteNextOrderBook.pairs[pairId] != nil: "Pair not found"
      } 

      let pair = &ByteNextOrderBook.pairs[pairId] as! &Pair
      pair.setFrozen(isFrozen: true)
    }

    pub fun unfreeze(pairId: String) {
      pre {
        ByteNextOrderBook.pairs[pairId] != nil: "Pair not found"
      } 

      let pair = &ByteNextOrderBook.pairs[pairId] as! &Pair
      pair.setFrozen(isFrozen: false)
    }
  }

  pub fun createProxy(): @ExchangeProxy {
    return <- create ExchangeProxy()
  }

  //  Returns a read-only view of Pair for the given pairId if it is contained by this collection
  pub fun borrowPair(pairId: String): &Pair{PairPublic}? {
    if self.pairs[pairId] != nil {
        return &self.pairs[pairId] as! &Pair{PairPublic}
    } else {
        return nil
    }
  }

  init() {
    self.AdminStoragePath = /storage/ByteNextAdminPath02
    self.ProxyStoragePath = /storage/ByteNextOrderBookProxyPath02

    self.pairs <- {}
    self.totalPairs = 0

    self.account.save(<- create Administrator(), to: self.AdminStoragePath)
  }
}