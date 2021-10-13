import FungibleToken from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtTransactionInfo from 0x01
import BNU from 0x01
import AvatarArtAuction from 0x02

// This transaction allows the Minter account to mint an NFT
// and deposit it into its collection.

transaction (tokenId: UInt64, price: UFix64, affiliateAddress: Address?){
    let auctionRef: &{AvatarArtAuction.AuctionPublic};

    let tokenVault: &BNU.Vault;
    let tokenVaultReceiver: Capability<&{FungibleToken.Receiver}>;
    let nftReceiver: Capability<&{NonFungibleToken.Receiver}>;

    prepare(account: AuthAccount) {
        let adminPublicAccount = getAccount(0x02);
        self.auctionRef = adminPublicAccount
                .getCapability<&{AvatarArtAuction.AuctionPublic}>(AvatarArtAuction.AuctionPublicPath)
                .borrow() ?? panic("Can not borrow admin auction capability");

        self.tokenVault = account.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
                ?? panic("Can not borrow token vault capability");

        self.tokenVaultReceiver = account
                .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        self.nftReceiver = account
                .getCapability<&{NonFungibleToken.Receiver}>(AvatarArtNFT.ReceiverPublicPath);
    }

    execute {
        let token <- self.tokenVault.withdraw(amount: price);

        if(affiliateAddress == nil){
            self.auctionRef.place(
            tokenId: tokenId,
            price: price,
            affiliateTokenReceiver: nil,
            placeUserTokenReceiver: self.tokenVaultReceiver,
            placeUserNftReceiver: self.nftReceiver,
            token: <- token);
        }else{
            let affiliateTokenReceiver = getAccount(affiliateAddress!)
                  .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
            self.auctionRef.place(
            tokenId: tokenId,
            price: price,
            affiliateTokenReceiver: affiliateTokenReceiver,
            placeUserTokenReceiver: self.tokenVaultReceiver,
            placeUserNftReceiver: self.nftReceiver,
            token: <- token);
        }

        log("New place has been setted");
    }
}