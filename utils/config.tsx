const mainnetAddress = require("../contracts/deploys/mercurials.1.address.json").address;
const mainnetAbi = require("../contracts/deploys/mercurials.1.compilerOutput.json").abi;
// const hardhatAddress = require("../contracts/deploys/mercurials.31337.address.json").address;
// const hardhatAbi = require("../contracts/deploys/mercurials.31337.compilerOutput.json").abi;
const goerliAddress = require("../contracts/deploys/mercurials.5.address.json").address;
const goerliAbi = require("../contracts/deploys/mercurials.5.compilerOutput.json").abi;

interface Deployments {
  [chainId: string]: {
    address: string;
    abi: any;
  };
}

export const deployments: Deployments = {
  1: {
    address: mainnetAddress,
    abi: mainnetAbi,
  },
  // 31337: {
  //   address: hardhatAddress,
  //   abi: hardhatAbi,
  // },
  5: {
    address: goerliAddress,
    abi: goerliAbi,
  },
};
