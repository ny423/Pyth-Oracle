import Web3 from "web3";
import { FC } from "react";
import { withdraw } from "../../contracts/oracleLp";

type WithdrawButtonProps = {
    web3: Web3,
    sender: string,
    isBase: boolean,
    amount: number,
};

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