// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "pyth-sdk-solidity/IPyth.sol";
import "pyth-sdk-solidity/PythStructs.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 ** Buy: deposit quoteToken to this, withdraw baseToken
 ** Sell: deposit baseToken to this, withdraw quoteToken
 */
contract OracleLP is ERC20 {
    IPyth pyth;
    bytes32 baseTokenPriceId;
    bytes32 quoteTokenPriceId;

    ERC20 public baseToken;
    ERC20 public quoteToken;

    bool empty;
    uint constant MIN_DEPOSIT_SIZE = 10 ** 8;

    constructor(
        address _pyth,
        bytes32 _baseTokenPriceId,
        bytes32 _quoteTokenPriceId,
        address _baseToken,
        address _quoteToken
    ) ERC20("OracleLiquidityPool", "OLP") {
        pyth = IPyth(_pyth);
        baseTokenPriceId = _baseTokenPriceId;
        quoteTokenPriceId = _quoteTokenPriceId;
        baseToken = ERC20(_baseToken);
        quoteToken = ERC20(_quoteToken);
    }

    function getCurrentPrices() public payable returns (uint, uint) {
        PythStructs.Price memory currentBasePrice = pyth.getPrice(
            baseTokenPriceId
        );
        PythStructs.Price memory currentQuotePrice = pyth.getPrice(
            quoteTokenPriceId
        );

        uint256 basePrice = convertToUint(currentBasePrice, 18);
        uint256 quotePrice = convertToUint(currentQuotePrice, 18);
        return (basePrice, quotePrice);
    }

    function getPoolCurrentTotalValue() public view returns (uint) {
        uint256 basePrice = convertToUint(pyth.getPrice(baseTokenPriceId), 18);
        uint256 quotePrice = convertToUint(
            pyth.getPrice(quoteTokenPriceId),
            18
        );
        return baseBalance() * basePrice + quoteBalance() + quotePrice;
    }

    // * size: amount of target token
    function deposit(bool isBase, uint size) external returns (uint) {
        require(size > MIN_DEPOSIT_SIZE, "OracleLP: INSUFFICIENT DEPOSIT SIZE");
        if (isBase)
            require(
                baseToken.transferFrom(msg.sender, address(this), size),
                "OracleLP: TRANSFER TOKEN FAILURE"
            );
        else
            require(
                quoteToken.transferFrom(msg.sender, address(this), size),
                "OracleLP: TRANSFER TOKEN FAILURE"
            );
        (uint basePrice, uint quotePrice) = getCurrentPrices();

        uint256 currentPrice; // getting current price of token
        if (isBase) currentPrice = basePrice;
        else currentPrice = quotePrice;

        uint totalValue = currentPrice * size;
        if (empty) {
            mint(msg.sender, totalValue);
        } else {
            mint(
                msg.sender,
                (totalSupply() * totalValue) / (getPoolCurrentTotalValue())
            );
        }
        return totalValue;
    }

    // * size amount of LP token
    function withdraw(bool isBase, uint size) external returns (uint) {
        (uint basePrice, uint quotePrice) = getCurrentPrices();
        uint256 returnAmount;
        if (isBase) {
            returnAmount =
                ((size / totalSupply()) * getPoolCurrentTotalValue()) /
                basePrice;
            if (returnAmount > baseBalance()) {
                returnAmount = baseBalance();
                size =
                    (returnAmount * totalSupply() * basePrice) /
                    getPoolCurrentTotalValue();
            }
            // transfer return amount of base token to withdrawer
            // burn corresponsing amount of LP token
            burn(msg.sender, size);
            baseToken.transferFrom(address(this), msg.sender, returnAmount);
        } else {
            returnAmount =
                ((size / totalSupply()) * getPoolCurrentTotalValue()) /
                quotePrice;
            if (returnAmount > quoteBalance()) {
                returnAmount = quoteBalance();
                size =
                    (returnAmount * totalSupply() * quotePrice) /
                    getPoolCurrentTotalValue();
            }
            // transfer return amount of quote token to withdrawer
            // burn corresponsing amount of LP token
            burn(msg.sender, size);
            quoteToken.transferFrom(address(this), msg.sender, returnAmount);
        }
        if (getPoolCurrentTotalValue() == 0) {
            empty = true;
        }
        return returnAmount;
    }

    function swap(bool isBuy, uint size) external {
        (uint basePrice, uint quotePrice) = getCurrentPrices();

        // This computation loses precision. The infinite-precision result is between [quoteSize, quoteSize + 1]
        // We need to round this result in favor of the contract.
        uint256 quoteSize = (size * basePrice) / quotePrice;

        // TODO: use confidence interval

        if (isBuy) {
            // (Round up)
            quoteSize += 1;

            quoteToken.transferFrom(msg.sender, address(this), quoteSize);
            baseToken.transfer(msg.sender, (size * 997) / 1000); // * 0.997 for 0.003 charged for fee
        } else {
            baseToken.transferFrom(msg.sender, address(this), size);
            quoteToken.transfer(msg.sender, (quoteSize * 997) / 1000);
        }
    }

    // TODO: we should probably move something like this into the solidity sdk
    function convertToUint(
        PythStructs.Price memory price,
        uint8 targetDecimals
    ) private pure returns (uint256) {
        if (price.price < 0 || price.expo > 0 || price.expo < -255) {
            revert();
        }

        uint8 priceDecimals = uint8(uint32(-1 * price.expo));

        if (targetDecimals >= priceDecimals) {
            return
                uint(uint64(price.price)) *
                10 ** uint32(targetDecimals - priceDecimals);
        } else {
            return
                uint(uint64(price.price)) /
                10 ** uint32(priceDecimals - targetDecimals);
        }
    }

    // Get the number of base tokens in the pool
    function baseBalance() public view returns (uint256) {
        return baseToken.balanceOf(address(this));
    }

    // Get the number of quote tokens in the pool
    function quoteBalance() public view returns (uint256) {
        return quoteToken.balanceOf(address(this));
    }

    // Send all tokens in the oracle AMM pool to the caller of this method.
    // (This function is for demo purposes only. You wouldn't include this on a real contract.)
    function withdrawAll() external {
        baseToken.transfer(msg.sender, baseToken.balanceOf(address(this)));
        quoteToken.transfer(msg.sender, quoteToken.balanceOf(address(this)));
    }

    // Reinitialize the parameters of this contract.
    // (This function is for demo purposes only. You wouldn't include this on a real contract.)
    function reinitialize(
        bytes32 _baseTokenPriceId,
        bytes32 _quoteTokenPriceId,
        address _baseToken,
        address _quoteToken
    ) external {
        baseTokenPriceId = _baseTokenPriceId;
        quoteTokenPriceId = _quoteTokenPriceId;
        baseToken = ERC20(_baseToken);
        quoteToken = ERC20(_quoteToken);
    }

    function mint(address account, uint amount) internal {
        _mint(account, amount);
    }

    function burn(address account, uint amount) internal {
        _burn(account, amount);
    }

    receive() external payable {}
}
