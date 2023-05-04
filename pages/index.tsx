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
import Navbar from "../components/Navbar/Navbar";
import MintButton from "../components/MintButton/MintButton";
import PriceInfo from "../components/PriceInfo/PriceInfo";
import TransactionInfo from "../components/TransactionInfo/TransactionInfo";
import { MintAttempt } from "../utils/types";

const Home: NextPage = () => {
  const { chain = { id: 5 } } = useNetwork();

  // State
  // TODO use a fixed chain id so it works even if they're connected to a diff network
  const [address, setAddress] = useState(deployments[chain.id].address);
  const [abi, setAbi] = useState(deployments[chain.id].abi);
  const [mintAttempt, setMintAttempt] = useState<MintAttempt>();

  // Hooks
  const { isConnected } = useAccount();
  useEffect(() => {
    // TODO use a fixed chain id so it works even if they're connected to a diff network
    setAddress(deployments[chain.id].address);
    setAbi(deployments[chain.id].abi);
  }, [chain]);

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

  const encodedMetadata = nextToken?.[1];
  const extractMetadataFromTokenURI = (tokenURI: string) => {
    return JSON.parse(atob(tokenURI.split(",")[1]));
  };

  const extractSVGFromTokenURI = (tokenURI: string) => {
    const metadata = extractMetadataFromTokenURI(tokenURI);
    if (!metadata.animation_url) {
      return "";
    }

    return atob(metadata.animation_url.split(",")[1]);
  };

  const extractTraitsFromTokenURI = (tokenURI: string) => {
    if (!tokenURI) {
      return [];
    }
    const metadata = extractMetadataFromTokenURI(tokenURI);
    return metadata.attributes;
  };

  // Log traits when nextToken changes
  useEffect(() => {
    console.log("Traits:", extractTraitsFromTokenURI(encodedMetadata));
  }, [encodedMetadata]);

  const {
    data: receipt,
    error: waitForTransactionError,
    isFetching: waitIsFetching,
  } = useWaitForTransaction({
    hash: mintAttempt?.transactionHash,
  });

  return (
    <div className={styles.container}>
      <div className={styles.column}>
        <Head>
          <title>Mercurials - NFT</title>
        </Head>
        <Navbar chainId={chain.id} address={address} />
        <main className={styles.main}>
          <h1 className={styles.header}>
            Mercurial #{nextToken?.[0].toString()}
          </h1>
          <PriceInfo blockNumber={blockNumber} nextToken={nextToken} />
          <div className={styles.traitsAndImageContainer}>
            <div className={styles.imageContainer}>
              <div className={styles.tokenImage}>
                {nextToken && (
                  <div
                    // key={nextToken?.[0]?.toString() + blockNumber?.toString()}
                    key={nextToken?.[0]?.toString()}
                    dangerouslySetInnerHTML={{
                      __html: extractSVGFromTokenURI(nextToken[1]),
                    }}
                  />
                )}
              </div>
              <div className={styles.buttonContainer}>
                <MintButton
                  isConnected={isConnected}
                  readIsFetching={readIsFetching}
                  waitIsFetching={waitIsFetching}
                  address={address}
                  abi={abi}
                  nextToken={nextToken}
                  mintAttempt={mintAttempt}
                  setMintAttempt={setMintAttempt}
                />
              </div>
            </div>
          </div>
          <TransactionInfo
            waitIsFetching={waitIsFetching}
            receipt={receipt}
            waitForTransactionError={waitForTransactionError}
            mintAttempt={mintAttempt}
            address={address}
          />
        </main>
      </div>
    </div>
  );
};

export default Home;
