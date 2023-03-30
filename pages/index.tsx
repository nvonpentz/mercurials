import type { NextPage } from "next";
import Head from "next/head";
import styles from "../styles/Home.module.css";
import {
  useAccount,
  useBlockNumber,
  useContractRead,
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
  useNetwork,
} from "wagmi";
import Image from "next/image";
import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { Result } from "ethers/lib/utils";
import { deployments } from "../utils/config";
import ExpiresIn from "../components/ExpiresIn/ExpiresIn";
import Navbar from "../components/Navbar/Navbar";
import MintButton from "../components/MintButton/MintButton";
import TokenInfo from "../components/TokenInfo/TokenInfo";
import TransactionInfo from "../components/TransactionInfo/TransactionInfo";

const Home: NextPage = () => {
  // State
  const [address, setAddress] = useState(deployments[chain?.id]?.address);
  const [abi, setAbi] = useState(deployments[chain?.id]?.abi);

  // Hooks
  const { isConnected } = useAccount();
  const { chain = { id: 5 } } = useNetwork();
  useEffect(() => {
    setAddress(deployments[chain?.id]?.address);
    setAbi(deployments[chain?.id]?.abi);
  }, [chain]);
  const { data: blockNumber } = useBlockNumber();
  const { data: nextToken, isFetching: readIsFetching } = useContractRead({
    address: address,
    abi: abi,
    functionName: "nextToken",
    args: [],
    overrides: {
      blockTag: "pending",
    },
    watch: true,
  }) as { data: Result; isFetching: boolean };
  const { config, error: prepareWriteError } = usePrepareContractWrite({
    address: address,
    abi: abi,
    args: [nextToken?.[0], nextToken?.[3]],
    functionName: "mint",
    overrides: {
      gasLimit: ethers.BigNumber.from(5000000),
      value: nextToken?.[2],
    },
  });

  const {
    data: writeData,
    error: writeError,
    isError: isWriteError,
    isLoading: isWriteLoading,
    write,
  } = useContractWrite(config);

  const {
    data: receipt,
    error: waitForTransactionError,
    isFetching: waitIsFetching,
  } = useWaitForTransaction({
    hash: writeData?.hash,
  });

  return (
    <div className={styles.container}>
      <div className={styles.column}>
        <Head>
          <title>Mercurials - NFT</title>
          <meta name="description" content="TODO" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <link rel="icon" href="/favicon.ico" />
        </Head>
        <Navbar chainId={chain.id} address={address} />
        <main className={styles.main}>
          <h1>Mercurial #{nextToken?.[0].toString()}</h1>
          <TokenInfo blockNumber={blockNumber} nextToken={nextToken} />
          <div className={styles.tokenImage}>
            {nextToken && (
              <div dangerouslySetInnerHTML={{ __html: nextToken[1] }} />
            )}
          </div>
          <div></div>{" "}
          <div className={styles.buttonContainer}>
            <MintButton
              isConnected={isConnected}
              readIsFetching={readIsFetching}
              write={write}
              waitIsFetching={waitIsFetching}
            />
          </div>
          <TransactionInfo
            waitIsFetching={waitIsFetching}
            receipt={receipt}
            waitForTransactionError={waitForTransactionError}
          />
        </main>
      </div>
    </div>
  );
};

export default Home;
