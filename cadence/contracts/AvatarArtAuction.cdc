//import FungibleToken from "./FungibleToken.cdc"
//import NonFungibleToken from "./NonFungibleToken.cdc";

import BNU from 0x02;
import FungibleToken from 0x01;
import NonFungibleToken from 0x03;
import AvatarArtNFT from 0x04;
import AvatarArtTransactionInfo from 0x01;

pub contract AvatarArtMarketplace {
    pub let CollectionStoragePath: StoragePath;
    pub let CollectionCapabilityPath: PublicPath;
    pub let AdminSaleCollectionStoragePath: StoragePath;

  // Event that is emitted when a new NFT is put up for sale
  pub event SellingOrderCreated(tokenId: UInt64, price: UFix64, owner: Address);

  // Event that is emitted when a token is purchased
  pub event TokenPurchased(id: UInt64, price: UFix64, time: UFix64)

  // Event that is emitted when a seller withdraws their NFT from the sale
  pub event SaleWithdrawn(id: UInt64)

  // Interface that users will publish for their Sale collection
  // that only exposes the methods that are supposed to be public
  //
  pub resource interface SalePublic {
    pub fun purchase(
        tokenId: UInt64,
        buyer: Address,
        affiliateAddress: Address,
        affiliateTokens: @BNU.Vault,
        storingTokens: @BNU.Vault,
        insuranceTokens: @BNU.Vault,
        contractorTokens: @BNU.Vault,
        platformTokens: @BNU.Vault,
        authorTokens: @BNU.Vault,
        sellerTokens: @BNU.Vault)
    pub fun idPrice(tokenId: UInt64): UFix64?
    pub fun getIDs(): [UInt64];
    pub fun getOwner(tokenId: UInt64): Address;
  }

  // SaleCollection
  //
  // NFT Collection object that allows a user to put their NFT up for sale
  // where others can send fungible tokens to purchase it
  //
  pub resource SaleCollection: SalePublic {
    // Dictionary of the NFTs that the user is putting up for sale
    pub var sellings: {UInt64: Bool}

    // Dictionary of the prices for each NFT by ID
    pub var prices: {UInt64: UFix64}
    pub var owners: {UInt64: Address};

    init () {
        self.sellings = {};
        self.prices = {};
        self.owners = {};
    }

    // Seller cancels selling order by removing tokenId from collection
    pub fun withdraw(tokenId: UInt64, owner: Address){
        pre{
            self.owners[tokenId] == owner: "Forbidden to withdraw";
        }
        // remove the price
        self.prices.remove(key: tokenId);
        self.owners.remove(key: tokenId);
        self.sellings.remove(key: tokenId);
    }

    // listForSale lists an NFT for sale in this collection
    pub fun createSellingOrder(tokenId: UInt64, price: UFix64, owner: Address) {
        // store the price in the price array
        self.prices[tokenId] = price
        self.owners[tokenId] = owner;
        self.sellings[tokenId] = true;

        emit SellingOrderCreated(tokenId: tokenId, price: price, owner: owner);
    }

    // purchase lets a user send tokens to purchase an NFT that is for sale
    pub fun purchase(
            tokenId: UInt64,
            buyer: Address,
            affiliateAddress: Address,
            affiliateTokens: @BNU.Vault,
            storingTokens: @BNU.Vault,
            insuranceTokens: @BNU.Vault,
            contractorTokens: @BNU.Vault,
            platformTokens: @BNU.Vault,
            authorTokens: @BNU.Vault,
            sellerTokens: @BNU.Vault
       ) {
        pre {
            self.sellings[tokenId] == true && self.prices[tokenId] != nil:
                "No token matching this ID for sale!"
        }

        let publicAccount = getAccount(0x01);

        let transactionAddressReference = publicAccount.getCapability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>(
            AvatarArtTransactionInfo.TransactionAddressCapabilityPublicPath).borrow()
                ?? panic("Could not borrow a reference to the hello capability");

        let feeInfoReference = publicAccount.getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath)
            .borrow() ?? panic("Could not borrow a reference to the hello capability");

        let transactionAddress: AvatarArtTransactionInfo.TransactionAddressItem = 
            transactionAddressReference.getAddress(tokenId: tokenId)!;
        let feeInfo: AvatarArtTransactionInfo.FeeInfoItem = 
            feeInfoReference.getFee(tokenId: tokenId)!;

        // get the value out of the optional
        let price = self.prices[tokenId]!;

        if(affiliateAddress != nil){
            if(feeInfo.affiliate != nil && feeInfo.affiliate > 0.0){
                if(affiliateTokens.balance != price * feeInfo.affiliate / 100.0){
                    destroy affiliateTokens;
                    panic("affiliate fee parameter is invalid");
                }else{
                    self.transferToken(receipent: affiliateAddress, balanceVault: <- affiliateTokens);
                }
            }else{
                destroy affiliateTokens;
            }
        }else{
            destroy affiliateTokens;
        }

        if(transactionAddress.storing != nil){
            if(feeInfo.storing != nil && feeInfo.storing > 0.0){
                if(storingTokens.balance != price * feeInfo.storing / 100.0){
                    destroy storingTokens;
                    panic("storing fee parameter is invalid");
                }else{
                    self.transferToken(receipent: transactionAddress.storing, balanceVault: <- storingTokens);
                }
            }else{
                destroy storingTokens;
            }
        }else{
            destroy storingTokens;
        }

        if(transactionAddress.insurance != nil){
            if(feeInfo.insurance != nil && feeInfo.insurance > 0.0){
                if(insuranceTokens.balance != price * feeInfo.insurance / 100.0){
                    destroy insuranceTokens;
                    panic("insurance fee parameter is invalid");
                }else{
                    self.transferToken(receipent: transactionAddress.insurance, balanceVault: <- insuranceTokens);
                }
            }else{
                destroy insuranceTokens;
            }
        }else{
            destroy insuranceTokens;
        }

        if(transactionAddress.contractor != nil){
            if(feeInfo.contractor != nil && feeInfo.contractor > 0.0){
                if(contractorTokens.balance != price * feeInfo.contractor / 100.0){
                    destroy contractorTokens;
                    panic("contractor fee parameter is invalid");
                }else{
                    self.transferToken(receipent: transactionAddress.contractor, balanceVault: <- contractorTokens);
                }
            }else{
                destroy contractorTokens;
            }
        }else{
            destroy contractorTokens;
        }

        if(transactionAddress.platform != nil){
            if(feeInfo.platform != nil && feeInfo.platform > 0.0){
                if(platformTokens.balance != price * feeInfo.platform / 100.0){
                    destroy platformTokens;
                    panic("platform fee parameter is invalid");
                }else{
                    self.transferToken(receipent: transactionAddress.platform, balanceVault: <- platformTokens);
                }
            }else{
                destroy platformTokens;
            }
        }else{
            destroy platformTokens;
        }

        if(transactionAddress.author != nil){
            if(feeInfo.author != nil && feeInfo.author > 0.0){
                if(authorTokens.balance != price * feeInfo.author / 100.0){
                    destroy authorTokens;
                    panic("author fee parameter is invalid");
                }else{
                    self.transferToken(receipent: transactionAddress.author, balanceVault: <- authorTokens);
                }
            }else{
                destroy authorTokens;
            }
        }else{
            destroy authorTokens;
        }

        self.prices[tokenId] = nil;
        let seller = self.owners[tokenId]!;
        let sellerAccount = getAccount(seller);

        let vaultRef = sellerAccount.getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath)
                        .borrow() ?? panic("Could not borrow reference to owner token vault");
        
        // deposit the purchasing tokens into the owners vault
        vaultRef.deposit(from: <-sellerTokens);

        self.owners[tokenId] = buyer;

        emit TokenPurchased(id: tokenId, price: price, time: getCurrentBlock().timestamp);
    }

    // idPrice returns the price of a specific token in the sale
    pub fun idPrice(tokenId: UInt64): UFix64? {
        return self.prices[tokenId]
    }

    // getIDs returns an array of token IDs that are for sale
    pub fun getIDs(): [UInt64] {
        return self.sellings.keys;
    }

    pub fun getOwner(tokenId: UInt64): Address{
        return self.owners[tokenId]!;
    }

    access(self) fun transferToken(receipent: Address, balanceVault: @BNU.Vault){
        let publicAccount = getAccount(receipent);
        let vaultRef =  publicAccount.getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath)
                        .borrow() ?? panic("Can not borrow vault capability");
        vaultRef.deposit(from: <- balanceVault);
    }

    destroy() {
        //Do nothing
    }
  }

    init(){
        self.CollectionStoragePath = /storage/avatarArtCollection;
        self.CollectionCapabilityPath = /public/avatarArtCollectionCapability;
        self.AdminSaleCollectionStoragePath = /storage/adminSaleCollection;

        self.account.save(<- create SaleCollection(), to: self.AdminSaleCollectionStoragePath);
        self.account.link<&{AvatarArtMarketplace.SalePublic}>(self.CollectionCapabilityPath, target: self.AdminSaleCollectionStoragePath);
    }
}