//import FungibleToken from "./FungibleToken.cdc"
//import NonFungibleToken from "./NonFungibleToken.cdc";

import BNU from 0x01;
import FungibleToken from 0x01;
import NonFungibleToken from 0x01;
import AvatarArtNFT from 0x01;
import AvatarArtTransactionInfo from 0x02;

pub contract AvatarArtMarketplace {
    pub let SaleCollectionStoragePath: StoragePath;
    pub let SaleCollectionPublicPath: PublicPath;
    pub let AdminSaleCollectionStoragePath: StoragePath;

  // Event that is emitted when a new NFT is put up for sale
  pub event SellingOrderCreated(tokenId: UInt64, price: UFix64);

  // Event that is emitted when a token is purchased
  pub event TokenPurchased(id: UInt64, price: UFix64, time: UFix64);

  // Event that is emitted when a seller withdraws their NFT from the sale
  pub event SaleWithdrawn(id: UInt64)

  access(self) var nftPrices: {UInt64: UFix64};
  access(self) var paymentTypes: {UInt64: Type};

  access(account) fun setNftPrice(tokenId: UInt64, price: UFix64){
      self.nftPrices[tokenId] = price;
  }

  access(account) fun setPaymentTypes(tokenId: UInt64, paymentType: Type){
      self.paymentTypes[tokenId] = paymentType;
  }

  pub fun getNftPrice(tokenId: UInt64): UFix64?{
    return self.nftPrices[tokenId];
  }

  pub fun getPaymentTypes(tokenId: UInt64): Type?{
    return self.paymentTypes[tokenId];
  }

  // Interface that users will publish for their Sale collection
  // that only exposes the methods that are supposed to be public
  //
  pub resource interface SalePublic {
    pub fun purchase(
        tokenId: UInt64,
        buyerNftReceiver: Capability<&{NonFungibleToken.Receiver}>,
        affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?,
        tokens: @FungibleToken.Vault,
        transactionInfoAccount: PublicAccount);
    pub fun idPrice(tokenId: UInt64): UFix64?
    pub fun getIDs(): [UInt64];
  }

  // SaleCollection
  //
  // NFT Collection object that allows a user to put their NFT up for sale
  // where others can send fungible tokens to purchase it
  //
  pub resource SaleCollection: SalePublic {
    // Dictionary of the NFTs that the user is putting up for sale

    // Dictionary of the prices for each NFT by ID
    pub var prices: {UInt64: UFix64};
    pub var nfts: @{UInt64: AvatarArtNFT.NFT};
    pub let ownerTokenReceiver: Capability<&{FungibleToken.Receiver}>;

    // listForSale lists an NFT for sale in this collection
    pub fun createSellingOrder(tokenId: UInt64, nft: @AvatarArtNFT.NFT) {
      let price = AvatarArtMarketplace.getNftPrice(tokenId: tokenId)!;
        // store the price in the price array
      self.prices[tokenId] = price;
      let oldNft <- self.nfts.insert(key: tokenId, <- nft);
      destroy oldNft;
      emit SellingOrderCreated(tokenId: tokenId, price: price);
    }

    // Seller cancels selling order by removing tokenId from collection
    pub fun cancelSellingOrder(tokenId: UInt64): @AvatarArtNFT.NFT{
        pre{
            self.nfts[tokenId] != nil: "NFT has not existed";
        }
        // remove the price
        self.prices.remove(key: tokenId);

        return <- self.nfts.remove(key: tokenId)!;
    }

    // purchase lets a user send tokens to purchase an NFT that is for sale
    pub fun purchase(
        tokenId: UInt64,
        buyerNftReceiver: Capability<&{NonFungibleToken.Receiver}>,
        affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?,
        tokens: @FungibleToken.Vault,
        transactionInfoAccount: PublicAccount) {
        pre {
            self.prices[tokenId] != nil:
                "No token matching this ID for sale!";
            AvatarArtMarketplace.getPaymentTypes(tokenId: tokenId) != nil:
                "Payment token is not setted";
            tokens.isInstance(AvatarArtMarketplace.getPaymentTypes(tokenId: tokenId)!):
                "Payment token is not allowed";
            tokens.balance == self.prices[tokenId]:
                "Token balance is invalid";
        }

        let feeReference = transactionInfoAccount
                  .getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath)
                  .borrow()??panic("Can not borrow AvatarArtTransactionInfo.PublicFeeInfo capability");
                  
        let fee = feeReference.getFee(tokenId: tokenId)!;

        let feeRecepientReference = transactionInfoAccount
            .getCapability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>(AvatarArtTransactionInfo.TransactionAddressCapabilityPublicPath)
            .borrow()??panic("Can not borrow AvatarArtTransactionInfo.PublicTransactionAddress capability");
        let feeRecepient = feeRecepientReference.getAddress(tokenId: tokenId)!;

        //Distribute for users
        var tokenQuantity = tokens.balance;
        if(fee.affiliate != nil && fee.affiliate > 0.0 && affiliateTokenReceiver != nil){
            let fee = tokenQuantity * fee.affiliate / 100.0;
            let feeVault <- tokens.withdraw(amount: fee);
            affiliateTokenReceiver!.borrow()!.deposit(from: <- feeVault);
        }

        if(fee.storing != nil && fee.storing > 0.0 && feeRecepient.storing != nil){
            let fee = tokenQuantity * fee.storing / 100.0;
            let feeVault <- tokens.withdraw(amount: fee);
            feeRecepient.storing!.borrow()!.deposit(from: <- feeVault);
        }

        if(fee.insurance != nil && fee.insurance > 0.0 && feeRecepient.insurance != nil){
            let fee = tokenQuantity * fee.insurance / 100.0;
            let feeVault <- tokens.withdraw(amount: fee);
            feeRecepient.insurance!.borrow()!.deposit(from: <- feeVault);
        }

        if(fee.contractor != nil && fee.contractor > 0.0 && feeRecepient.contractor != nil){
            let fee = tokenQuantity * fee.contractor / 100.0;
            let feeVault <- tokens.withdraw(amount: fee);
            feeRecepient.contractor!.borrow()!.deposit(from: <- feeVault);
        }

        if(fee.platform != nil && fee.platform > 0.0 && feeRecepient.platform != nil){
            let fee = tokenQuantity * fee.platform / 100.0;
            let feeVault <- tokens.withdraw(amount: fee);
            feeRecepient.platform!.borrow()!.deposit(from: <- feeVault);
        }

        if(fee.author != nil && fee.author > 0.0 && feeRecepient.author != nil){
            let fee = tokenQuantity * fee.author / 100.0;
            let feeVault <- tokens.withdraw(amount: fee);
            feeRecepient.author!.borrow()!.deposit(from: <- feeVault);
        }

        self.ownerTokenReceiver.borrow()!.deposit(from: <- tokens);
        let price = self.prices[tokenId]!;
        self.prices.remove(key: tokenId);

        let nft <- self.nfts.remove(key: tokenId) as! @NonFungibleToken.NFT;
        buyerNftReceiver.borrow()!.deposit(token: <- nft);

        emit TokenPurchased(id: tokenId, price: price, time: getCurrentBlock().timestamp);
    }

    // idPrice returns the price of a specific token in the sale
    pub fun idPrice(tokenId: UInt64): UFix64? {
        return self.prices[tokenId]
    }

    // getIDs returns an array of token IDs that are for sale
    pub fun getIDs(): [UInt64] {
        return self.nfts.keys;
    }

    init (ownerTokenReceiver: Capability<&{FungibleToken.Receiver}>) {
        self.ownerTokenReceiver = ownerTokenReceiver;
        self.prices = {};
        self.nfts <- {};
    }

    destroy() {
        destroy self.nfts;
    }
  }

  init(ownerTokenReceiver: Capability<&{FungibleToken.Receiver}>){
        self.SaleCollectionStoragePath = /storage/avatarArtCollection;
        self.SaleCollectionPublicPath = /public/avatarArtCollection;

        self.nftPrices = {};
        self.paymentTypes = {};

        self.account.save(<- create SaleCollection(ownerTokenReceiver: ownerTokenReceiver), to: self.AdminSaleSaleCollectionStoragePath);
        self.account.link<&SaleCollection{AvatarArtMarketplace.SalePublic}>(self.SaleCollectionPublicPath, target: self.AdminSaleSaleCollectionStoragePath);
  }
}