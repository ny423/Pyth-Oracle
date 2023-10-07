// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "pyth-sdk-solidity/MockPyth.sol";

contract PythSetUp {
    MockPyth public mockPyth;
    address payable public owner;

    bytes32 constant BASE_PRICE_ID =
        0x000000000000000000000000000000000000000000000000000000000000abcd;
    bytes32 constant QUOTE_PRICE_ID =
        0x0000000000000000000000000000000000000000000000000000000000001234;

    constructor(address mockPythAddress) {
        mockPyth = MockPyth(mockPythAddress);
        owner = payable(msg.sender); // Set the owner to the address that deployed the contract.
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the contract owner can withdraw");
        owner.transfer(address(this).balance);
    }

    // A payable function can receive Ether.
    function deposit() public payable {
        // `msg.value` contains the amount of Ether sent in the transaction.
        require(msg.value > 0, "You must send some Ether");
    }

    function getUpdateFee(
        int32 basePrice,
        int32 quotePrice
    ) public view returns (uint256) {
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
        return mockPyth.getUpdateFee(updateData);
    }

    function setPrices(int32 basePrice, int32 quotePrice) public payable {
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
        mockPyth.updatePriceFeeds{value: value}(updateData);
    }

    receive() external payable {}
}
