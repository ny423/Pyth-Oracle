import OracleLPAbi from '../abi/OracleLPAbi.json';
import { getContract, numberToTokenQty } from '../utils/utils';
import Web3 from 'web3';
import { CONFIG } from '../config';

const deposit = async (web3: Web3, sender: string,
    isBase: boolean, amount: number) => {
    const contract = getContract(web3, OracleLPAbi, CONFIG.lpContractAddress);
    const quantity = numberToTokenQty(amount, CONFIG.baseToken.decimals);
    return await contract.methods.deposit(isBase, quantity)
        .send({ from: sender });
}

const withdraw = async (web3: Web3, sender: string, isBase: boolean, size: number) => {
    const contract = getContract(web3, OracleLPAbi, CONFIG.lpContractAddress);
    const quantity = numberToTokenQty(size, CONFIG.lpTokenDecimals);
    return await contract.methods.withdraw(isBase, quantity)
        .send({ from: sender });
}

const swap = async (web3: Web3, sender: string, isBuy: boolean, size: number) => {
    const contract = getContract(web3, OracleLPAbi, CONFIG.lpContractAddress);
    const quantity = numberToTokenQty(size, CONFIG.baseToken.decimals);
    return await contract.methods.swap(isBuy, quantity)
        .send({ from: sender });
}

type getCurrentPricesRes = {
    0: string,
    1: string,
};

const getCurrentPrices = async (web3: Web3): Promise<getCurrentPricesRes> => {
    const contract = getContract(web3, OracleLPAbi, CONFIG.lpContractAddress);
    return await contract.methods.getCurrentPrices().call();
}
export { deposit, withdraw, swap, getCurrentPrices };