CTOR_ARGS=0x000000000000000000000000ff1a0f4744e8582df1ae09d5611b887b6a12925c08f781a893bc9340140c5f89c8a96f438bcfae4d1474cc0f688e3a52892c73181fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588000000000000000000000000b3a2edfefc35afe110f983e32eb67e671501de1f0000000000000000000000008c65f3b18fb29d756d26c1965d84dbc273487624
PYTH_CONTRACT_ADDRESS="0x512a04598f44671bB5B9A37B069C1A06508FDDb9"
# The Pyth price feed ids of the base and quote tokens. The list of ids is available here https://pyth.network/developers/price-feed-ids
# Note that each feed has different ids on mainnet and testnet.
BASE_FEED_ID="0x000000000000000000000000000000000000000000000000000000000000abcd"
QUOTE_FEED_ID="0x0000000000000000000000000000000000000000000000000000000000001234"
# The address of the base and quote ERC20 tokens.
BASE_ERC20_ADDR="0xB3a2EDFEFC35afE110F983E32Eb67E671501de1f"
QUOTE_ERC20_ADDR="0x8C65F3b18fB29D756d26c1965d84DBC273487624"

forge verify-contract \
  --chain-id 80001 \
  --constructor-args $(cast abi-encode "constructor(address,bytes32,bytes32,address,address)" \
  "0x512a04598f44671bB5B9A37B069C1A06508FDDb9" \
  "0x000000000000000000000000000000000000000000000000000000000000abcd" \
  "0x0000000000000000000000000000000000000000000000000000000000001234" \
  "0xB3a2EDFEFC35afE110F983E32Eb67E671501de1f" \
  "0x8C65F3b18fB29D756d26c1965d84DBC273487624" \
  ) \
  --etherscan-api-key YUGWA6ZP18V1X78ZBU1AYAY1FX5M7658NA \
  --compiler-version v0.8.4+commit.c7e474f2 \
  0xFa682a72e18835202fA0916FFF535082a331a90E \
  src/OracleLP.sol:OracleLP

forge verify-check --chain-id 80001 efeqiaibiqzxfrjiwqw2eeyp6f1snbysv2jtms9hriiddgxvma YUGWA6ZP18V1X78ZBU1AYAY1FX5M7658NA

forge verify-contract \
  --chain-id 80001 \
  --constructor-args $(cast abi-encode "constructor(address)" \
  "0x512a04598f44671bB5B9A37B069C1A06508FDDb9" \
  ) \
  --etherscan-api-key YUGWA6ZP18V1X78ZBU1AYAY1FX5M7658NA \
  --compiler-version v0.8.4+commit.c7e474f2 \
  0xd3F09663590a889E9Abe13EFBBe43FF84253de6E \
  src/PythSetUp.sol:PythSetUp

forge verify-check --chain-id 80001 <GUID> -e YUGWA6ZP18V1X78ZBU1AYAY1FX5M7658NA

forge verify-contract \
  --chain-id 80001 \
  --constructor-args $(cast abi-encode "constructor(uint,uint)" \
  60, 1 \
  ) \
  --etherscan-api-key YUGWA6ZP18V1X78ZBU1AYAY1FX5M7658NA \
  --compiler-version v0.8.4+commit.c7e474f2 \
  0x512a04598f44671bB5B9A37B069C1A06508FDDb9 \
  lib/pyth-sdk-solidity/MockPyth.sol:MockPyth

forge verify-check --chain-id 80001 <GUID> -e YUGWA6ZP18V1X78ZBU1AYAY1FX5M7658NA