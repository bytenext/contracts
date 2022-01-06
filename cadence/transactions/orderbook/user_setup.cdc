import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc"

transaction() {
  prepare(signer: AuthAccount) {
    if signer.borrow<&ByteNextOrderBook.ExchangeProxy>(from: ByteNextOrderBook.ProxyStoragePath) == nil {
      let proxy <- ByteNextOrderBook.createProxy()
      signer.save(<-proxy, to: ByteNextOrderBook.ProxyStoragePath)
    }
  }
}