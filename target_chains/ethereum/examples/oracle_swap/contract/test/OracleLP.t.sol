// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/OracleLP.sol";
import "pyth-sdk-solidity/MockPyth.sol";
import "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

contract OracleLPTest is Test {
    MockPyth public mockPyth;

    bytes32 constant BASE_PRICE_ID =
        0x000000000000000000000000000000000000000000000000000000000000abcd;
    bytes32 constant QUOTE_PRICE_ID =
        0x0000000000000000000000000000000000000000000000000000000000001234;

    ERC20Mock baseToken;
    address payable constant BASE_TOKEN_MINT =
        payable(0x0000000000000000000000000000000000000011);
    ERC20Mock quoteToken;
    address payable constant QUOTE_TOKEN_MINT =
        payable(0x0000000000000000000000000000000000000022);

    OracleLP public lp;

    address payable constant DUMMY_TO =
        payable(0x0000000000000000000000000000000000000055);

    uint256 MAX_INT = 2 ** 256 - 1;

    function setUp() public {
        // Creating a mock of Pyth contract with 60 seconds validTimePeriod (for staleness)
        // and 1 wei fee for updating the price.
        mockPyth = new MockPyth(60, 1);

        baseToken = new ERC20Mock(
            "Foo token",
            "FOO",
            BASE_TOKEN_MINT,
            1000 * 10 ** 18
        );
        quoteToken = new ERC20Mock(
            "Bar token",
            "BAR",
            QUOTE_TOKEN_MINT,
            1000 * 10 ** 18
        );

        lp = new OracleLP(
            address(mockPyth),
            BASE_PRICE_ID,
            QUOTE_PRICE_ID,
            address(baseToken),
            address(quoteToken)
        );
    }

    function setupTokens(uint senderBaseQty, uint senderQuoteQty) private {
        baseToken.mint(address(this), senderBaseQty);
        quoteToken.mint(address(this), senderQuoteQty);
    }

    function depositTokens(uint size, bool isBase) public {
        baseToken.approve(address(lp), MAX_INT);
        quoteToken.approve(address(lp), MAX_INT);
        lp.deposit(isBase, size);
    }

    function withdrawTokens(uint size, bool isBase) public {
        lp.withdraw(isBase, size);
    }

    function setPrices(int32 basePrice, int32 quotePrice) private {
        bytes[] memory updateData = new bytes[](2);
        updateData[0] = mockPyth.createPriceFeedUpdateData(
            BASE_PRICE_ID,
            basePrice * 100000,
            10 * 100000,
            -5,
            basePrice * 100000,
            10 * 100000,
            uint64(block.timestamp)
        );
        updateData[1] = mockPyth.createPriceFeedUpdateData(
            QUOTE_PRICE_ID,
            quotePrice * 100000,
            10 * 100000,
            -5,
            quotePrice * 100000,
            10 * 100000,
            uint64(block.timestamp)
        );

        uint value = mockPyth.getUpdateFee(updateData);
        vm.deal(address(this), value);
        mockPyth.updatePriceFeeds{value: value}(updateData);
    }

    function doSwap(bool isBuy, uint size) private {
        baseToken.approve(address(lp), MAX_INT);
        quoteToken.approve(address(lp), MAX_INT);
        lp.swap(isBuy, size);
    }

    // heler function copied from main contract
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

    function testInitialDeposit() public returns (uint256) {
        setupTokens(20e18, 20e18);

        uint amount = 10e18;
        setPrices(10, 1);
        depositTokens(amount, true); // deposit 10e18 base token

        assertEq(baseToken.balanceOf(address(this)), 20e18 - amount);
        assertEq(baseToken.balanceOf(address(lp)), amount);
        uint256 expectedLP = convertToUint(
            mockPyth.getPrice(BASE_PRICE_ID),
            18
        ) * amount;
        emit log("Supply of LP");
        emit log_uint(lp.totalSupply());
        emit log("ExpectedLP: ");
        emit log_uint(expectedLP);
        emit log("ActualLP:");
        emit log_uint(lp.balanceOf(address(this)));
        assertEq(lp.balanceOf(address(this)), expectedLP);
        return expectedLP;
    }

    function testSecondDeposit() public returns (uint256) {
        uint256 currentLP = testInitialDeposit();

        uint amount = 5e18;
        setPrices(10, 1);

        depositTokens(amount, false); // deposit 5e18 quote token

        assertEq(quoteToken.balanceOf(address(this)), 20e18 - amount);
        assertEq(quoteToken.balanceOf(address(lp)), amount);
        uint256 expectedLP = convertToUint(
            mockPyth.getPrice(QUOTE_PRICE_ID),
            18
        ) * amount;
        assertEq(lp.balanceOf(address(this)), currentLP + expectedLP);
        return currentLP + expectedLP;
    }

    function testSwap() public {
        setupTokens(20e18, 20e18);

        doSwap(true, 1e18);

        assertEq(quoteToken.balanceOf(address(this)), 10e18 - 1);
        assertEq(baseToken.balanceOf(address(this)), 21e18);

        doSwap(false, 1e18);

        assertEq(quoteToken.balanceOf(address(this)), 20e18 - 1);
        assertEq(baseToken.balanceOf(address(this)), 20e18);
    }

    // function testWithdraw() public {
    //     setupTokens(10e18, 10e18);

    //     swap.withdrawAll();

    //     assertEq(quoteToken.balanceOf(address(this)), 20e18);
    //     assertEq(baseToken.balanceOf(address(this)), 20e18);
    //     assertEq(quoteToken.balanceOf(address(swap)), 0);
    //     assertEq(baseToken.balanceOf(address(swap)), 0);
    // }

    receive() external payable {}
}
