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

    pub let AuctionStoragePath: StoragePath;
    pub let AuctionPublicPath: PublicPath;
    pub let AdminStoragePath: StoragePath;

    pub var nftStartPrices: {UInt64: UFix64};
    pub var paymentTypes: {UInt64: Type};
    pub var priceSteps: {UFix64: UFix64};
    pub var withdrawables: {UInt64: Bool};
    pub var firstSolds: {UInt64: Bool};

    pub struct AuctionItem{
        pub(set) var startTime: UFix64;
        pub(set) var endTime: UFix64;
        pub var startPrice: UFix64;
        pub(set) var lastPrice: UFix64;
        pub(set) var affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?;
        pub(set) var winnerVaultReceiver: Capability<&{FungibleToken.Receiver}>?;
        pub(set) var winnerAuctionNftReceiver: Capability<&{AuctionNFTReceiver}>?;

        init(
            startTime: UFix64,
            endTime: UFix64, 
            startPrice: UFix64){
            self.startTime = startTime;
            self.endTime = endTime;
            self.startPrice = startPrice;
            self.lastPrice = 0.0;
            self.affiliateTokenReceiver = nil;
            self.winnerVaultReceiver = nil;
            self.winnerAuctionNftReceiver = nil;
        }
    }

    pub resource interface AuctionNFTReceiver{
        pub fun deposit(nft: @AvatarArtNFT.NFT);
    } 

    pub resource interface AuctionPublic{
        pub fun getAuctionInfo(tokenId: UInt64): AuctionItem?;
        pub fun place(
            tokenId: UInt64,
            price: UFix64,
            affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?,
            placeUserTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            placeUserAuctionNftReceiver: Capability<&{AuctionNFTReceiver}>,
            token: @FungibleToken.Vault);

        pub fun distribute(
            tokenId: UInt64,
            feeReference: Capability<&{AvatarArtTransactionInfo.PublicFeeInfo}>,
            feeRecepientReference: Capability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>);
    }

    pub resource Auction : AuctionPublic, AuctionNFTReceiver{
        pub var ownerVaultReceiver: Capability<&{FungibleToken.Receiver}>;
        pub var ownerNftReceiver: Capability<&{NonFungibleToken.Receiver}>;

        pub var auctionInfos: {UInt64: AuctionItem};
        pub var auctionings:  {UInt64: Bool};
       
        pub var keptVaults: @{UInt64: FungibleToken.Vault};
        pub var nfts: @{UInt64: AvatarArtNFT.NFT};

        pub fun getAuctionInfo(tokenId:UInt64): AuctionItem?{
          return self.auctionInfos[tokenId];
        }

        access(self) fun getPriceStep(price: UFix64): UFix64?{
          var priceStep: UFix64 = 0.0;
          var prevPrice: UFix64 = 0.0;
          for key in AvatarArtAuction.priceSteps.keys{
              if(key == price){
                  return AvatarArtAuction.priceSteps[key];
              }else if(key < price && prevPrice < key){
                  priceStep = AvatarArtAuction.priceSteps[key]!;
                  prevPrice = key;
              }
          }

          return priceStep;
        }

        pub fun createNewAuction(
            startTime: UFix64,
            endTime: UFix64,
            nft: @AvatarArtNFT.NFT){
            pre{
                self.auctionInfos[nft.id] == nil: "Auction has been created";
                AvatarArtAuction.nftStartPrices[nft.id] != nil && 
                AvatarArtAuction.nftStartPrices[nft.id]! > 0.0:
                    "Can not create new auction";
            }
            let price = AvatarArtAuction.nftStartPrices[nft.id]!;
            let tokenId = nft.id;

            self.auctionInfos[tokenId] = AuctionItem(
                startTime: startTime, 
                endTime: endTime,
                startPrice: price);

            self.auctionings[tokenId] = true;

            let oldNft <- self.nfts.insert(key: tokenId, <- nft);
            destroy oldNft;

            emit NewAuctionCreated(tokenId: tokenId, startTime: startTime, endTime: endTime, startPrice: price);
        }

        pub fun userCreateNewAuction(
            tokenId: UInt64,
            price: UFix64,
            startTime: UFix64,
            endTime: UFix64){
            pre{
                self.auctionInfos[tokenId] == nil: "Auction has been created";
                AvatarArtAuction.nftStartPrices[tokenId] != nil && 
                AvatarArtAuction.nftStartPrices[tokenId]! == 0.0:
                    "Can not create new auction";
                self.nfts[tokenId] != nil: "User does not own NFT";
            }
            var startPrice = price;
            if(AvatarArtAuction.firstSolds[tokenId] == false){
                startPrice = AvatarArtAuction.nftStartPrices[tokenId]!;
            }

            self.auctionInfos[tokenId] = AuctionItem(
                startTime: startTime, 
                endTime: endTime,
                startPrice: startPrice);

            self.auctionings[tokenId] = true;

            emit NewAuctionCreated(tokenId: tokenId, startTime: startTime, endTime: endTime, startPrice: startPrice);
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

        pub fun place(
            tokenId: UInt64,
            price: UFix64,
            affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>?,
            placeUserTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            placeUserAuctionNftReceiver: Capability<&{AuctionNFTReceiver}>,
            token: @FungibleToken.Vault){
            pre{
                self.auctionInfos[tokenId] != nil: "Auction has not been created";
                self.auctionings[tokenId] == true: "NFT is not auctioned";
                AvatarArtAuction.paymentTypes[tokenId] != nil: "Payment type has not been set";
                token.isInstance(AvatarArtAuction.paymentTypes[tokenId]!) : "Payment token is not accepted";
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
            auction.winnerAuctionNftReceiver = placeUserAuctionNftReceiver;
            auction.affiliateTokenReceiver = affiliateTokenReceiver;
            auction.lastPrice = price;
            self.auctionInfos[tokenId] = auction;

            emit NewPlace(tokenId: tokenId, price: price, user: userAddress, time: getCurrentBlock().timestamp);
        }

        pub fun distribute(
            tokenId: UInt64,
            feeReference: Capability<&{AvatarArtTransactionInfo.PublicFeeInfo}>,
            feeRecepientReference: Capability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>){
            pre{
                self.auctionInfos[tokenId] != nil: "Auction has not been created";
            }

            var auction = self.auctionInfos[tokenId] ?? panic("Auction has not existed");
            assert(getCurrentBlock().timestamp > auction.endTime, message: "Auction has not ended");

            AvatarArtAuction.nftStartPrices[tokenId] = 0.0;

            var winnerAddress: Address? = nil;
            if(auction.winnerVaultReceiver != nil){
                winnerAddress = auction.winnerVaultReceiver!.address;
                //Deposit nft to winner auction resource
                let nft <- self.nfts.remove(key: tokenId)!;
                auction.winnerAuctionNftReceiver!.borrow()!.deposit(nft: <- nft);
                  
                let fee = feeReference.borrow()!.getFee(tokenId: tokenId)!;
                let feeRecepient = feeRecepientReference.borrow()!.getAddress(tokenId: tokenId)!;

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

                self.ownerVaultReceiver.borrow()!.deposit(from: <-tokenVault);
            }else{
                winnerAddress = self.ownerVaultReceiver.address;
            }

            //Remove resources
            self.auctionInfos.remove(key: tokenId);
            AvatarArtAuction.firstSolds[tokenId] = true;
            self.auctionings[tokenId] = false;

            emit Distributed(tokenId: tokenId, user: winnerAddress!);
        }

        pub fun deposit(nft: @AvatarArtNFT.NFT){
            pre{
                AvatarArtAuction.nftStartPrices[nft.id]! == 0.0: "Can not deposit nft"; 
            }
            let olfNft <- self.nfts.insert(key: nft.id, <- nft);
            destroy  olfNft;
        }

        pub fun withdrawNFT(tokenId: UInt64): @AvatarArtNFT.NFT{
            pre{
                AvatarArtAuction.withdrawables[tokenId] == true:
                    "Can not withdraw NFT";
                self.nfts[tokenId] != nil: "NFT has not existed";
            }

            AvatarArtAuction.nftStartPrices.remove(key: tokenId);
            AvatarArtAuction.withdrawables.remove(key: tokenId);
            AvatarArtAuction.firstSolds.remove(key: tokenId);
            self.auctionings.remove(key: tokenId);
            return <- self.nfts.remove(key: tokenId)!;
        }

        init(
            ownerVaultReceiver: Capability<&{FungibleToken.Receiver}>,
            ownerNftReceiver: Capability<&{NonFungibleToken.Receiver}>){
            self.auctionInfos = {};
            self.keptVaults <- {};
            self.nfts <- {};
            self.auctionings = {};
            self.ownerVaultReceiver = ownerVaultReceiver;
            self.ownerNftReceiver = ownerNftReceiver;
        }

        destroy() {
            destroy self.keptVaults;
            destroy self.nfts;
        }
    }

    pub resource Administrator{
        pub fun setNftPrice(tokenId: UInt64, startPrice: UFix64){
            pre{
                AvatarArtAuction.nftStartPrices[tokenId] == nil: "Can not set price";
            }
            AvatarArtAuction.nftStartPrices[tokenId] = startPrice;
        }

        pub fun setPaymentType(tokenId: UInt64, paymentType: Type){
            AvatarArtAuction.paymentTypes[tokenId] = paymentType;
        }

        pub fun setPriceStep(price: UFix64, priceStep: UFix64){
            AvatarArtAuction.priceSteps[price] = priceStep;
        }

        pub fun allowUserToWithdraw(tokenId: UInt64){
            AvatarArtAuction.withdrawables[tokenId] = true;
        }
    }

    pub fun createNewAuction(
        ownerVaultReceiver: Capability<&{FungibleToken.Receiver}>,
        ownerNftReceiver: Capability<&{NonFungibleToken.Receiver}>): @Auction{
        return <- create Auction(
            ownerVaultReceiver: ownerVaultReceiver,
            ownerNftReceiver: ownerNftReceiver);
    }
    
    init(){
        self.AuctionStoragePath = /storage/avatarArtAdminAuction;
        self.AuctionPublicPath = /public/avatarArtAdminAuction;
        self.AdminStoragePath = /storage/avatarArtAuctionAdmin;

        self.nftStartPrices = {};
        self.paymentTypes = {};
        self.priceSteps = {};
        self.withdrawables = {};
        self.firstSolds = {};

        self.account.save(<- create Administrator(), to: self.AdminStoragePath);
    }
}