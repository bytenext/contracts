// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IByteNextLaunchpad{
    /**
    * @dev User join to IDO with specific project and pay `paymentAmount` to buy project token
    * @param paymentAmount Payment token amount used to buy project token
    */
    function join(uint256 paymentAmount) external returns(bool);

    /**
    * @dev User claims project token when IDO ends
    */
    function claim() external returns(bool);
}