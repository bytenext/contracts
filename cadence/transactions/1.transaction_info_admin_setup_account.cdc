
//import AvatarArtTransactionInfo from "./contracts/AvatarArtTransactionInfo.cdc"

import AvatarArtTransactionInfo from 0x01
transaction {

    prepare(userAccount: AuthAccount) {
        userAccount.link<&{AvatarArtTransactionInfo.PublicFeeInfo}>(
        AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath,
        target: AvatarArtTransactionInfo.FeeInfoStoragePath);

        userAccount.link<&{AvatarArtTransactionInfo.PublicTransactionAddress}>(
        AvatarArtTransactionInfo.TransactionAddressCapabilityPublicPath,
        target: AvatarArtTransactionInfo.TransactionAddressStoragePath);
    }
}