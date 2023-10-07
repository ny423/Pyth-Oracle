export const CONFIG = {
    // Each token is configured with its ERC20 contract address and Pyth Price Feed ID.
    // You can find the list of price feed ids at https://pyth.network/developers/price-feed-ids
    // Note that feeds have different ids on testnet / mainnet.
    baseToken: {
        name: "BRL",
        erc20Address: "0xB3a2EDFEFC35afE110F983E32Eb67E671501de1f",
        pythPriceFeedId:
            "0x000000000000000000000000000000000000000000000000000000000000abcd",
        decimals: 18,
    },
    quoteToken: {
        name: "USD",
        erc20Address: "0x8C65F3b18fB29D756d26c1965d84DBC273487624",
        pythPriceFeedId:
            "0x0000000000000000000000000000000000000000000000000000000000001234",
        decimals: 18,
    },
    // swapContractAddress: "0x15F9ccA28688F5E6Cbc8B00A8f33e8cE73eD7B02",
    lpContractAddress: "0x69802b7a40b2cd833ba494c2eb1e6962738a370e",
    lpTokenDecimals: 18,
    pythContractAddress: "0x512a04598f44671bB5B9A37B069C1A06508FDDb9",
    priceServiceUrl: "https://xc-testnet.pyth.network",
    mintQty: 100,
    depositQty: 25,
};