import NonFungibleToken from 0x03
import AvatarArtNFT from 0x04

// This transaction allows the Minter account to mint an NFT
// and deposit it into its collection.

transaction (tokenId: UInt64) {
    prepare(buyerAccount: AuthAccount) {
        let publicAccount = getAccount(0x01)
        let feeInfoReference = publicAccount.getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath)
                            .borrow()
                            ?? panic("Could not borrow a reference to the hello capability");

        let feeInfo = feeInfoReference.getFee(tokenId: tokenId);
        if(feeInfo.affiliate)

        // get the references to the buyer's fungible token Vault and NFT Collection Receiver
        self.collectionRef = acct.borrow<&AnyResource{NonFungibleToken.NFTReceiver}>(from: /storage/NFTCollection)!
        let vaultRef = acct.borrow<&FungibleToken.Vault>(from: /storage/MainVault)
            ?? panic("Could not borrow owner's vault reference")

        // withdraw tokens from the buyers Vault
        self.temporaryVault <- vaultRef.withdraw(amount: 10.0)
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(0x01)

        // get the reference to the seller's sale
        let saleRef = seller.getCapability<&AnyResource{Marketplace.SalePublic}>(/public/NFTSale)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        // purchase the NFT the the seller is selling, giving them the reference
        // to your NFT collection and giving them the tokens to buy it
        saleRef.purchase(tokenID: 1, recipient: self.collectionRef, buyTokens: <-self.temporaryVault)

        log("Token 1 has been bought by account 2!")
    }
}