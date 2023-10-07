import Web3 from "web3";
import { FC } from "react";
import { CONFIG } from "../../config";
import { approveToken } from "../../contracts/erc20";

type ApproveButtonProps = {
    web3: Web3,
    sender: string,
    isBase: boolean,
    amount?: number,
};

export const ApproveButton: FC<ApproveButtonProps> = (
    { web3, sender, isBase, amount }
) => {
    return <button
        onClick={async () => {
            if (isBase)
                await approveToken(web3, CONFIG.baseToken.erc20Address, sender, CONFIG.lpContractAddress);
            if (!isBase)
                await approveToken(web3, CONFIG.quoteToken.erc20Address, sender, CONFIG.lpContractAddress);
        }}>
        Approve {amount ? amount : "All"}
    </button>
};