import { address as foundryAddress } from "../contracts/deploys/mercurials.31337.address.json";
import { abi as foundryAbi } from "../contracts/deploys/mercurials.31337.compilerOutput.json";
import { address as goerliAddress } from "../contracts/deploys/mercurials.5.address.json";
import { abi as goerliAbi } from "../contracts/deploys/mercurials.5.compilerOutput.json";
import { address as polygonAddress } from "../contracts/deploys/mercurials.137.address.json";
import { abi as polygonAbi } from "../contracts/deploys/mercurials.137.compilerOutput.json";

export const deployments = {
  31337: {
    address: foundryAddress,
    abi: foundryAbi,
  },
  5: {
    address: goerliAddress,
    abi: goerliAbi,
  },
  137: {
    address: polygonAddress,
    abi: polygonAbi,
  },
};
