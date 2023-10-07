import Web3 from "web3";
import { FC } from "react";
import { withdraw } from "../../contracts/oracleLp";
import { ComponentProps } from "../../types";

type WithdrawButtonProps = {
    isBase: boolean,
    amount: number,
} & ComponentProps;

export const WithdrawAllButton: FC<WithdrawButtonProps> = (
    { web3, sender, isBase, amount }
) => {
    return <button
        onClick={async () => {
            const result = await withdraw(web3, sender,
                isBase, amount);
            console.log("🚀 ~ file: DepositButton.tsx:21 ~ onClick={ ~ result:", result)
        }}>
        Withdraw all
    </button>
};