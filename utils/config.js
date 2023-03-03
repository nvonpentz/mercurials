import { address as foundryAddress } from "../contracts/deploys/mercurial.31337.address.json";
import { abi as foundryAbi } from "../contracts/deploys/mercurial.31337.compilerOutput.json";
// import { goerliAddress } from "../contracts/deploys/mercurial.5.address.json";
// import { goerliAbi } from "../contracts/deploys/mercurial.5.compilerOutput.json";
// import { mainnetAddress } from "../contracts/deploys/mercurial.1.address.json";
// import { mainnetAbi } from "../contracts/deploys/mercurial.1.compilerOutput.json";

export const deployments = {
  31337: {
    address: foundryAddress,
    abi: foundryAbi,
  },
  // 5: {
  //   address: goerliAddress,
  //   abi: goerliAbi,
  // },
  // 1: {
  //   address: mainnetAddress,
  //   abi: mainnetAbi,
  // },
};
