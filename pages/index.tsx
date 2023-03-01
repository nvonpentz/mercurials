import { ConnectButton } from '@rainbow-me/rainbowkit';
import type { NextPage } from 'next';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import { address } from '../contracts/deploys/mercurial.31337.address.json';
import { abi } from '../contracts/deploys/mercurial.31337.compilerOutput.json';
import {
  useBlockNumber,
  useContractRead,
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction
} from 'wagmi'
import Image from 'next/image'
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { Result } from 'ethers/lib/utils';

const Home: NextPage = () => {
  const [transactionHash, setTransactionHash] = useState("");
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
  }) as { data: Result, isFetching: boolean };

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

  const { data: receipt, error: waitForTransactionError, isFetching: waitIsFetching } = useWaitForTransaction({
    hash: writeData?.hash,
  });

  // Countdown timer state and effect
  const [seconds, setSeconds] = useState(12);

  useEffect(() => {
    // Reset the timer when the block number changes
    setSeconds(12);
  }, [blockNumber]);

  useEffect(() => {
    if (seconds > 0) {
      const timer = setTimeout(() => setSeconds(seconds - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [seconds]);

  return (
    <div className={styles.container}>
      <div className={styles.column}>
        <Head>
          <title>Mercurials - NFT</title>
          <meta name="description" content="TODO" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <link rel="icon" href="/favicon.ico" />
          <link rel="preconnect" href="https://fonts.googleapis.com"/>
          <link rel="preconnect" href="https://fonts.gstatic.com"/>
          <link href="https://fonts.googleapis.com/css2?family=Lato&display=swap" rel="stylesheet"/>
        </Head>
        <nav className={styles.navbar}>
          <ul>
            <li><ConnectButton /></li>
          </ul>
        </nav>
        <main className={styles.main}>
          <h1>Mercurial #{nextToken?.[0].toString()}</h1>
          <div className={styles.tokenInfo}>
            <div className={styles.tokenInfoColumn}>
              <div>Current block:</div>
              <div>Expires in:</div>
              <div>Current price:</div>
            </div>
            <div className={styles.tokenInfoColumn}>
              <div>{blockNumber?.toString()}</div>
              <div>{nextToken?.[4]?.toString()} blocks.</div>
              <strong>Ξ {nextToken && ethers.utils.formatEther(nextToken?.[2].toString())}</strong>
            </div>
          </div>
          <div className={styles.tokenImage}>
            {nextToken && <div dangerouslySetInnerHTML={{ __html: nextToken[1] }} />}
          </div>
          <div>
          </div>
          <div className={styles.buttonContainer}>
            <button disabled={ readIsFetching || !write || waitIsFetching } onClick={() => write?.()} className={styles.mintButton}>
              Mint
            </button>
          </div>
          <div className={styles.transactionInfo}>
            <div> {transactionHash && <a href={`https://rinkeby.etherscan.io/tx/${transactionHash}`}>View on Etherscan</a>}</div>
            <div> {waitIsFetching && 'Waiting for transaction to be mined...'} </div>
            <div> {receipt && <div> Success! </div>} </div>
            <div> {waitForTransactionError && <div> Mint failed. </div>} </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Home;
