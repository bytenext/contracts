import VnMiss from "./VnMiss.cdc"
import VnMissCandidate from "./VnMissCandidate.cdc"
import NonFungibleToken from "../core/NonFungibleToken.cdc"

pub contract VnMissSwap {
    pub var endAt: UFix64?
    pub let additional: { UInt64: { VnMiss.Level: UInt64 } }

    pub let AdminStoragePath: StoragePath

    pub event SwapForNFT(from: [UInt64], to: UInt64, recipient: Address, candidateID: UInt64)

    pub fun levelAsString(level: VnMiss.Level): String {
        switch level {
            case VnMiss.Level.Bronze:
                return "Bronze"

            case VnMiss.Level.Diamond:
                return "Silver"

            case VnMiss.Level.Diamond:
                return "Diamond"
        }

        return  ""
    }

    pub fun swapNFTForNFT(list: @[VnMiss.NFT; 5], target: @VnMiss.NFT, recipient: Capability<&{NonFungibleToken.CollectionPublic}>) {
        assert(self.endAt == nil || self.endAt! <= getCurrentBlock().timestamp, message: "Not open")
        assert(list.length == 5, message: "Should input 5 nft")

        let receiver = recipient.borrow() ?? panic("Collection broken")

        var i = 0
        var level: VnMiss.Level = VnMiss.Level.Diamond
        let from: [UInt64] = []
        while i < list.length {
            let ref = &list[i] as &VnMiss.NFT
            from.append(ref.id)
            if ref.level.rawValue < level.rawValue {
                level = ref.level
            }

            i = i + 1
        }

        let targetId = target.id
        let candidateID = target.candidateID
        let minted = self.additional[candidateID]!
        minted[level] = minted[level] ?? 195 + 1
        self.additional[candidateID] = minted

        let minter = self.account.borrow<&VnMiss.NFTMinter>(from: VnMiss.MinterStoragePath)
                            ?? panic("Can not borrow")
        let c = VnMissCandidate.getCandidate(id: candidateID)!
        minter.mintNFT(
            recipient: receiver,
            candidateID: candidateID,
            level: level,
            name: c.buildName(level: self.levelAsString(level: level), id: minted[level]!),
            thumbnail: target.thumbnail
        )
        receiver.deposit(token: <- target)

        emit  SwapForNFT(from: from, to: targetId, recipient: recipient.address, candidateID: candidateID)

        destroy list
    }

    pub resource Admin {
        pub fun setEndAt(endAt: UFix64) {
            VnMissSwap.endAt = endAt
        }
    }

    init() {
        self.endAt = nil
        self.additional = {}

        self.AdminStoragePath = /storage/BNMUVnMissSwap
        self.account.save(<- create Admin(), to: self.AdminStoragePath)
    }
}