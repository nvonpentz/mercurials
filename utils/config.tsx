const foundryAddress = require("../contracts/deploys/mercurial.31337.address.json").address;
const foundryAbi = require("../contracts/deploys/mercurial.31337.compilerOutput.json").abi;
const goerliAddress = require("../contracts/deploys/mercurial.5.address.json").address;
const goerliAbi = require("../contracts/deploys/mercurial.5.compilerOutput.json").abi;

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
