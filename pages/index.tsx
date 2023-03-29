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

const Home: NextPage = () => {
  // UI Helpers
  const numberWithCommas = (x: string | undefined) => {
    return x?.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  };

  // Hooks
  const { isConnected } = useAccount();
  const { chain = { id: 5 } } = useNetwork();
  const [address, setAddress] = useState(deployments[chain?.id]?.address);
  const [abi, setAbi] = useState(deployments[chain?.id]?.abi);
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

  // Fetches USD price of ETH
  const [ethPrice, setEthPrice] = useState();
  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch(
          "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd"
        );
        const data = await response.json();
        setEthPrice(data.ethereum.usd);
      } catch (error) {
        console.error(error);
      }
    };
    fetchData();
  }, [blockNumber]);

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
        <Navbar chainId={chain.id} address={address}/>
        <main className={styles.main}>
          <h1>Mercurial #{nextToken?.[0].toString()}</h1>
          <div className={styles.tokenInfo}>
            <div className={styles.tokenInfoColumn}>
              <div>Current block:</div>
              <div>Expires in:</div>
              <div>Current price:</div>
            </div>
            <div className={styles.tokenInfoColumn}>
              <div>{numberWithCommas(blockNumber?.toString())}</div>
              <ExpiresIn blocks={nextToken?.[4]?.toString()} />
              <div>
                <strong>
                  Ξ{" "}
                  {nextToken &&
                    parseFloat(
                      ethers.utils.formatEther(nextToken?.[2].toString())
                    ).toFixed(5)}
                </strong>
                <span>
                  ($
                  {ethPrice &&
                    nextToken &&
                    (
                      ethPrice *
                      parseFloat(
                        ethers.utils.formatEther(nextToken?.[2].toString())
                      )
                    ).toFixed(2)}
                  )
                </span>
              </div>
            </div>
          </div>
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
          <div className={styles.transactionInfo}>
            <div>
              {" "}
              {waitIsFetching && "Waiting for transaction to be mined..."}{" "}
            </div>
            <div> {receipt && <div> Success! </div>} </div>
            <div> {waitForTransactionError && <div> Mint failed. </div>} </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Home;
