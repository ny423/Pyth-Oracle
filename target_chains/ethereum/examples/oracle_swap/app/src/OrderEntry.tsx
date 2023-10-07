import React, { FC, useEffect, useState } from "react";
import "./App.css";
import Web3 from "web3";
import { BigNumber } from "ethers";
import { TokenConfig, numberToTokenQty, tokenQtyToNumber } from "./utils/utils";
import { approveToken, getApprovedQuantity } from "./contracts/erc20";
import { swap } from "./contracts/oracleLp";

/**
 * The order entry component lets users enter a quantity of the base token to buy/sell and submit
 * the transaction to the blockchain.
 */

type OrderEntryProps = {
  web3: Web3 | undefined;
  account: string | null;
  isBuy: boolean;
  approxPrice: number | undefined;
  baseToken: TokenConfig;
  quoteToken: TokenConfig;
  swapContractAddress: string;
}

export const OrderEntry: FC<OrderEntryProps> = ({
  web3, account, isBuy, approxPrice, baseToken, quoteToken, swapContractAddress }) => {
  const [qty, setQty] = useState<string>("1");
  const [qtyBn, setQtyBn] = useState<BigNumber | undefined>(
    BigNumber.from("1")
  );
  const [authorizedQty, setAuthorizedQty] = useState<BigNumber>(
    BigNumber.from("0")
  );
  const [isAuthorized, setIsAuthorized] = useState<boolean>(false);

  const [spentToken, setSpentToken] = useState<TokenConfig>(baseToken);
  const [approxQuoteSize, setApproxQuoteSize] = useState<number | undefined>(
    undefined
  );

  useEffect(() => {
    if (isBuy) {
      setSpentToken(quoteToken);
    } else {
      setSpentToken(baseToken);
    }
  }, [isBuy, baseToken, quoteToken]);

  useEffect(() => {
    async function helper() {
      if (web3 !== undefined && account !== null) {
        setAuthorizedQty(
          await getApprovedQuantity(
            web3!,
            spentToken.erc20Address,
            account!,
            swapContractAddress
          )
        );
      } else {
        setAuthorizedQty(BigNumber.from("0"));
      }
    }

    helper();
    const interval = setInterval(helper, 3000);

    return () => {
      clearInterval(interval);
    };
  }, [web3, account, swapContractAddress, spentToken]);

  useEffect(() => {
    try {
      const qtyBn = numberToTokenQty(qty, baseToken.decimals);
      setQtyBn(qtyBn);
    } catch (error) {
      setQtyBn(undefined);
    }
  }, [baseToken.decimals, qty]);

  useEffect(() => {
    if (qtyBn !== undefined) {
      setIsAuthorized(authorizedQty.gte(qtyBn));
    } else {
      setIsAuthorized(false);
    }
  }, [qtyBn, authorizedQty]);

  useEffect(() => {
    if (qtyBn !== undefined && approxPrice !== undefined) {
      setApproxQuoteSize(
        tokenQtyToNumber(qtyBn, baseToken.decimals) * approxPrice
      );
    } else {
      setApproxQuoteSize(undefined);
    }
  }, [approxPrice, baseToken.decimals, qtyBn]);

  return (
    <div>
      <div>
        <p>
          {isBuy ? "Buy" : "Sell"}
          <input
            type="text"
            name="base"
            value={qty}
            onChange={(event) => {
              setQty(event.target.value);
            }}
          />
          {baseToken.name}
        </p>
        {qtyBn !== undefined && approxQuoteSize !== undefined ? (
          isBuy ? (
            <p>
              Pay {approxQuoteSize.toFixed(3)} {quoteToken.name} to
              receive{" "}
              {tokenQtyToNumber(qtyBn, baseToken.decimals).toFixed(3)}{" "}
              {baseToken.name}
            </p>
          ) : (
            <p>
              Pay {tokenQtyToNumber(qtyBn, baseToken.decimals).toFixed(3)}{" "}
              {baseToken.name} to receive {approxQuoteSize.toFixed(3)}{" "}
              {quoteToken.name}
            </p>
          )
        ) : (
          <p>Transaction details are loading...</p>
        )}
      </div>

      <div className={"swap-steps"}>
        {account === null || web3 === undefined ? (
          <div>Connect your wallet to swap</div>
        ) : (
          <div>
            1.{" "}
            <button
              onClick={async () => {
                await approveToken(
                  web3!,
                  spentToken.erc20Address,
                  account!,
                  swapContractAddress
                );
              }}
              disabled={isAuthorized}
            >
              {" "}
              Approve{" "}
            </button>
            2.
            <button
              onClick={async () => {
                await swap(web3, account, isBuy, Number(qty));
              }}
              disabled={!isAuthorized}
            >
              {" "}
              Submit{" "}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
