import { address as foundryAddress } from "../contracts/deploys/mercurial.31337.address.json";
import { abi as foundryAbi } from "../contracts/deploys/mercurial.31337.compilerOutput.json";
import { address as goerliAddress } from "../contracts/deploys/mercurial.5.address.json";
import { abi as goerliAbi } from "../contracts/deploys/mercurial.5.compilerOutput.json";

interface Deployments {
  [chainId: string]: {
    address: string;
    abi: any;
  };
}

export const deployments: Deployments = {
  31337: {
    address: foundryAddress,
    abi: foundryAbi,
  },
  5: {
    address: goerliAddress,
    abi: goerliAbi,
  }
};

