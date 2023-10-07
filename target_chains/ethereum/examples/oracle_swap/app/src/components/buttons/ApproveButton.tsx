import { FC } from "react";
import { CONFIG } from "../../config";
import { approveToken } from "../../contracts/erc20";
import { ComponentProps } from "../../types";

type ApproveButtonProps = {
    isBase: boolean,
    amount?: number,
} & ComponentProps;

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