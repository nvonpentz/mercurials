import { ConnectButton } from '@rainbow-me/rainbowkit';
import type { NextPage } from 'next';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import { address } from '../contracts/deploys/fossil.31337.address.json';
import { abi } from '../contracts/deploys/fossil.31337.compilerOutput.json';
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

const Home: NextPage = () => {
  const [transactionHash, setTransactionHash] = useState('');
  const { data: blockNumber } = useBlockNumber();
  const { data: nextToken, isFetching: readIsFetching } = useContractRead({
    address: address,
    abi: abi,
    functionName: 'nextToken',
    args: [],
    overrides: {
      blockTag: 'pending',
    },
    watch: true
  });

  const { config, error: prepareWriteError } = usePrepareContractWrite({
    address: address,
    abi: abi, args: [nextToken?.[0], nextToken?.[3]],
    functionName: 'mint',
    overrides: {
      gasLimit: 5000000,
      value: nextToken?.[2]
    }
  });
  
  const {
    data: writeData,
    error: writeError,
    isError: isWriteError,
    isLoading: isWriteLoading,
    write,
  } = useContractWrite(config);

  useEffect(() => {
    if (writeData?.hash) {
      setTransactionHash(writeData.hash);
    }
  }, [writeData?.hash]);

  const { data: receipt, error: waitForTransactionError, isFetching: waitIsFetching } = useWaitForTransaction({
    hash: writeData?.hash,
  })

  return (
    <div className={styles.container}>
      <div className={styles.column}>
        <Head>
          <title>Fossils - NFT</title>
          <meta name="description" content="TODO" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <link rel="icon" href="/favicon.ico" />
          <link rel="preconnect" href="https://fonts.googleapis.com"/>
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
          <link href="https://fonts.googleapis.com/css2?family=Lato&display=swap" rel="stylesheet"/>
        </Head>
        {<nav className={styles.navbar}>
          <span>Block #{blockNumber?.toString()}</span>
          <ConnectButton /> 
      </nav>}
        <main className={styles.main}>
          <h1>Fossils #{nextToken?.[0].toString()}</h1>
          <div>
            {nextToken && <div dangerouslySetInnerHTML={{ __html: nextToken[1] }} />}
          </div>
          <div>
            <strong>Ξ</strong> {nextToken && ethers.utils.formatEther(nextToken?.[2].toString())}
          </div>
          <button disabled={ readIsFetching || !write || waitIsFetching } onClick={() => write()}>
            Mint
          </button>
          <div> {transactionHash && <a href={`https://rinkeby.etherscan.io/tx/${transactionHash}`} target="_blank">View on Etherscan</a>}</div>
          <div> {waitIsFetching && 'Waiting for transaction to be mined...'} </div>
          <div> {receipt && <div> Success! </div>} </div>
          <div> {waitForTransactionError && <div> Mint failed. </div>} </div>
        </main>
      </div>
    </div>
  );
};

export default Home;
