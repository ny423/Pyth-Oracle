import Web3 from "web3";
import { numberToTokenQty } from "../../utils/utils";
import { mint } from "../../contracts/erc20";
import { ComponentProps } from "../../types";

export function MintButton(props: {
  erc20Address: string;
  destination: string;
  qty: number;
  decimals: number;
} & ComponentProps) {
  return (
    <button
      onClick={async () => {
        await mint(
          props.web3,
          props.sender,
          props.erc20Address,
          props.destination,
          numberToTokenQty(props.qty, props.decimals)
        );
      }}
    >
      Mint {props.qty}
    </button>
  );
}
