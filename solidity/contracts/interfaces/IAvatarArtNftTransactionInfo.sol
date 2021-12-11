// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IFeeInfo.sol";

interface IAvatarArtNftTransactionInfo is IFeeInfo{
    /**
    * @dev Get multiplier for fee
    **/
    function MULTIPLIER() external returns(uint256);

    /**
    * @dev Get _author address of specific NFT tokenId
    **/
    function getFeeReceipentAddresses(uint256 tokenId) external view returns(FeeReceipentAddress memory);

    /**
    * @dev Get payment token address of specific NFT tokenId
    **/
    function _paymentTokenAddresses(uint256 tokenId) external view returns(address);

    /**
    * @dev Get avatarArt platform address
    **/
    function _avatarArtPlatformAddress() external view returns(address);

    /**
    * @dev Get floor price percent of specific NFT tokenId
    **/
    function _floorPrices(uint256 tokenId) external view returns(uint256);

    /**
    * @dev Get fee info of specific NFT tokenId
    **/
    function getFee(uint256 tokenId) external view returns(FeeInfo memory);

    /**
    * @dev Set fee receipents of specific NFT tokenId
    **/
    function setFeeReceipentAddresses(uint256 tokenId, address storing, address insurance, address contractor, address author) external;

    /**
    * @dev Set payment token address of specific NFT tokenId
    **/
    function setPaymentTokenAddress(uint256 tokenId, address paymentTokenAddress) external;

    /**
    * @dev Set fee info of specific NFT tokenId
    **/
    function setFee(uint256 tokenId, uint256 affiliate, uint256 storing, uint256 insurance, uint256 contractor, uint256 platform, uint256 author) external;
}