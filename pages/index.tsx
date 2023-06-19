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
  // const [address, setAddress] = useState(deployments[chain.id].address);
  // const [abi, setAbi] = useState(deployments[chain.id].abi);
  const [address, setAddress] = useState(deployments[5].address);
  const [abi, setAbi] = useState(deployments[5].abi);
  const [mintAttempt, setMintAttempt] = useState<MintAttempt>();

  // Hooks
  const { isConnected } = useAccount();
  useEffect(() => {
    // setAddress(deployments[chain.id].address);
    // setAbi(deployments[chain.id].abi);
    setAddress(deployments[5].address);
    setAbi(deployments[5].abi);
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

  const encodedMetadata = nextToken?.[1];
  const extractMetadataFromTokenURI = (tokenURI: string) => {
    return JSON.parse(atob(tokenURI.split(",")[1]));
  };

  const extractSVGFromTokenURI = (tokenURI: string) => {
    const metadata = extractMetadataFromTokenURI(tokenURI);
    if (!metadata.image) {
      return "";
    }

    return atob(metadata.image.split(",")[1]);
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
    console.log(
      "Traits:",
      JSON.stringify(extractTraitsFromTokenURI(encodedMetadata), null, 2)
    );
    // extractTraitsFromTokenURI(encodedMetadata));
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
          <title>Mercurials - On-chain generative art</title>
        </Head>
        <Navbar chainId={chain.id} address={address} />
        <main className={styles.main}>
          <h1 className={styles.header}>
            Mercurial #{nextToken?.[0].toString()}
          </h1>
          <PriceInfo blockNumber={blockNumber} nextToken={nextToken} />
          <div className={styles.traitsAndImageContainer}>
            <div className={styles.imageContainer}>
              <svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" version="1.1" viewBox="0 0 350 350">
                <g transform="rotate(90, 175, 175)">
                  <filter id="a">
                    <feTurbulence baseFrequency="0.0079" numOctaves="2" seed="32927"/>
                    <feDisplacementMap>
                      <animate attributeName="scale" values="-79;-36;-79;" keyTimes="0; 0.6; 1" dur="33s" repeatCount="indefinite" calcMode="spline" keySplines="0.3 0 0.7 1; 0.3 0 0.7 1"/>
                    </feDisplacementMap>
                    <feColorMatrix type="hueRotate" result="b">
                      <animate attributeName="values" from="0" to="360" dur="8s" repeatCount="indefinite"/>
                    </feColorMatrix>
                    <feColorMatrix type="matrix" result="c" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0"/>
                    <feComposite in="b" in2="c" operator="out" result="d"/>
                    <feComposite in="d" in2="d" operator="arithmetic" k1="1" k2="1" k3="1" k4="-0.20"/>
                    <feDiffuseLighting lighting-color="#fff" diffuseConstant="1" surfaceScale="17">
                      <feDistantLight elevation="82"/>
                    </feDiffuseLighting>
                    <feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>
                  </filter>
                  <rect width="350" height="350" filter="url(#a)"/>
                </g>
              </svg>
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
