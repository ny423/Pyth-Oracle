import Web3 from "web3";
import { FC } from "react";
import { deposit } from "../../contracts/oracleLp";

type DepositButtonProps = {
    web3: Web3,
    sender: string,
    isBase: boolean,
    amount: number,
};

export const DepositButton: FC<DepositButtonProps> = (
    { web3, sender, isBase, amount }
) => {
    return <button
        onClick={async () => {
            // if (isBase)
            //     await approveToken(web3, CONFIG.baseToken.erc20Address, sender, CONFIG.lpContractAddress);
            // if (!isBase)
            //     await approveToken(web3, CONFIG.quoteToken.erc20Address, sender, CONFIG.lpContractAddress);
            const result = await deposit(web3, sender,
                isBase, amount);
            console.log("🚀 ~ file: DepositButton.tsx:21 ~ onClick={ ~ result:", result)
        }}>
        Deposit {amount}
    </button>
};