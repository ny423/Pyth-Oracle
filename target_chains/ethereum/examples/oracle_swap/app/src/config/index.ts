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
    lpContractAddress: "0xa344b3595DE91e3eD9a3CaE5a6B5A5B85048dF45",
    lpTokenDecimals: 36,
    pythContractAddress: "0x512a04598f44671bB5B9A37B069C1A06508FDDb9",
    priceServiceUrl: "https://xc-testnet.pyth.network",
    mintQty: 100,
    depositQty: 25,
};