// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IByteNextFactory.sol";
import "./IByteNextPair.sol";
import "./IByteNextERC20.sol";
import "./ByteNextPair.sol";

contract ByteNextFactory is IByteNextFactory {
    bytes32 public constant override INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(ByteNextPair).creationCode));

    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor() {
        feeToSetter = msg.sender;
        feeTo = msg.sender;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'ByteNext: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ByteNext: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'ByteNext: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ByteNextPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IByteNextPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'ByteNext: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'ByteNext: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}