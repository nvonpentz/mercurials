import { ConnectButton } from '@rainbow-me/rainbowkit';
import type { NextPage } from 'next';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import { address } from '../contracts/deploys/fossil.31337.address.json';
import { abi } from '../contracts/deploys/fossil.31337.compilerOutput.json';
import { useContractRead, useContractWrite } from 'wagmi'
import Image from 'next/image'
import { useState, useEffect } from 'react';

const maxImages = 3;

const Home: NextPage = () => {
  const [blockNumber, setBlockNumber] = useState(0); // added state to keep track of the current value
  // const { data, error, isError, isLoading, isFetched, isFetching } = useContractRead({
  //   address: address,
  //   abi: abi,
  //   functionName: 'generateSVG',
  //   args: [blockNumber] // use the current value of blockNumber
  // });

  const { data, error, isError, isLoading, isFetched, isFetching } = useContractRead({
    address: address,
    abi: abi,
    functionName: 'nextToken',
    args: [],
    watch: true
  });

  const handleButtonClick = () => {
    setBlockNumber(blockNumber + 1); // increment the value on button click
  }

  return (
    <div className={styles.container}>
      <div className={styles.column}>
        <Head>
          <title>Fossils - NFT</title>
          <meta name="description" content="TODO" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <link rel="icon" href="/favicon.ico" />
        </Head>
        {false && <nav className={styles.navbar}>
          <span className={styles.title}>Fossils</span>
          <span className={styles.title}>Waffles</span>
          <ConnectButton /> 
        </nav>}
          <main className={styles.main}>
          {data && <div dangerouslySetInnerHTML={{ __html: data[1] }} />}
          {false && <Image
                      className={styles.display}
                      src={data}
                      width={500}
                      height={500}
            />}
          { false && <button onClick={handleButtonClick}>Increment</button>}
        </main>
      </div>
    </div>
  );
};

export default Home;
