
import AvatarArtMarketplace from 0x03

transaction(tokenId: UInt64, price: UFix64) {
    let adminReference: &AvatarArtMarketplace.Administrator
    prepare(adminAccount: AuthAccount) {
        assert(tokenId > 0,message: "tokenId parameter is invalid");

        self.adminReference = adminAccount.borrow<&AvatarArtMarketplace.Administrator>(from: AvatarArtMarketplace.AdminStoragePath)
            ?? panic("Can not borrow AvatarArtMarketplace.Administrator");
    }

    execute{
        self.adminReference.setNftPrice(tokenId: tokenId, price: price);
    }

    post{
        AvatarArtMarketplace.getNftPrice(tokenId: tokenId) == price:
            "NFT price is not set";
    }
}