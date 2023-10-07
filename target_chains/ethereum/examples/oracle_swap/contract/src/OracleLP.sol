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
    IPyth public pyth;
    bytes32 public baseTokenPriceId;
    bytes32 public quoteTokenPriceId;

    ERC20 public baseToken;
    ERC20 public quoteToken;

    bool public empty = true;
    uint8 public constant PRICE_DECIMALS = 18;

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

    function getCurrentPrices() public view returns (uint, uint) {
        PythStructs.Price memory currentBasePrice = pyth.getPriceUnsafe(
            baseTokenPriceId
        );
        PythStructs.Price memory currentQuotePrice = pyth.getPriceUnsafe(
            quoteTokenPriceId
        );

        uint256 basePrice = convertToUint(currentBasePrice, PRICE_DECIMALS);
        uint256 quotePrice = convertToUint(currentQuotePrice, PRICE_DECIMALS);
        return (basePrice, quotePrice);
    }

    function getPoolCurrentTotalValue(
        uint256 basePrice,
        uint256 quotePrice
    ) public view returns (uint256) {
        return ((baseBalance() * basePrice) + (quoteBalance() * quotePrice));
    }

    event Deposit(bool isBase, uint256 amount, uint256 price);

    // * size: amount of target token
    function deposit(bool isBase, uint256 size) external returns (uint) {
        // require(size > MIN_DEPOSIT_SIZE, "OracleLP: INSUFFICIENT DEPOSIT SIZE");
        (uint256 basePrice, uint256 quotePrice) = getCurrentPrices();

        uint256 currentPrice; // getting current price of token

        if (isBase) currentPrice = basePrice;
        else currentPrice = quotePrice;

        emit Deposit(isBase, size, currentPrice);

        uint256 totalValue = currentPrice * size;
        uint256 currentTotalValue = getPoolCurrentTotalValue(
            basePrice,
            quotePrice
        );
        if (empty) {
            mint(msg.sender, totalValue);
            empty = false;
        } else {
            mint(msg.sender, (totalSupply() * totalValue) / currentTotalValue);
        }

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
        return totalValue;
    }

    event Withdraw(
        bool isBase,
        uint256 sizeOfLP,
        uint256 price,
        uint256 returnAmount
    );

    // * size = amount of LP token, returns number of token sent to user
    function withdraw(
        bool isBase,
        uint256 size
    ) external returns (uint256, bool) {
        if (empty) {
            return (0, false);
        }
        (uint256 basePrice, uint256 quotePrice) = getCurrentPrices();
        uint256 totalValue = getPoolCurrentTotalValue(basePrice, quotePrice);
        uint256 returnAmount;
        bool exceed = false;
        if (isBase) {
            returnAmount = (size * totalValue) / basePrice / totalSupply();
            if (returnAmount > baseBalance()) {
                returnAmount = baseBalance();
                size = (returnAmount * totalSupply() * basePrice) / totalValue;
            }
            // transfer return amount of base token to withdrawer
            // burn corresponsing amount of LP token
            burn(msg.sender, size);
            baseToken.approve(address(this), returnAmount);
            require(
                baseToken.transferFrom(address(this), msg.sender, returnAmount)
            );
            emit Withdraw(isBase, size, basePrice, returnAmount);
        } else {
            returnAmount = (size * totalValue) / quotePrice / totalSupply();
            if (returnAmount > quoteBalance()) {
                returnAmount = quoteBalance();
                size = (returnAmount * totalSupply() * quotePrice) / totalValue;
            }
            // transfer return amount of quote token to withdrawer
            // burn corresponsing amount of LP token
            burn(msg.sender, size);
            quoteToken.approve(address(this), returnAmount);
            require(
                quoteToken.transferFrom(address(this), msg.sender, returnAmount)
            );
            emit Withdraw(isBase, size, quotePrice, returnAmount);
        }
        if (baseBalance() == 0 && quoteBalance() == 0) {
            empty = true;
        }
        return (returnAmount, exceed);
    }

    /*
     * Buy: get <size> base token
     * Sell: pay <size> base token
     */
    function swap(bool isBuy, uint256 size) external {
        (uint256 basePrice, uint256 quotePrice) = getCurrentPrices();

        // This computation loses precision. The infinite-precision result is between [quoteSize, quoteSize + 1]
        // We need to round this result in favor of the contract.
        uint256 quoteSize = (size * basePrice) / quotePrice;

        // TODO: use confidence interval

        if (isBuy) {
            // (Round up)
            quoteSize += 1;

            require(
                quoteToken.transferFrom(msg.sender, address(this), quoteSize)
            );
            baseToken.approve(address(this), (size * 997) / 1000);
            require(baseToken.transfer(msg.sender, (size * 997) / 1000)); // * 0.997 for 0.003 charged for fee
        } else {
            require(baseToken.transferFrom(msg.sender, address(this), size));
            quoteToken.approve(address(this), (quoteSize * 997) / 1000);
            require(quoteToken.transfer(msg.sender, (quoteSize * 997) / 1000));
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

    event Mint(uint256 amount);

    function mint(address account, uint256 amount) internal {
        emit Mint(amount);
        _mint(account, amount);
    }

    event Burn(uint256 amount);

    function burn(address account, uint256 amount) internal {
        emit Burn(amount);
        _burn(account, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 36;
    }

    receive() external payable {}
}
