import { ConnectButton } from '@rainbow-me/rainbowkit';
import type { NextPage } from 'next';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import { address } from '../contracts/deploys/fossil.31337.address.json';
import { abi } from '../contracts/deploys/fossil.31337.compilerOutput.json';
import { useContractRead, useBlockNumber } from 'wagmi'
import Image from 'next/image'
import { useState, useEffect } from 'react';

const maxImages = 3;

const Home: NextPage = () => {
  const { data: blockNumber } = useBlockNumber({ watch: true });
  const { data, error, isError, isLoading, isFetched, isFetching } = useContractRead({
    address: address,
    abi: abi,
    functionName: 'constructImageURI',
    // args: [796],
    args: [blockNumber]
  })

  const [pastImages, setPastImages] = useState<string[]>([])
  useEffect(() => {
    return () => {
      if (data && pastImages.length < maxImages) {
        setPastImages([...pastImages, data])
      } else if (data && isFetched && !isFetching && pastImages.length >= maxImages) {
        setPastImages([...pastImages.slice(1), data]);
      } 
    }
  }, [data])

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
          {data && <Image
                      className={styles.display}
                      src={data}
                      width={500}
                      height={500}
            />}
          { false && <div className={styles.menu}>
            <span className={styles.price}>$1000</span>
            <button className={styles.buyButton}>Buy</button>
          </div>}
          {false && <div className={styles.pastImages}>
            <h2>Recent Past Images</h2>
            <div className={styles.pastImagesGrid}>
              {false && data && pastImages.map((image, index) => (
                <Image className={styles.pastImage} key={index} src={pastImages[index] || ""} width={200} height={150} />
              ))}
            </div>
          </div>}
        </main>
      </div>
    </div>
  );
};

export default Home;
