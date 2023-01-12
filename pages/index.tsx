import { ConnectButton } from '@rainbow-me/rainbowkit';
import type { NextPage } from 'next';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import { address } from '../contracts/deploys/fossil.31337.address.json';
import { abi } from '../contracts/deploys/fossil.31337.compilerOutput.json';
import { useContractRead, useBlockNumber } from 'wagmi'
import Image from 'next/image'

const Home: NextPage = () => {
  const { data: blockNumber } = useBlockNumber({ watch: true });
  const { data, error, isError, isLoading } = useContractRead({
    address: address,
    abi: abi,
    functionName: 'constructImageURI',
    args: [blockNumber]
  })

  return (
    <div className={styles.container}>
      <Head>
        <title>Fossils - NFT</title>
        <meta name="description" content="TODO" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        {false && <ConnectButton />}
        {data &&
          <div className={styles.frame}>
            <Image className={styles.display}src={data} alt="Fossil" width={500} height={500} />
        </div>}
      </main>
      <footer className={styles.footer}>
      </footer>
    </div>
  );
};

export default Home;
