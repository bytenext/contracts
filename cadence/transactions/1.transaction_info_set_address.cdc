//import AvatarArtTransactionInfo from "./contracts/AvatarArtTransactionInfo.cdc"

import AvatarArtTransactionInfo from 0x01

transaction(tokenId: UInt64, storing: Address, insurance: Address, contractor: Address, platform: Address, author: Address) {

    let transactionAddressReference: &AvatarArtTransactionInfo.TransactionAddress;

    prepare(adminAccount: AuthAccount) {
        self.transactionAddressReference = adminAccount.borrow<&AvatarArtTransactionInfo.TransactionAddress>(
            from: AvatarArtTransactionInfo.TransactionAddressStoragePath)
            ?? panic("could not borrow minter reference");
    }

    execute{
        self.transactionAddressReference.setAddress(
            tokenId: tokenId,
            storing: storing,
            insurance: insurance,
            contractor: contractor,
            platform: platform,
            author: author
        );
        log("Address setted");
    }
}