// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IFeeInfo{
    //Store fee infor for NFT. Fee is calculated by percent and multipled by 1000
    struct FeeInfo{
        uint256 affiliate;
        uint256 storing;
        uint256 insurance;
        uint256 contractor;
        uint256 platform;
        uint256 author;
    }

    struct FeeReceipentAddress{
        address storing;
        address insurance;
        address contractor;
        address author;
    }
}