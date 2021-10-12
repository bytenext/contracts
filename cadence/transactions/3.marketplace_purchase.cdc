import FungibleToken from 0x01
import BNU from 0x02
import NonFungibleToken from 0x03
import AvatarArtNFT from 0x04
import AvatarArtMarketplace from 0x05
import AvatarArtTransactionInfo from 0x01

// This transaction allows the Minter account to mint an NFT
// and deposit it into its collection.

transaction (tokenId: UInt64, sellerAccountAddress: Address, affiliateAddress: Address) {
    let publicSaleCollection: &{AvatarArtMarketplace.SalePublic};

    let affiliateTokens: @BNU.Vault;
    let storingTokens: @BNU.Vault;
    let insuranceTokens: @BNU.Vault;
    let contractorTokens: @BNU.Vault;
    let platformTokens: @BNU.Vault;
    let authorTokens: @BNU.Vault;
    let sellerTokens: @BNU.Vault;

    let buyer: Address;

    prepare(buyerAccount: AuthAccount) {
        self.buyer = buyer.address;
        //Get token price
        self.publicSaleCollection = getAccount(sellerAccountAddress)
                              .getCapability<&{AvatarArtMarketplace.SalePublic}>(AvatarArtMarketplace.CollectionCapabilityPath)
                              .borrow() ?? panic("Can not borrow a reference to the public sale collection capability");
        let price = self.publicSaleCollection.idPrice(tokenId: tokenId)!;

        let publicAccount = getAccount(0x01)
        let feeInfoReference = publicAccount
                .getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath)
                            .borrow()
                            ?? panic("Could not borrow a reference to the fee info capability");
        let feeInfo: AvatarArtTransactionInfo.FeeInfoItem = 
            feeInfoReference.getFee(tokenId: tokenId)!;
        let affiliate = feeInfo.affiliate == nil ? 0.0 : feeInfo.affiliate;
        let storing = feeInfo.storing == nil ? 0.0 : feeInfo.storing;
        let insurance = feeInfo.insurance == nil ? 0.0 : feeInfo.insurance;
        let contractor = feeInfo.contractor == nil ? 0.0 : feeInfo.contractor;
        let platform = feeInfo.platform == nil ? 0.0 : feeInfo.platform;
        let author = feeInfo.author == nil ? 0.0 : feeInfo.author;

        let vaultRef = buyerAccount.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
            ?? panic("Could not borrow owner's vault reference")

        let affiliateFee = price * affiliate / 100.0;
        let storingFee = price * storing / 100.0;
        let insuranceFee = price * insurance / 100.0;
        let contractorFee = price * contractor / 100.0;
        let platformFee = price * platform / 100.0;
        let authorFee = price * author / 100.0;
        let sellerFee = price - affiliateFee - storingFee - insuranceFee - contractorFee - platformFee - authorFee;

        self.affiliateTokens <- vaultRef.withdraw(amount: affiliateFee) as! @BNU.Vault;
        self.storingTokens <- vaultRef.withdraw(amount: storingFee) as! @BNU.Vault;
        self.insuranceTokens <- vaultRef.withdraw(amount: insuranceFee) as! @BNU.Vault;
        self.contractorTokens <- vaultRef.withdraw(amount: contractorFee) as! @BNU.Vault;
        self.platformTokens <- vaultRef.withdraw(amount: platformFee) as! @BNU.Vault;
        self.authorTokens <- vaultRef.withdraw(amount: authorFee) as! @BNU.Vault;
        self.sellerTokens <- vaultRef.withdraw(amount: sellerFee) as! @BNU.Vault;
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(0x01)

        // get the reference to the seller's sale
        let saleRef = seller.getCapability<&AnyResource{AvatarArtMarketplace.SalePublic}>(/public/NFTSale)
            .borrow()
            ?? panic("Could not borrow seller's sale reference")

        // purchase the NFT the the seller is selling, giving them the reference
        // to your NFT collection and giving them the tokens to buy it
        saleRef.purchase(
            tokenId: tokenId,
            buyer: self.buyer,
            affiliateAddress: affiliateAddress,
            affiliateTokens: <-self.affiliateTokens,
            storingTokens: <-self.storingTokens,
            insuranceTokens: <-self.insuranceTokens,
            contractorTokens: <-self.contractorTokens,
            platformTokens: <-self.platformTokens,
            authorTokens: <-self.authorTokens,
            sellerTokens: <-self.sellerTokens
        );

        log("Purchasing done!")
    }
}