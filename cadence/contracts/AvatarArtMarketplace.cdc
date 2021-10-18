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
    pub let AdministratorStoragePath: StoragePath;

    pub event SellingOrderCreated(tokenId: UInt64, price: UFix64);
    pub event TokenPurchased(id: UInt64, price: UFix64, time: UFix64);
    pub event SaleWithdrawn(id: UInt64);

    pub var nftPrices: {UInt64: UFix64};
    pub var paymentTypes: {UInt64: Type};
    pub var withdrawables: {UInt64: Bool};
    pub var firstSolds: {UInt64: Bool};

    pub resource interface SaleCollectionNftReceiver{
        pub fun deposit(nft: @AvatarArtNFT.NFT);
    }

    pub resource interface SalePublic {
        pub fun purchase(
            tokenId: UInt64,
            buyerSaleCollectionNftReceiver: Capability<&{AvatarArtMarketplace.SaleCollectionNftReceiver}>,
            affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?,
            tokens: @FungibleToken.Vault,
            feeReference: Capability<&{AvatarArtTransactionInfo.PublicFeeInfo}>,
            feeRecepientReference: Capability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>);
        pub fun getSellingNFTs(): [UInt64];
    }

    pub resource SaleCollection: SalePublic, SaleCollectionNftReceiver {
        pub var nfts: @{UInt64: AvatarArtNFT.NFT};
        pub var sellings: {UInt64: Bool};
        pub let ownerTokenReceiver: Capability<&{FungibleToken.Receiver}>;
        
        init (ownerTokenReceiver: Capability<&{FungibleToken.Receiver}>) {
            self.ownerTokenReceiver = ownerTokenReceiver;
            self.nfts <- {};
            self.sellings = {};
        }

        destroy() {
            destroy self.nfts;
        }

        //User creates selling order for the first time
        //NFT should be transferred from user's storage to collection
        pub fun createSellingOrder(tokenId: UInt64, nft: @AvatarArtNFT.NFT) {
            let price = AvatarArtMarketplace.nftPrices[tokenId]!;
                // store the price in the price array
            let oldNft <- self.nfts.insert(key: tokenId, <- nft);

            //Set NFT as selling
            self.sellings[tokenId] = true;

            destroy oldNft;
            emit SellingOrderCreated(tokenId: tokenId, price: price);
        }

        //User creates selling orders after the first time order completes
        //NFT be still in user's marketplacae collection
        pub fun userCreateSellingOrder(tokenId: UInt64, price: UFix64, paymentType: Type){
            pre{
                tokenId > 0: "NFT is invalid";
                price > 0.0: "price should be greater than 0";
                AvatarArtMarketplace.nftPrices[tokenId] == 0.0:
                    "Can not create selling order";
                self.nfts[tokenId] != nil:
                    "User does not own this NFT";
            }

            var sellingPrice = price;

            if(AvatarArtMarketplace.firstSolds[tokenId] == false){
                sellingPrice = AvatarArtMarketplace.nftPrices[tokenId]!;
            }

            AvatarArtMarketplace.nftPrices[tokenId] = sellingPrice;
            AvatarArtMarketplace.paymentTypes[tokenId] = paymentType;
            //Set NFT as selling
            self.sellings[tokenId] = true;

            emit SellingOrderCreated(tokenId: tokenId, price: sellingPrice);
        }

        // Seller cancels selling order by removing tokenId from collection
        pub fun cancelSellingOrder(tokenId: UInt64){
            pre{
                self.nfts[tokenId] != nil: "NFT has not existed";
            }

            //Set NFT as selling
            self.sellings.remove(key: tokenId);

            AvatarArtMarketplace.nftPrices[tokenId] = 0.0;
        }

        //When a user purchase NFT, this NFT with be deposit to his collection
        pub fun deposit(nft: @AvatarArtNFT.NFT){
            pre{
                AvatarArtMarketplace.nftPrices[nft.id]! == 0.0: "Can not deposit nft"; 
            }
            let olfNft <- self.nfts.insert(key: nft.id, <- nft);
            destroy  olfNft;
        }

        // purchase lets a user send tokens to purchase an NFT that is for sale
        pub fun purchase(
            tokenId: UInt64,
            buyerSaleCollectionNftReceiver: Capability<&{AvatarArtMarketplace.SaleCollectionNftReceiver}>,
            affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?,
            tokens: @FungibleToken.Vault,
            feeReference: Capability<&{AvatarArtTransactionInfo.PublicFeeInfo}>,
            feeRecepientReference: Capability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>) {
            pre {
                AvatarArtMarketplace.nftPrices[tokenId] != nil && AvatarArtMarketplace.nftPrices[tokenId]! > 0.0:
                    "Can not purchase NFT";
                AvatarArtMarketplace.paymentTypes[tokenId] != nil:
                    "Payment token is not setted";
                tokens.isInstance(AvatarArtMarketplace.paymentTypes[tokenId]!):
                    "Payment token is not allowed";
                tokens.balance == AvatarArtMarketplace.nftPrices[tokenId]:
                    "Token balance is invalid";
            }

            let fee = feeReference.borrow()!.getFee(tokenId: tokenId)!;
            let feeRecepient = feeRecepientReference.borrow()!.getAddress(tokenId: tokenId)!;

            let price = AvatarArtMarketplace.nftPrices[tokenId]!;

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

            //Update contract price
            AvatarArtMarketplace.nftPrices[tokenId] = 0.0;
            if(AvatarArtMarketplace.firstSolds[tokenId] != true){
                AvatarArtMarketplace.firstSolds[tokenId] = true;
            }
            self.sellings.remove(key: tokenId);

            let nft <- self.nfts.remove(key: tokenId)!;
            buyerSaleCollectionNftReceiver.borrow()!.deposit(nft: <- nft);

            emit TokenPurchased(id: tokenId, price: price, time: getCurrentBlock().timestamp);
        }

        //User can withdraw NFT when admin approves
        pub fun withdrawNft(tokenId: UInt64): @AvatarArtNFT.NFT{
            pre{
                AvatarArtMarketplace.withdrawables[tokenId] == true:
                    "Can not withdraw NFT";
                self.nfts[tokenId] != nil: "NFT has not existed";
            }

            AvatarArtMarketplace.nftPrices.remove(key: tokenId);
            AvatarArtMarketplace.withdrawables.remove(key: tokenId);
            AvatarArtMarketplace.firstSolds.remove(key: tokenId);
            self.sellings.remove(key: tokenId);
            return <- self.nfts.remove(key: tokenId)!;
        }

        // getIDs returns an array of token IDs that are for sale
        pub fun getSellingNFTs(): [UInt64] {
            return self.sellings.keys;
        }
    }

    pub resource Administrator{
        pub fun setNftPrice(tokenId: UInt64, price: UFix64){
            AvatarArtMarketplace.nftPrices[tokenId] = price;
        }

        pub fun setPaymentType(tokenId: UInt64, paymentType: Type){
            AvatarArtMarketplace.paymentTypes[tokenId] = paymentType;
        }

        pub fun allowUserToWithdraw(tokenId: UInt64){
            AvatarArtMarketplace.withdrawables[tokenId] = true;
        }
    }

    pub fun createMarketplaceCollection(ownerTokenReceiver: Capability<&{FungibleToken.Receiver}>): @SaleCollection{
        return <- create SaleCollection(ownerTokenReceiver: ownerTokenReceiver);
    }

    init(){
            self.SaleCollectionStoragePath = /storage/avatarArtMarketplaceCollection;
            self.SaleCollectionPublicPath = /public/avatarArtMarketplaceCollection;
            self.AdministratorStoragePath = /storage/avatarArtMarketplaceAdmin;

            self.nftPrices = {};
            self.paymentTypes = {};
            self.withdrawables = {};
            self.firstSolds = {};

            self.account.save(<- create Administrator(), to: self.AdministratorStoragePath);
    }
}