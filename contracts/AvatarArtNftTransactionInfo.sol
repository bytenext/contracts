// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./core/Ownable.sol";
import "./interfaces/IAvatarArtNftTransactionInfo.sol";

/**
* @dev Store transaction fee for marketplace and auction
* There are alot of fee types when a NFT is bought and sold: 
*   Affiliate fee, storing fee, insurance fee, contractors fee, platform fee, author fee and the remaining is for seller
*  These fees is applied for separated NFT not for all NFT
*/
contract AvatarArtNftTransactionInfo is Ownable, IAvatarArtNftTransactionInfo{
    uint256 constant override public MULTIPLIER = 1000;

    //Mapping NFT tokenId and fee info
    mapping(uint256 => FeeInfo) public _feeInfos;

    //Mapping NFT tokenId and fee receipents
    mapping(uint256 => FeeReceipentAddress) public  _feeReceipentAddresses;

    //Mapping NFT tokenId and payment token address
    mapping(uint256 => address) override public _paymentTokenAddresses;

    mapping(uint256 => uint256) override public _floorPrices;

    address override public _avatarArtPlatformAddress;

    constructor(address avatarArtPlatformAddress){
        _avatarArtPlatformAddress = avatarArtPlatformAddress;
    }

    /**
    * @dev See {IAvatarArtNftFee.setAuthorAddress(tokenId, authorAddress);}
    */
    function setFeeReceipentAddresses(uint256 tokenId, address storing, address insurance, address contractor, address author) external override onlyOwner {
        _feeReceipentAddresses[tokenId].storing = storing;
        _feeReceipentAddresses[tokenId].insurance = insurance;
        _feeReceipentAddresses[tokenId].contractor = contractor;
        _feeReceipentAddresses[tokenId].author = author;
    }

    function setAvatarArtPlatformAddress(address avatarArtPlatformAddress) external onlyOwner {
        _avatarArtPlatformAddress = avatarArtPlatformAddress;
    }

    /**
    * @dev See {IAvatarArtNftFee.setPaymentTokenAddress(tokenId, paymentTokenAddress);}
    */
    function setPaymentTokenAddress(uint256 tokenId, address paymentTokenAddress) external override onlyOwner {
        _paymentTokenAddresses[tokenId] = paymentTokenAddress;
    }

    /**
    * @dev See {IAvatarArtNftFee.setFee(tokenId, affiliate, storing, insurance, contractor, platform, author);}
     */
    function setFee(uint256 tokenId, uint256 affiliate, uint256 storing, uint256 insurance, uint256 contractor, uint256 platform, uint256 author) external override onlyOwner {
        require(affiliate + storing + insurance + contractor + platform + author < 100 * MULTIPLIER, "Percent is greater than 100");
        _feeInfos[tokenId] = FeeInfo({
            affiliate:affiliate,
            storing:storing,
            insurance:insurance,
            contractor:contractor,
            platform:platform,
            author:author
        });
    }
    
    /**
    * @dev See {IAvatarArtNftFee.getFee(tokenId);}
    */
    function getFee(uint256 tokenId) external override view returns(FeeInfo memory){
            return _feeInfos[tokenId];
    }

    /**
    * @dev See {IAvatarArtNftFee.getFeeReceipentAddresses(tokenId);}
    */
    function getFeeReceipentAddresses(uint256 tokenId) external override view returns(FeeReceipentAddress memory){
            return _feeReceipentAddresses[tokenId];
    }
}