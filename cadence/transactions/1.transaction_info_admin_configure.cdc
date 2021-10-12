//import AvatarArtTransactionInfo from "./contracts/AvatarArtTransactionInfo.cdc"

import AvatarArtTransactionInfo from 0x01

transaction(tokenId: UInt64,
    storingAddress: Address, insuranceAddress: Address, contractorAddress: Address, platformAddress: Address, authorAddress: Address,
    storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64
    ) {

    let transactionAddressReference: &AvatarArtTransactionInfo.TransactionAddress;
    let feeInfoReference: &AvatarArtTransactionInfo.FeeInfo;

    prepare(adminAccount: AuthAccount) {
        self.transactionAddressReference = adminAccount.borrow<&AvatarArtTransactionInfo.TransactionAddress>(
            from: AvatarArtTransactionInfo.TransactionAddressStoragePath)
            ?? panic("could not borrow minter reference");

        self.feeInfoReference = adminAccount.borrow<&AvatarArtTransactionInfo.FeeInfo>(
            from: AvatarArtTransactionInfo.FeeInfoStoragePath)
            ?? panic("could not borrow minter reference");
    }

    execute{
        self.transactionAddressReference.setAddress(
            tokenId: tokenId,
            storing: storingAddress,
            insurance: insuranceAddress,
            contractor: contractorAddress,
            platform: platformAddress,
            author: authorAddress
        );

        self.feeInfoReference.setFee(
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