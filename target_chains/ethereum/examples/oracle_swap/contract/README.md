# Oracle Based Swap

## Introduction
This Swap's functionality and implementation is similar to UniswapV2 Pool but using oracle price feed instead of the formula `x * y = k` for price calculation;
## Contract Explanation
The OracleLP Contract inherits major functions in OracleSwap and also inherits ERC20 for governing the supply of the LP token to depositors as an incentive.\
In the following explanation, consider the 2 tokens in the pool as Token A and Token B for simplicity, and their prices as P<sub>A</sub> and P<sub>B</sub>

## Features

### 1. Add liquidity
- Depositor can only add one token T, either A or B per contract call, take adding n token A as an example.
- If the pool is empty, depositor can get (P<sub>A</sub> * n) LP Tokens 
- Else depositor can get S<sub>total</sub> * (P<sub>A</sub> * n) / [P<sub>A</sub> * A + P<sub>B</sub> * B] LP Tokens (Which is Total LP supply * proportion of new deposit value )
### 2. Remove Liquidity
- Withdrawer can only remove one token T, either A or B per contract call, take token A as an example for n LP tokens.
- Let number of token A withdrawer can get back be x
- Consider S<sub>total</sub> / n = (P<sub>A</sub> * A + P<sub>B</sub> * B) / x * P<sub>A</sub>
- x = n/S<sub>total</sub> * (P<sub>A</sub> * A + P<sub>B</sub> * B) / P<sub>A</sub>
- `if x > A, x = A else x = x`
### 3. Incentivize for depositing token
- With reference to UniswapV2 design, fee charged for each transaction is 0.3%
- Consider the case where user wants to swap from A to B
- When there is no fee, P<sub>A</sub> * A = P<sub>B</sub> * B, Token B he can get = P<sub>A</sub> / P<sub>B</sub> * A
- After adding fee, Token B he can get = P<sub>A</sub> / P<sub>B</sub> * A * (1-0.3%)

## Deployments
### Network: Polygon Mumbai (ChainId: 80001)
- OracleLP: <a href="https://mumbai.polygonscan.com/address/0xa344b3595DE91e3eD9a3CaE5a6B5A5B85048dF45">0xa344b3595DE91e3eD9a3CaE5a6B5A5B85048dF45</a>
- PythSetUp: <a href="https://mumbai.polygonscan.com/address/0xd3F09663590a889E9Abe13EFBBe43FF84253de6E">0xd3F09663590a889E9Abe13EFBBe43FF84253de6E</a>
- MockPyth: <a href="https://mumbai.polygonscan.com/address/0x512a04598f44671bb5b9a37b069c1a06508fddb9">0x512a04598f44671bB5B9A37B069C1A06508FDDb9</a>

### Contract Functionalities
- OracleLP:
    - Main Contract for handling deposit withdraw and swapping
- PythSetUp: 
    - Helper contract for facilitating the usage of Pyth Contract
    - Getting the price update fee and do the update
- MockPyth:
    - Mock contract for handling price of the base and quote token