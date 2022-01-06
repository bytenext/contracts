import FungibleToken from "./FungibleToken.cdc"

pub contract ByteNextOrderBook {
  access(contract) let pairs: @{UInt64: Pair}
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

  pub event OrderCreated(pairId: UInt64, orderId: UInt64, type: UInt8, price: UFix64, qty: UInt64, fee: UFix64)
  pub event OrderCancelled(pairId: UInt64, orderId: UInt64, type: UInt8)
  pub event PairCreated(pairId: UInt64, paymentType: Type, sellingTokenType: Type, minPrice: UFix64, maxPrice: UFix64)
  pub event OrderFilled(pairId: UInt64, buyOrderId: UInt64, sellOrderId: UInt64, price: UFix64, fillQty: UInt64, orderType: UInt8)

  pub struct Order {
    pub let orderId: UInt64
    pub let owner: Address
    pub let price: UFix64
    pub let qty: UInt64
    pub let time: UFix64
    pub let feePercent: UInt64
    pub(set) var filledQty: UInt64
    pub let receiver: Capability<&{FungibleToken.Receiver}>
 
    pub(set) var index: UInt64

    init(
      orderId: UInt64,
      owner: Address,
      price: UFix64,
      qty: UInt64,
      time: UFix64,
      fee: UInt64,
      receiver: Capability<&{FungibleToken.Receiver}>
    ) {
      self.orderId = orderId
      self.owner = owner
      self.price = price
      self.qty = qty
      self.filledQty = 0
      self.time = time
      self.feePercent = fee

      self.receiver = receiver
      self.index = 0
    }
  }
  
  pub resource Pair {
    pub var isFrozen: Bool
    pub let minPrice: UFix64
    pub let maxPrice: UFix64

    access(contract) let paymentVault: @FungibleToken.Vault
    access(contract) let sellingVault: @FungibleToken.Vault

    access(self) var totalOrder: UInt64

    access(self) let buyOrders: {UInt64: Order}
    access(self) let sellOrders: {UInt64: Order}

    // Sorted (desc) by order price
    access(self) let sortedBuyOrders: [UInt64] 
    // Sorted (asc) by order price
    access(self) let sortedSellOrders: [UInt64]

    access(self) var sellingFeeReceiver: Capability<&{FungibleToken.Receiver}>
    access(self) var paymentFeeReceiver: Capability<&{FungibleToken.Receiver}>
    access(self) var feePercent: UInt64


    init(
      isFrozen: Bool, minPrice: UFix64, maxPrice: UFix64,
      paymentVault: @FungibleToken.Vault, sellingVault: @FungibleToken.Vault,
      paymentFeeReceiver: Capability<&{FungibleToken.Receiver}>,
      sellingFeeReceiver: Capability<&{FungibleToken.Receiver}>,
      feePercent: UInt64
      ) {
      self.isFrozen = isFrozen
      self.minPrice = minPrice
      self.maxPrice = maxPrice

      self.totalOrder = 0
      self.buyOrders = {}
      self.sortedBuyOrders = []
      self.sellOrders = {}
      self.sortedSellOrders = []

      self.paymentVault <- paymentVault
      self.sellingVault <- sellingVault
      self.feePercent = feePercent

      self.paymentFeeReceiver = paymentFeeReceiver
      self.sellingFeeReceiver = sellingFeeReceiver
    }

    destroy() {
      destroy self.paymentVault
      destroy self.sellingVault
    }

    access(contract) fun buy(buyer: Address, vault: @FungibleToken.Vault, price: UFix64, requestQty: UInt64, receiver: Capability<&{FungibleToken.Receiver}>) {
      pre {
        !self.isFrozen: "Pair is frozen"
        price > 0.0: "Input invalid"
        UInt64(vault.balance / price) == requestQty: "Quantity not match"
      }

      // 1 AURORA        = 20 * USDT
      // 1 Selling Token = Price *  1 Payment Token

      self.totalOrder = self.totalOrder + 1
      let orderId = self.totalOrder

      emit OrderCreated( pairId: self.uuid, orderId: orderId,
          type: OrderType.Buy.rawValue, price: price, qty: requestQty, fee: 0.0)

      self.paymentVault.deposit(from: <- vault) 

      let orders = self.getOpenSellOrdersForPrice(price: price, qty: requestQty)

      var matchedQty = (0 as UInt64)
      if orders.length == 0 {
        var needToMatchQty = requestQty;
        var deleted = 0 as UInt64

        for order in orders {

          let availableQty = order.qty - order.filledQty  
          var currentFilledQuantity: UInt64 = 0

          if needToMatchQty < availableQty {
            matchedQty = needToMatchQty

            //Increase filled quantity
            order.filledQty = order.filledQty + needToMatchQty
            self.sellOrders[order.orderId] = order

            currentFilledQuantity = needToMatchQty
            needToMatchQty = 0
          } else {
            matchedQty = matchedQty + availableQty
            needToMatchQty = needToMatchQty - availableQty
            currentFilledQuantity = availableQty

            // All qty of order filled
            self.sellOrders.remove(key: order.orderId)
            self.sortedSellOrders.remove(at: order.index - deleted)
            deleted = deleted + 1
          }


          // Fee for seller (pay in Selling Token)
          self.sellingFeeReceiver.borrow()!.deposit(from: <- self.sellingVault.withdraw(amount: UFix64(currentFilledQuantity) * UFix64(self.feePercent) / 10_000.0))

          // Send selling token to buyer
          receiver.borrow()!.deposit(from: <- self.sellingVault.withdraw(amount: UFix64(currentFilledQuantity) - UFix64(currentFilledQuantity) * UFix64(order.feePercent) / 10_000.0))


          // Fee for buyer (pay in Payment Token)
          self.paymentFeeReceiver.borrow()!.deposit(from: <- self.paymentVault.withdraw(amount: UFix64(currentFilledQuantity) * order.price * UFix64(order.feePercent) / 10_000.0))

          // Paid payment token to seller
          order.receiver.borrow()!.deposit(from: <- self.paymentVault.withdraw(amount: UFix64(currentFilledQuantity)* order.price - UFix64(currentFilledQuantity) * order.price * UFix64(self.feePercent) / 10_000.0))

          // Emit
          emit OrderFilled(pairId: self.uuid, buyOrderId: order.orderId, sellOrderId: self.totalOrder, price: order.price, fillQty: currentFilledQuantity, orderType: OrderType.Buy.rawValue)

          if needToMatchQty == 0 {
            break
          }

        }
      }


      if matchedQty != requestQty {
        let order = Order(
            orderId: orderId,
            owner: buyer,
            price: price,
            qty: requestQty,
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
    }

    access(contract) fun sell(seller: Address, vault: @FungibleToken.Vault, price: UFix64, requestQty: UInt64, receiver: Capability<&{FungibleToken.Receiver}>) {
      pre {
        !self.isFrozen: "Pair is frozen"
        price > 0.0: "Input invalid"
        UInt64(vault.balance / price) == requestQty: "Quantity not match"
      }

      self.totalOrder = self.totalOrder + 1
      let orderId = self.totalOrder

      emit OrderCreated(pairId: self.uuid, orderId: orderId,
          type: OrderType.Sell.rawValue, price: price, qty: requestQty, fee: 0.0)

      self.sellingVault.deposit(from: <- vault) 



      let orders = self.getOpenBuyOrdersForPrice(price: price, qty: requestQty)

      var matchedQty = (0 as UInt64)
      if orders.length == 0 {
        var needToMatchQty = requestQty;
        var deleted = 0 as UInt64

        for order in orders {

          let orderQtyRemaining = order.qty - order.filledQty  
          var currentFilledQuantity: UInt64 = 0

          if needToMatchQty < orderQtyRemaining {
            matchedQty = needToMatchQty

            //Increase filled quantity
            order.filledQty = order.filledQty + needToMatchQty
            self.sellOrders[order.orderId] = order

            currentFilledQuantity = needToMatchQty
            needToMatchQty = 0
          } else {
            matchedQty = matchedQty + orderQtyRemaining
            needToMatchQty = needToMatchQty - orderQtyRemaining
            currentFilledQuantity = orderQtyRemaining

            // All qty of order filled
            self.buyOrders.remove(key: order.orderId)
            self.sortedBuyOrders.remove(at: order.index - deleted)
            deleted = deleted + 1
          }


          // Fee for seller (pay in Selling Token)
          let sellingFeeAmount = UFix64(currentFilledQuantity) * UFix64(order.feePercent) / 10_000.0
          self.sellingFeeReceiver.borrow()!.deposit(from: <- self.sellingVault.withdraw(amount: sellingFeeAmount))

          // Send selling token to buyer
          receiver.borrow()!.deposit(from: <- self.sellingVault.withdraw(amount: UFix64(currentFilledQuantity) - sellingFeeAmount))


          // Fee for buyer (pay in Payment Token)
          let paymentFee = UFix64(currentFilledQuantity) * order.price * UFix64(order.feePercent) / 10_000.0
          self.paymentFeeReceiver.borrow()!.deposit(from: <- self.paymentVault.withdraw(amount: paymentFee))

          // Paid payment token to seller
          order.receiver.borrow()!.deposit(from: <- self.paymentVault.withdraw(amount: UFix64(currentFilledQuantity)* order.price - paymentFee))

          // Emit
          emit OrderFilled(pairId: self.uuid, buyOrderId: order.orderId, sellOrderId: self.totalOrder, price: order.price, fillQty: currentFilledQuantity, orderType: OrderType.Buy.rawValue)

          if needToMatchQty == 0 {
            break
          }

        }
      }


      if matchedQty != requestQty {
        let order = Order(
            orderId: orderId,
            owner: seller,
            price: price,
            qty: requestQty,
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

    access(contract) fun cancel(sender: Address, orderId: UInt64, type: OrderType) {
      if type == OrderType.Sell {
        if let order = self.sellOrders[orderId] {
          assert(order.owner == sender, message: "Forbidden")

          // Send token back
          order.receiver.borrow()!.deposit(from: <- self.sellingVault.withdraw(amount: UFix64(order.qty - order.filledQty) * order.price ))

          self.sellOrders.remove(key: order.orderId)


          // Need to upgrade when array to large
          var index: UInt64? = nil
          for id in self.sortedSellOrders {
            if orderId == id {
              index = id
              break
            }
          }

          if let index = index {
            self.sortedSellOrders.remove(at: index)
          }

          emit OrderCancelled(pairId: self.uuid, orderId: order.orderId, type: OrderType.Sell.rawValue)

          return 
        }
      }

      if type == OrderType.Buy {
        if let order = self.buyOrders[orderId] {

          assert(order.owner == sender, message: "Forbidden")

          // Send token back
          order.receiver.borrow()!.deposit(from: <- self.paymentVault.withdraw(amount: UFix64(order.qty - order.filledQty) * order.price ))

          self.buyOrders.remove(key: order.orderId)


          // Need to upgrade when array to large
          var index: UInt64? = nil
          for id in self.sortedBuyOrders {
            if orderId == id {
              index = id
              break
            }
          }

          if let index = index {
            self.sortedBuyOrders.remove(at: index)
          }

          emit OrderCancelled(pairId: self.uuid, orderId: order.orderId, type: OrderType.Buy.rawValue)

          return 
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
        } else{
          high = mid
        }
      }

      return low
    }

    /**
      * Get selling orders that can be filled with `price` of `token1`
    */
    access(contract) fun getOpenSellOrdersForPrice(price: UFix64, qty: UInt64): [Order] {
      if self.sellOrders.length == 0 {
        return []
      }

      let orders: [Order] = []
      var filled: UInt64 = 0

      // Search for order which price asc, it mean order with lower price will be select first
      var index =  0 as UInt64
      for orderId in self.sortedSellOrders {
        index = index + 1
        let order = self.sellOrders[orderId]!;
        if order.price <= price {
          order.index = index
          orders.append(order)

          filled = filled + order.qty - order.filledQty

          // Stop find
          if filled >= qty {
            break
          }
        }
      }
      
      return orders
    }

    access(contract) fun getOpenBuyOrdersForPrice(price: UFix64, qty: UInt64): [Order] {
      if self.buyOrders.length == 0 {
        return []
      }

      let orders: [Order] = []
      var filled: UInt64 = 0
      var index =  0 as UInt64

      // Search for order which price desc, it mean order with higher price will be select first
      for orderId in self.sortedBuyOrders {
        index = index + 1
        let order = self.buyOrders[orderId]!
        if order.price >= price {
          order.index = index
          orders.append(order)
          filled = filled + order.qty - order.filledQty

          // Stop find
          if filled >= qty {
            break
          }
        }
      }
      
      return orders
    }


    access(contract) fun setFee(feePercent: UInt64) {
      self.feePercent = feePercent 
    }

    access(contract) fun setFeeReceiver(
      paymentFeeReceiver: Capability<&{FungibleToken.Receiver}>,
      sellingFeeReceiver: Capability<&{FungibleToken.Receiver}>,
    ) {
      self.paymentFeeReceiver = paymentFeeReceiver
      self.sellingFeeReceiver = sellingFeeReceiver
    }

    access(contract) fun setFrozen(isFrozen: Bool) {
      self.isFrozen = isFrozen
    }
  }

  pub let AdminStoragePath: StoragePath;
  pub let ProxyStoragePath: StoragePath;

  pub resource ExchangeProxy {
    pub fun buy(pairId: UInt64, vault: @FungibleToken.Vault, price: UFix64, requestQty: UInt64, receiver: Capability<&{FungibleToken.Receiver}>) { 
      pre {
        ByteNextOrderBook.pairs.containsKey(pairId): "Pair not found"
        self.owner != nil: "Owner should not be nil"
      }


      let pair <- ByteNextOrderBook.pairs.remove(key: pairId)!

      pair.buy(buyer: self.owner!.address, vault: <- vault, price: price, requestQty: requestQty, receiver: receiver)

      let old <- ByteNextOrderBook.pairs.insert(key: pairId, <- pair)
      destroy old
    }


    pub fun sell(pairId: UInt64, vault: @FungibleToken.Vault, price: UFix64, requestQty: UInt64, receiver: Capability<&{FungibleToken.Receiver}>) {
      pre {
        ByteNextOrderBook.pairs.containsKey(pairId)
        self.owner != nil: "Owner should not be nil"
      }


      let pair <- ByteNextOrderBook.pairs.remove(key: pairId)!

      pair.sell(seller: self.owner!.address, vault: <- vault, price: price, requestQty: requestQty, receiver: receiver)

      let old <- ByteNextOrderBook.pairs.insert(key: pairId, <- pair)
      destroy old
    }


    pub fun cancel(pairId: UInt64, orderId: UInt64, type: OrderType) {
      pre {
        ByteNextOrderBook.pairs.containsKey(pairId)
        self.owner != nil: "Owner should not be nil"
      }


      let pair <- ByteNextOrderBook.pairs.remove(key: pairId)!

      pair.cancel(sender: self.owner!.address, orderId: orderId, type: type)

      let old <- ByteNextOrderBook.pairs.insert(key: pairId, <- pair)
      destroy old
    }
  }

  pub resource Administrator {
    pub fun createPair(isFrozen: Bool, minPrice: UFix64, maxPrice: UFix64,
      paymentVault: @FungibleToken.Vault, sellingVault: @FungibleToken.Vault,
      paymentFeeReceiver: Capability<&{FungibleToken.Receiver}>,
      sellingFeeReceiver: Capability<&{FungibleToken.Receiver}>,
      feePercent: UInt64
    ) {
      ByteNextOrderBook.totalPairs = ByteNextOrderBook.totalPairs + 1
      let paymentType = paymentVault.getType()
      let sellingTokenType = sellingVault.getType()

      let pair <- create Pair(isFrozen: isFrozen, minPrice: minPrice, maxPrice: maxPrice,
              paymentVault: <- paymentVault, sellingVault: <- sellingVault,
              paymentFeeReceiver: paymentFeeReceiver, sellingFeeReceiver: sellingFeeReceiver,
              feePercent: feePercent)

      let pairId = pair.uuid

      let oldPair <- ByteNextOrderBook.pairs[pairId] <- pair
      destroy oldPair

      emit PairCreated(pairId: pairId, paymentType: paymentType, sellingTokenType: sellingTokenType,
              minPrice: minPrice, maxPrice: maxPrice)
    }

    pub fun setFee(pairId: UInt64, feePercent: UInt64) {
      pre {
        ByteNextOrderBook.pairs.containsKey(pairId): "Pair not found"
      } 


      let pair <- ByteNextOrderBook.pairs.remove(key: pairId)!

      pair.setFee(feePercent: feePercent)

      let old <- ByteNextOrderBook.pairs.insert(key: pairId, <- pair)
      destroy old
    }

    pub fun setFeeReceiver(
      pairId: UInt64, 
      paymentFeeReceiver: Capability<&{FungibleToken.Receiver}>,
      sellingFeeReceiver: Capability<&{FungibleToken.Receiver}>,
    ) {
      pre {
        ByteNextOrderBook.pairs.containsKey(pairId): "Pair not found"
      } 


      let pair <- ByteNextOrderBook.pairs.remove(key: pairId)!

      pair.setFeeReceiver(paymentFeeReceiver: paymentFeeReceiver, sellingFeeReceiver: sellingFeeReceiver)

      let old <- ByteNextOrderBook.pairs.insert(key: pairId, <- pair)
      destroy old
    }

    pub fun freeze(pairId: UInt64) {
      pre {
        ByteNextOrderBook.pairs.containsKey(pairId): "Pair not found"
      } 


      let pair <- ByteNextOrderBook.pairs.remove(key: pairId)!

      pair.setFrozen(isFrozen: true)

      let old <- ByteNextOrderBook.pairs.insert(key: pairId, <- pair)
      destroy old
    }

    pub fun unfreeze(pairId: UInt64) {
      pre {
        ByteNextOrderBook.pairs.containsKey(pairId): "Pair not found"
      } 


      let pair <- ByteNextOrderBook.pairs.remove(key: pairId)!

      pair.setFrozen(isFrozen: false)

      let old <- ByteNextOrderBook.pairs.insert(key: pairId, <- pair)
      destroy old
    }
  }


  pub fun createProxy(): @ExchangeProxy {
    return <- create ExchangeProxy()
  }

  init() {
    self.AdminStoragePath = /storage/ByteNextAdminPath
    self.ProxyStoragePath = /storage/ByteNextOrderBookProxyPath

    self.pairs <- {}
    self.totalPairs = 0

    self.account.save(<- create Administrator(), to: self.AdminStoragePath)
  }
}