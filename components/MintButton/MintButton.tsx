import React, { useEffect } from 'react';
import { ethers } from "ethers";
import styles from "../../styles/MintButton.module.css";
import {
  usePrepareContractWrite,
  useContractWrite,
} from "wagmi";
import { MintAttempt } from "../../utils/types";

interface MintButtonProps {
  isConnected: boolean;
  readIsFetching: boolean;
  waitIsFetching: boolean;
  address: string;
  abi: any;
  nextToken: any;
  setMintAttempt: (mintAttempt: MintAttempt) => void;
}

const MintButton: React.FC<MintButtonProps> = ({
  isConnected,
  readIsFetching,
  waitIsFetching,
  address,
  abi,
  nextToken,
  setMintAttempt,
}) => {
  // UI logic
  const mintButtonText = (isConnected: boolean) => {
    if (!isConnected) {
      return "Connect Wallet to Mint";
    }
    return "Mint";
  };

  // Hooks
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

  const handleClick = async () => {
    if (write) {
      await write();
      setMintAttempt({
        tokenId: nextToken?.[0].toString(),
        svg: nextToken[1],
        transactionHash: undefined,
      });
    }
  };

  useEffect(() => {
    if (writeData?.hash) {
      setMintAttempt((prevMintAttempt) => {
        if (!prevMintAttempt.transactionHash) {
          return {
            ...prevMintAttempt,
            transactionHash: writeData.hash,
          };
        }
        return prevMintAttempt;
      });
    }
  }, [writeData?.hash, setMintAttempt]);

  return (
    <button
      disabled={readIsFetching || !write || waitIsFetching}
      onClick={handleClick}
      className={styles.mintButton}
    >
      {mintButtonText(isConnected)}
    </button>
  );
};

export default MintButton;
