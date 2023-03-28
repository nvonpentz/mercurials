import React from 'react';
import { ConnectButton } from "@rainbow-me/rainbowkit";
import styles from '../../styles/Navbar.module.css';

const Navbar = () => {
  return (
    <nav className={styles.navbar}>
      <ul>
        <li>
          <a href="https://mercurials.wtf">Home</a>
        </li>
        <li>
          <a href="https://mercurials.wtf/about">About</a>
        </li>
        <li className={styles.connectButtonLi}>
          <ConnectButton />
        </li>
      </ul>
    </nav>
  );
};

export default Navbar;

