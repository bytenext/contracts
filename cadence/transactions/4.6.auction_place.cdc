import FungibleToken from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtTransactionInfo from 0x02
import BNU from 0x01
import AvatarArtAuction from 0x04

transaction (tokenId: UInt64, price: UFix64, sellerAddress: Address, affiliateAddress: Address?){
    let auctionRef: &AvatarArtAuction.Auction;
    let sellerRef: &{AvatarArtAuction.AuctionPublic};

    let tokenVault: &BNU.Vault;
    let placeUserTokenReceiver: Capability<&{FungibleToken.Receiver}>;
    let placeUserAuctionNftReceiver: Capability<&{AvatarArtAuction.AuctionNFTReceiver}>;

    prepare(userAccount: AuthAccount) {
        let sellerAccount = getAccount(sellerAddress);
        self.sellerRef = sellerAccount.getCapability<&{AvatarArtAuction.AuctionPublic}>(AvatarArtAuction.AuctionPublicPath)
              .borrow() ?? panic("Can not borrow seller's AvatarArtAuction.AuctionPublic");

        self.auctionRef = userAccount
                    .borrow<&AvatarArtAuction.Auction>(from: AvatarArtAuction.AuctionStoragePath)
                    ?? panic("Can not borrow Auction capability");

        self.tokenVault = userAccount.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
                ?? panic("Can not borrow token vault capability");

        self.placeUserTokenReceiver = userAccount
                .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        self.placeUserAuctionNftReceiver = userAccount
                .getCapability<&{AvatarArtAuction.AuctionNFTReceiver}>(AvatarArtAuction.AuctionPublicPath);
    }

    execute {
        let token <- self.tokenVault.withdraw(amount: price);
        var affiliateTokenReceiver: Capability<&{FungibleToken.Receiver}>? = nil;
        if(affiliateAddress != nil){
           affiliateTokenReceiver = getAccount(affiliateAddress!)
                  .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        }
     
        self.sellerRef.place(
            tokenId: tokenId,
            price: price,
            affiliateTokenReceiver: affiliateTokenReceiver,
            placeUserTokenReceiver: self.placeUserTokenReceiver,
            placeUserAuctionNftReceiver: self.placeUserAuctionNftReceiver,
            token: <- token);
        
        log("New place is setted");
    }
}