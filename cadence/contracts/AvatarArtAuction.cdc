import FungibleToken from 0x01;
import NonFungibleToken from 0x01;
import AvatarArtNFT from 0x01;
import AvatarArtTransactionInfo from 0x02;

pub contract AvatarArtAuction {
    pub event NewAuctionCreated(tokenId: UInt64, startTime: UFix64, endTime: UFix64, startPrice: UFix64);
    pub event AuctionPriceUpdated(tokenId: UInt64, price: UFix64);
    pub event AuctionTimeUpdated(tokenId: UInt64, startTime: UFix64, endTime: UFix64);
    pub event Distributed(tokenId: UInt64, user: Address);
    pub event NewPlace(tokenId: UInt64, price: UFix64, user: Address, time: UFix64);

    pub let AuctionAdminStoragePath: StoragePath;
    pub let AuctionPublicPath: PublicPath;

        pub struct AuctionItem{
        pub(set) var startTime: UFix64;
        pub(set) var endTime: UFix64;
        pub var startPrice: UFix64;
        pub(set) var lastPrice: UFix64;
        pub(set) var affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?;
        pub(set) var winnerVaultReceiver: Capability<&{FungibleToken.Receiver}>?;
        pub(set) var ownerNftReceiver: Capability<&{NonFungibleToken.Receiver}>;
        pub let ownerVaultReceiver: Capability<&{FungibleToken.Receiver}>;

        init(
            startTime: UFix64,
            endTime: UFix64, 
            startPrice: UFix64,
            ownerNftReceiver: Capability<&{NonFungibleToken.Receiver}>,
            ownerVaultReceiver: Capability<&{FungibleToken.Receiver}>
            ){
            self.startTime = startTime;
            self.endTime = endTime;
            self.startPrice = startPrice;
            self.lastPrice = 0.0;
            self.affiliateTokenReceiver = nil;
            self.ownerVaultReceiver = ownerVaultReceiver;
            self.ownerNftReceiver = ownerNftReceiver;
            self.winnerVaultReceiver = nil;
        }
    }

    pub resource interface AuctionPublic{
        pub fun getAuctionInfo(tokenId:UInt64): AuctionItem?;
        pub fun getPriceStep(price: UFix64): UFix64?;
        pub fun getPaymentType(tokenId: UInt64): Type?;
        pub fun place(
            tokenId: UInt64,
            price: UFix64,
            affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?,
            placeUserTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            placeUserNftReceiver: Capability<&{NonFungibleToken.Receiver}>,
            token: @FungibleToken.Vault);

        pub fun distribute(tokenId: UInt64, transactionInfoAccount: PublicAccount);
    }

    /**
    * Resource to store all auction
    **/
    pub resource Auction : AuctionPublic{
        pub var auctionInfos: {UInt64: AuctionItem};
        pub var priceSteps: {UFix64: UFix64};
        pub var paymentTypes: {UInt64: Type};
        pub var keptVaults: @{UInt64: FungibleToken.Vault};
        pub var nfts: @{UInt64: AvatarArtNFT.NFT};

        pub fun getAuctionInfo(tokenId:UInt64): AuctionItem?{
          return self.auctionInfos[tokenId];
        }

        pub fun getPaymentType(tokenId: UInt64): Type?{
            return self.paymentTypes[tokenId];
        }

        pub fun getPriceStep(price: UFix64): UFix64?{
          var priceStep: UFix64 = 0.0;
          var prevPrice: UFix64 = 0.0;
          for key in self.priceSteps.keys{
              if(key == price){
                  return self.priceSteps[key];
              }else if(key < price && prevPrice < key){
                  priceStep = self.priceSteps[key]!;
                  prevPrice = key;
              }
          }

          return priceStep;
        }

        pub fun setPaymentType(tokenId: UInt64, paymentType: Type){
            self.paymentTypes[tokenId] = paymentType;
        }

        pub fun setPriceStep(price: UFix64, priceStep: UFix64){
            pre{
                priceStep > 0.0: "priceStep should be greater than 0";
            }
            self.priceSteps[price] = priceStep;
        }

        pub fun createNewAuction(
            startTime: UFix64,
            endTime: UFix64,
            price: UFix64,
            paymentType: Type,
            ownerNftReceiver: Capability<&{NonFungibleToken.Receiver}>,
            ownerVaultReceiver: Capability<&{FungibleToken.Receiver}>,
            nft: @AvatarArtNFT.NFT){
            pre{
                self.auctionInfos[nft.id] == nil: "Auction has been created";
            }
            let tokenId = nft.id;

            self.auctionInfos[tokenId] = AuctionItem(
                startTime: startTime, 
                endTime: endTime,
                startPrice: price,
                ownerNftReceiver: ownerNftReceiver,
                ownerVaultReceiver: ownerVaultReceiver);

            self.paymentTypes[tokenId] = paymentType;

            let oldNft <- self.nfts.insert(key: tokenId, <- nft);
            destroy oldNft;

            emit NewAuctionCreated(tokenId: tokenId, startTime: startTime, endTime: endTime, startPrice: price);
        }

        pub fun updateAuctionTime(tokenId: UInt64, startTime: UFix64, endTime: UFix64){
            pre{
                self.auctionInfos[tokenId] != nil: "Auction has not been created";
            }

            var auction = self.auctionInfos[tokenId] ?? panic("Auction has not existed");

            auction.startTime = startTime;
            auction.endTime = endTime;

            self.auctionInfos[tokenId] = auction;

            emit AuctionTimeUpdated(tokenId: tokenId, startTime: startTime, endTime: endTime);
        }

        pub fun updateAuctionPrice(tokenId: UInt64, price: UFix64){
            pre{
                self.auctionInfos[tokenId] != nil: "Auction has not been created";
            }
            var auction = self.auctionInfos[tokenId] ?? panic("Auction has not existed");
            if(auction.startTime < getCurrentBlock().timestamp){
                panic("Can not set price when auction starts");
            }

            auction.lastPrice = price;

            self.auctionInfos[tokenId] = auction;
            emit AuctionPriceUpdated(tokenId: tokenId, price: price);
        }

        pub fun place(
            tokenId: UInt64,
            price: UFix64,
            affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?,
            placeUserTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            placeUserNftReceiver: Capability<&{NonFungibleToken.Receiver}>,
            token: @FungibleToken.Vault){
            pre{
                self.auctionInfos[tokenId] != nil: "Auction has not been created";
                self.paymentTypes[tokenId] != nil: "Payment type has not been set";
                token.isInstance(self.paymentTypes[tokenId]!) : "Payment token is not accepted";
                token.balance == price: "Invalid balance to place";
            }

            var auction = self.auctionInfos[tokenId] ?? panic("Auction has not existed");
            let currentTime = getCurrentBlock().timestamp;
            if(currentTime < auction.startTime || currentTime > auction.endTime){
              panic("Invalid time to place");
            }

            if(auction.lastPrice + self.getPriceStep(price: auction.startPrice)! > price){
              panic("Invalid price for price step");
            }

            let userAddress = placeUserTokenReceiver.address;

            //If has last winner, refund to him
            let oldVault <- self.keptVaults.insert(key: tokenId, <- token);
            if(oldVault != nil){
                //Refund for last winner
                auction.winnerVaultReceiver!.borrow()!.deposit(from: <- oldVault!);
            }else{
                destroy oldVault;
            }

            //Update winner and last bid price
            auction.winnerVaultReceiver = placeUserTokenReceiver;
            auction.ownerNftReceiver = placeUserNftReceiver;
            auction.affiliateTokenReceiver = affiliateTokenReceiver;
            auction.lastPrice = price;
            self.auctionInfos[tokenId] = auction;

            emit NewPlace(tokenId: tokenId, price: price, user: userAddress, time: getCurrentBlock().timestamp);
        }

        pub fun distribute(tokenId: UInt64, transactionInfoAccount: PublicAccount){
            pre{
                self.auctionInfos[tokenId] != nil: "Auction has not been created";
            }

            var auction = self.auctionInfos[tokenId] ?? panic("Auction has not existed");
            assert(getCurrentBlock().timestamp > auction.endTime, message: "Auction has not ended");

            //Transfer NFT to winner, winner can be owner or new winner
            let nft: @NonFungibleToken.NFT <- self.nfts.remove(key: tokenId) as! @NonFungibleToken.NFT;
            auction.ownerNftReceiver.borrow()!.deposit(token: <- nft);

            if(auction.winnerVaultReceiver != nil){
                let feeReference = transactionInfoAccount
                  .getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath)
                  .borrow()??panic("Can not borrow AvatarArtTransactionInfo.PublicFeeInfo capability");
                  
                let fee = feeReference.getFee(tokenId: tokenId)!;

                let feeRecepientReference = transactionInfoAccount
                  .getCapability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>(AvatarArtTransactionInfo.TransactionAddressCapabilityPublicPath)
                  .borrow()??panic("Can not borrow AvatarArtTransactionInfo.PublicTransactionAddress capability");
                let feeRecepient = feeRecepientReference.getAddress(tokenId: tokenId)!;

                //Distribute for users
                let tokenVault <- self.keptVaults.remove(key: tokenId)!;
                var tokenQuantity = tokenVault.balance;
                if(fee.affiliate != nil && fee.affiliate > 0.0 && auction.affiliateTokenReceiver != nil){
                    let fee = tokenQuantity * fee.affiliate / 100.0;
                    let feeVault <- tokenVault.withdraw(amount: fee);
                    auction.affiliateTokenReceiver!.borrow()!.deposit(from: <- feeVault);
                }

                if(fee.storing != nil && fee.storing > 0.0 && feeRecepient.storing != nil){
                    let fee = tokenQuantity * fee.storing / 100.0;
                    let feeVault <- tokenVault.withdraw(amount: fee);
                    feeRecepient.storing!.borrow()!.deposit(from: <- feeVault);
                }

                if(fee.insurance != nil && fee.insurance > 0.0 && feeRecepient.insurance != nil){
                    let fee = tokenQuantity * fee.insurance / 100.0;
                    let feeVault <- tokenVault.withdraw(amount: fee);
                    feeRecepient.insurance!.borrow()!.deposit(from: <- feeVault);
                }

                if(fee.contractor != nil && fee.contractor > 0.0 && feeRecepient.contractor != nil){
                    let fee = tokenQuantity * fee.contractor / 100.0;
                    let feeVault <- tokenVault.withdraw(amount: fee);
                    feeRecepient.contractor!.borrow()!.deposit(from: <- feeVault);
                }

                if(fee.platform != nil && fee.platform > 0.0 && feeRecepient.platform != nil){
                    let fee = tokenQuantity * fee.platform / 100.0;
                    let feeVault <- tokenVault.withdraw(amount: fee);
                    feeRecepient.platform!.borrow()!.deposit(from: <- feeVault);
                }

                if(fee.author != nil && fee.author > 0.0 && feeRecepient.author != nil){
                    let fee = tokenQuantity * fee.author / 100.0;
                    let feeVault <- tokenVault.withdraw(amount: fee);
                    feeRecepient.author!.borrow()!.deposit(from: <- feeVault);
                }

                auction.ownerVaultReceiver.borrow()!.deposit(from: <-tokenVault);
            }

            //Remove resources
            self.auctionInfos.remove(key: tokenId);

            emit Distributed(tokenId: tokenId, user: auction.ownerNftReceiver.address);
        }

        init(){
            self.auctionInfos = {};
            self.priceSteps = {};
            self.paymentTypes = {};
            self.keptVaults <- {};
            self.nfts <- {};
        }

        destroy() {
            destroy self.keptVaults;
            destroy self.nfts;
        }
    }
    
    init(){
        self.AuctionAdminStoragePath = /storage/avatarArtAdminAuction;
        self.AuctionPublicPath = /public/avatarArtAdminAuction;

        self.account.save(<- create Auction(), to: self.AuctionAdminStoragePath);
        self.account.link<&Auction{AuctionPublic}>(self.AuctionPublicPath, target: self.AuctionAdminStoragePath);
    }
}