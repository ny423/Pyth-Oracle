#!/bin/bash -e

# URL of the ethereum RPC node to use. Choose this based on your target network
# (e.g., this deploys to goerli optimism testnet)
RPC_URL="https://polygon-mumbai.infura.io/v3/2b4858332bd44d9098c06176da95b024"

# The address of the Pyth contract on your network. See the list of contract addresses here https://docs.pyth.network/documentation/pythnet-price-feeds/evm
PYTH_CONTRACT_ADDRESS="0x512a04598f44671bB5B9A37B069C1A06508FDDb9"
# The Pyth price feed ids of the base and quote tokens. The list of ids is available here https://pyth.network/developers/price-feed-ids
# Note that each feed has different ids on mainnet and testnet.
BASE_FEED_ID="0x000000000000000000000000000000000000000000000000000000000000abcd"
QUOTE_FEED_ID="0x0000000000000000000000000000000000000000000000000000000000001234"
# The address of the base and quote ERC20 tokens.
BASE_ERC20_ADDR="0xB3a2EDFEFC35afE110F983E32Eb67E671501de1f"
QUOTE_ERC20_ADDR="0x8C65F3b18fB29D756d26c1965d84DBC273487624"

PUBLIC_KEY="0xf642E421e81Bc42dC87E5833B5A69715999d49Df"
PRIVATE_KEY="bb8a3b933c94a7b6957e440d6ef853a4e6f31187ad14bace0c5d685bdacbf08e"

POLYGON_SCAN_API="YUGWA6ZP18V1X78ZBU1AYAY1FX5M7658NA"

# Note the -l here uses a ledger wallet to deploy your contract. You may need to change this
# option if you are using a different wallet.
forge create ./src/OracleLP.sol:OracleLP\
  --rpc-url $RPC_URL\
  --private-key $PRIVATE_KEY\
  --etherscan-api-key $POLYGON_SCAN_API \
  --verify \
  --constructor-args \
  $PYTH_CONTRACT_ADDRESS\
  $BASE_FEED_ID\
  $QUOTE_FEED_ID\
  $BASE_ERC20_ADDR\
  $QUOTE_ERC20_ADDR