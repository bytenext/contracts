pub contract AvatarArtTransactionInfo {
    pub let FeeInfoStoragePath: StoragePath;
    pub let FeeInfoPublicPath: PublicPath;
    pub let FeeInfoCapabilityPublicPath: PublicPath;

    pub let TransactionAddressStoragePath: StoragePath;
    pub let TransactionAddressPublicPath: PublicPath;
    pub let TransactionAddressCapabilityPublicPath: PublicPath;

    pub event FeeUpdated(tokenId: UInt64, affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64);
    pub event TransactionAddressUpdated(tokenId: UInt64, storing: Address, insurance: Address, contractor: Address, platform: Address, author: Address);
    

    pub struct FeeInfoItem{
        pub let affiliate: UFix64;
        pub let storing: UFix64;
        pub let insurance: UFix64;
        pub let contractor: UFix64;
        pub let platform: UFix64;
        pub let author: UFix64;

        // initializer
        init (_affiliate: UFix64, _storing: UFix64, _insurance: UFix64, _contractor: UFix64, _platform: UFix64, _author: UFix64) {
            self.affiliate = _affiliate;
            self.storing = _storing;
            self.insurance = _insurance;
            self.contractor = _contractor;
            self.platform = _platform;
            self.author = _author;
        }
    }

    pub resource interface PublicFeeInfo{
        pub fun getFee(tokenId: UInt64): FeeInfoItem?;
    }

    pub resource FeeInfo : PublicFeeInfo{
        //Store fee for each NFT
        pub var fees: {UInt64: FeeInfoItem};

        pub fun setFee(tokenId: UInt64, affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64){
            pre{
                tokenId > 0: "tokenId parameter is zero";
            }

            self.fees[tokenId] = FeeInfoItem(
                _affiliate: affiliate,
                _storing: storing,
                _insurance: insurance,
                _contractor: contractor,
                _platform: platform,
                _author: author);

            emit FeeUpdated(tokenId: tokenId, affiliate: affiliate, storing: storing, insurance: insurance, contractor: contractor, platform: platform, author: author);
        }

        pub fun getFee(tokenId: UInt64): FeeInfoItem?{
            pre{
                tokenId > 0: "tokenId parameter is zero";
            }

            return self.fees[tokenId];
        }

        // initializer
        init () {
            self.fees = {};
        }

        // destructor
        destroy() {
            //Do nothing
        }
    }
    
    pub struct TransactionAddressItem{
        pub let storing: Address;
        pub let insurance: Address;
        pub let contractor: Address;
        pub let platform: Address;
        pub let author: Address;

        // initializer
        init (_storing: Address, _insurance: Address, _contractor: Address, _platform: Address, _author: Address) {
            self.storing = _storing;
            self.insurance = _insurance;
            self.contractor = _contractor;
            self.platform = _platform;
            self.author = _author;
        }
    }

    pub resource interface PublicTransactionAddress{
        pub fun getAddress(tokenId: UInt64): TransactionAddressItem?;
    }

    pub resource TransactionAddress : PublicTransactionAddress{
        //Store fee for each NFT
        pub var addresses: {UInt64: TransactionAddressItem};

        pub fun setAddress(tokenId: UInt64, storing: Address, insurance: Address, contractor: Address, platform: Address, author: Address){
            pre{
                tokenId > 0: "tokenId parameter is zero";
            }

            self.addresses[tokenId] = TransactionAddressItem(
                _storing: storing,
                _insurance: insurance,
                _contractor: contractor,
                _platform: platform,
                _author: author);

            emit TransactionAddressUpdated(tokenId: tokenId, storing: storing, insurance: insurance, contractor: contractor, platform: platform, author: author);
        }

        pub fun getAddress(tokenId: UInt64): TransactionAddressItem?{
            pre{
                tokenId > 0: "tokenId parameter is zero";
            }

            return self.addresses[tokenId];
        }

        // initializer
        init () {
            self.addresses = {};
        }

        // destructor
        destroy() {
            //Do nothing
        }
    }

    init(){
        self.FeeInfoStoragePath = /storage/feeInfo;
        self.FeeInfoPublicPath = /public/feeInfo;
        self.FeeInfoCapabilityPublicPath = /public/feeInfoCapability;

        self.TransactionAddressStoragePath = /storage/transactionAddress;
        self.TransactionAddressPublicPath = /public/transactionAddress;
        self.TransactionAddressCapabilityPublicPath = /public/transactionAddress;

        let feeInfo <- create FeeInfo();
        self.account.save(<- feeInfo, to: self.FeeInfoStoragePath);

        self.account.link<&{AvatarArtTransactionInfo.PublicFeeInfo}>(
            AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath,
            target: AvatarArtTransactionInfo.FeeInfoStoragePath);

        let transactionAddress <- create TransactionAddress();
        self.account.save(<- transactionAddress, to: self.TransactionAddressStoragePath);

        self.account.link<&{AvatarArtTransactionInfo.PublicTransactionAddress}>(
            AvatarArtTransactionInfo.TransactionAddressCapabilityPublicPath,
            target: AvatarArtTransactionInfo.TransactionAddressStoragePath);
    }
}