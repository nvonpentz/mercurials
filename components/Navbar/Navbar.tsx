import React from 'react';
import Link from 'next/link';
import { ConnectButton } from "@rainbow-me/rainbowkit";
import styles from '../../styles/Navbar.module.css';

const Navbar = () => {
  return (
    <nav className={styles.navbar}>
      <ul>
        <li>
          <Link href="/">
            <a>Home</a>
          </Link>
        </li>
        <li>
          <a href="https://example.com" target="_blank" rel="noopener noreferrer">About</a>
        </li>
        <li className={styles.connectButtonLi}>
          <ConnectButton />
        </li>
      </ul>
    </nav>
  );
};

export default Navbar;
