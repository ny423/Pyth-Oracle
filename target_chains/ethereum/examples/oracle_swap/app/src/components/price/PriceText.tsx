import { FC, useEffect, useState } from "react";
import { ExchangeRateMeta, timeAgo, TokenConfig } from "../../utils/utils";
import { getCurrentPrices } from "../../contracts/oracleLp";
import Web3 from "web3";
import { BigNumber } from "ethers";


type PriceTextProps = {
  baseToken: TokenConfig;
  quoteToken: TokenConfig;
};

type Prices = {
  base: BigNumber,
  quote: BigNumber,
};
/**
 * Show the current exchange rate with a tooltip for pyth prices.
 */
export const PriceText: FC<PriceTextProps> = ({
  baseToken, quoteToken,
}) => {

  const [priceInfo, setPriceInfo] = useState<Prices>({
    base: BigNumber.from(1), quote: BigNumber.from(1) // default price 1: 1
  });
  useEffect(() => {
    const readPriceInfo = async () => {
      const web3 = new Web3("https://polygon-mumbai.infura.io/v3/2b4858332bd44d9098c06176da95b024");
      const prices = await getCurrentPrices(web3);
      setPriceInfo({ base: BigNumber.from(prices[0]), quote: BigNumber.from(prices[1]) })
    };

    const interval = setInterval(async () => {
      readPriceInfo();
    }, 3000);  // Call every 3 seconds

    return () => clearInterval(interval);  // Clean up on unmount
  }, []);

  return (
    <div>
      Price of {baseToken.name}/{quoteToken.name}: {priceInfo.base.div(priceInfo.quote).toNumber()}
    </div>
  );
}
