import AvatarArtTransactionInfo from 0x01

pub fun main(tokenId: UInt64) {
    let publicAccount = getAccount(0x01)

    let feeInfoReference = publicAccount.getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath)
                            .borrow()
                            ?? panic("Could not borrow a reference to the hello capability");

    log(feeInfoReference.getFee(tokenId: tokenId));
}