import AvatarArtTransactionInfo from 0x01

pub fun main(tokenId: UInt64) {
    let publicAccount = getAccount(0x01)

    let transactionAddressReference = publicAccount.getCapability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>(AvatarArtTransactionInfo.TransactionAddressCapabilityPublicPath)
                            .borrow()
                            ?? panic("Could not borrow a reference to the hello capability");

    log(transactionAddressReference.getAddress(tokenId: tokenId));
}