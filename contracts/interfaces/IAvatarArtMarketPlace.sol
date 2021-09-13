// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAvatarArtMarketplace{
    /**
     * @dev User that created sell order can cancel that order
     */ 
    function cancelSellOrder(uint256 tokenId) external returns(bool);
    
    /**
     * @dev Create a sell order to sell NFT
     */
    function createSellOrder(uint tokenId, uint price) external returns(bool);
    
    /**
     * @dev User purchases a NFT
     */ 
    function purchase(uint tokenId, address affiliate) external returns(uint);
}