import React from 'react';
import Link from 'next/link';
import { ConnectButton } from "@rainbow-me/rainbowkit";
import styles from '../../styles/Navbar.module.css';

interface NavbarProps {
  chainId: number;
  address: string;
}

const Navbar: React.FC<NavbarProps> = ({ chainId, address }) => {
  const openseaLink = `https://opensea.io/assets/ethereum/${address}`;
  return (
    <nav className={styles.navbar}>
      <ul>
        <li>
          <a href="https://nvp.dev/posts/mercurials" target="_blank" rel="noopener noreferrer">About</a>
        </li>
        <li>
          <a href={openseaLink} target="_blank" rel="noopener noreferrer">OpenSea</a>
        </li>
        <li className={styles.connectButtonLi}>
          <ConnectButton />
        </li>
      </ul>
    </nav>
  );
};

export default Navbar;
