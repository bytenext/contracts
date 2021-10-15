import FungibleToken from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtTransactionInfo from 0x02
import BNU from 0x01
import AvatarArtMarketplace from 0x03

transaction (
    tokenId: UInt64, price: UFix64, sellerAddress: Address, 
    affiliateAddress: Address?, contractOwnerAddress: Address){
    let sellerRef: &{AvatarArtMarketplace.SalePublic};

    let tokenVault: &BNU.Vault;
    let buyerTokenReceiver: Capability<&{FungibleToken.Receiver}>;
    let buyerMarketCollectionNftReceiver: Capability<&{AvatarArtMarketplace.SaleCollectionNftReceiver}>;

    let feeRef: Capability<&{AvatarArtTransactionInfo.PublicFeeInfo}>;
    let feeRecepientRef: Capability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>;

    prepare(userAccount: AuthAccount) {
        let sellerAccount = getAccount(sellerAddress);
        self.sellerRef = sellerAccount
            .getCapability<&{AvatarArtMarketplace.SalePublic}>(AvatarArtMarketplace.SaleCollectionPublicPath)
              .borrow() ?? panic("Can not borrow seller's AvatarArtMarketplace.SaleCollectionPublic");

        self.tokenVault = userAccount.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
                ?? panic("Can not borrow token vault capability");

        self.buyerTokenReceiver = userAccount
                .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        self.buyerMarketCollectionNftReceiver = userAccount
                .getCapability<&{AvatarArtMarketplace.SaleCollectionNftReceiver}>(AvatarArtMarketplace.SaleCollectionPublicPath);

        let contractOwnerAccount = getAccount(contractOwnerAddress);
        self.feeRef = contractOwnerAccount
                        .getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(
                        AvatarArtTransactionInfo.FeeInfoPublicPath);

        self.feeRecepientRef = contractOwnerAccount
                        .getCapability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>(
                        AvatarArtTransactionInfo.TransactionAddressPublicPath);
    }

    execute {
        let token <- self.tokenVault.withdraw(amount: price);
        var affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>? = nil;
        if(affiliateAddress != nil){
           affiliateTokenReceiver = getAccount(affiliateAddress!)
                  .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        }
     
        self.sellerRef.purchase(
            tokenId: tokenId,
            buyerSaleCollectionNftReceiver: self.buyerMarketCollectionNftReceiver, 
            affiliateTokenReceiver: affiliateTokenReceiver, 
            tokens: <- token, 
            feeReference: self.feeRef, 
            feeRecepientReference: self.feeRecepientRef)
           
        log("NFT is purchased");
    }
}