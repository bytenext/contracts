// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./IByteNextFactory.sol";
import "./ByteNextLibrary.sol";
import "./IWBNB.sol";

contract ByteNextRouter{
    uint256 public constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    address public factory;
    address public WBNB;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "outdate");
        _;
    }

    constructor(address _factory, address _WBNB) {
        factory = _factory;
        WBNB = _WBNB;
    }

    receive() external payable {
        assert(msg.sender == WBNB); // only accept ETH via fallback from the WBNB contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IByteNextFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IByteNextFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = ByteNextLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = ByteNextLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'INS_B');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = ByteNextLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'INS_A');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ByteNextLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IByteNextPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WBNB,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = ByteNextLibrary.pairFor(factory, token, WBNB);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWBNB(WBNB).deposit{value: amountETH}();
        assert(IWBNB(WBNB).transfer(pair, amountETH));
        liquidity = IByteNextPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = ByteNextLibrary.pairFor(factory, tokenA, tokenB);
        IByteNextPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IByteNextPair(pair).burn(to);
        (address token0,) = ByteNextLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'INS_A');
        require(amountB >= amountBMin, 'INS_B');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WBNB,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWBNB(WBNB).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // function addLiquidityFromSingleToken(
    //     address paymentToken,
    //     uint256 paymentAmount,
    //     address[] memory pathToTokenA,
    //     address[] memory pathToTokenB,
    //     address tokenA,
    //     address tokenB,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
    //     if(payment)



    //     (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    //     address pair = ByteNextLibrary.pairFor(factory, tokenA, tokenB);
    //     TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    //     TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    //     liquidity = IByteNextPair(pair).mint(to);
    // }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = ByteNextLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? ByteNextLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IByteNextPair(ByteNextLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = ByteNextLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INS_OUT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ByteNextLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = ByteNextLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'EXCESSIVE_IN');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ByteNextLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WBNB, 'INV_PATH');
        amounts = ByteNextLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INS_OUT');
        IWBNB(WBNB).deposit{value: amounts[0]}();
        assert(IWBNB(WBNB).transfer(ByteNextLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WBNB, 'INV_PATH');
        amounts = ByteNextLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'EXCESSIVE_IN');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ByteNextLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWBNB(WBNB).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WBNB, 'INV_PATH');
        amounts = ByteNextLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INS_OUT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ByteNextLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWBNB(WBNB).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WBNB, 'INV_PATH');
        amounts = ByteNextLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'EXCESSIVE_IN');
        IWBNB(WBNB).deposit{value: amounts[0]}();
        assert(IWBNB(WBNB).transfer(ByteNextLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure returns (uint amountB) {
        return ByteNextLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        returns (uint amountOut)
    {
        return ByteNextLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        returns (uint amountIn)
    {
        return ByteNextLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        returns (uint[] memory amounts)
    {
        return ByteNextLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        returns (uint[] memory amounts)
    {
        return ByteNextLibrary.getAmountsIn(factory, amountOut, path);
    }
}