import React from 'react';
import { ethers } from "ethers";
import styles from "../../styles/MintButton.module.css";

interface MintButtonProps {
  isConnected: boolean;
  readIsFetching: boolean;
  write?: () => void; // Make the write prop optional
  waitIsFetching: boolean;
}

const MintButton: React.FC<MintButtonProps> = ({
  isConnected,
  readIsFetching,
  write,
  waitIsFetching,
}) => {
  const mintButtonText = (isConnected: boolean) => {
    if (!isConnected) {
      return "Connect Wallet to Mint";
    }
    return "Mint";
  };

  return (
    <button
      disabled={readIsFetching || !write || waitIsFetching}
      onClick={() => write?.()}
      className={styles.mintButton}
    >
      {mintButtonText(isConnected)}
    </button>
  );
};

export default MintButton;

