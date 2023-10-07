import Web3 from "web3";
import { FC } from "react";
import { deposit } from "../../contracts/oracleLp";
import { ComponentProps } from "../../types";

type DepositButtonProps = {
    isBase: boolean,
    amount: number,
} & ComponentProps;

export const DepositButton: FC<DepositButtonProps> = (
    { web3, sender, isBase, amount }
) => {
    return <button
        onClick={async () => {
            const result = await deposit(web3, sender,
                isBase, amount);
            console.log("🚀 ~ file: DepositButton.tsx:21 ~ onClick={ ~ result:", result)
        }}>
        Deposit {amount}
    </button>
};