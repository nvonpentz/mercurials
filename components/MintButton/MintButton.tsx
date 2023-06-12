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
  mintAttempt: MintAttempt | undefined;
  setMintAttempt: (mintAttempt: MintAttempt) => void;
}

const MintButton: React.FC<MintButtonProps> = ({
  isConnected,
  readIsFetching,
  waitIsFetching,
  address,
  abi,
  nextToken,
  mintAttempt,
  setMintAttempt,
}) => {
  // UI logic
  const mintButtonText = (isConnected: boolean) => {
    // if (!isConnected) {
    //   return "Connect Wallet to Mint";
    // }
    return "Burn Ether and Mint";
  };

  // Hooks
  const { config, error: prepareWriteError } = usePrepareContractWrite({
    address: address,
    abi: abi,
    args: [nextToken?.[0], nextToken?.[3]],
    functionName: "mint",
    overrides: {
      gasLimit: ethers.BigNumber.from(100000),
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
      } as MintAttempt);
    }
  };

  useEffect(() => {
    if (writeData?.hash) {
      if (mintAttempt?.transactionHash === undefined) {
        setMintAttempt({
          tokenId: mintAttempt?.tokenId,
          svg: mintAttempt?.svg,
          transactionHash: writeData.hash,
        } as MintAttempt);
      }
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
