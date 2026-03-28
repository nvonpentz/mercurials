import React, { useEffect } from 'react';
import styles from "../../styles/MintButton.module.css";
import {
  useSimulateContract,
  useWriteContract,
} from "wagmi";
import { MintAttempt } from "../../utils/types";

interface MintButtonProps {
  isConnected: boolean;
  readIsFetching: boolean;
  waitIsFetching: boolean;
  address: `0x${string}`;
  abi: any;
  nextToken: readonly [bigint, string, bigint, `0x${string}`, bigint] | undefined;
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
    return "Burn Ether and Mint";
  };

  // Hooks
  const { data: simulateData, error: simulateError } = useSimulateContract({
    address: address,
    abi: abi,
    args: nextToken ? [nextToken[0], nextToken[3]] : undefined,
    functionName: "mint",
    value: nextToken?.[2],
    gas: BigInt(150000),
    query: {
      enabled: !!nextToken,
    },
  });

  const {
    data: writeData,
    error: writeError,
    isPending: isWritePending,
    writeContract,
  } = useWriteContract();

  const handleClick = async () => {
    if (simulateData?.request && nextToken) {
      writeContract(simulateData.request);
      setMintAttempt({
        tokenId: Number(nextToken[0]),
        svg: nextToken[1],
        transactionHash: undefined,
      });
    }
  };

  useEffect(() => {
    if (writeData && mintAttempt && mintAttempt.transactionHash === undefined) {
      setMintAttempt({
        tokenId: mintAttempt.tokenId,
        svg: mintAttempt.svg,
        transactionHash: writeData,
      });
    }
  }, [writeData, mintAttempt, setMintAttempt]);

  return (
    <button
      disabled={readIsFetching || !simulateData?.request || waitIsFetching || isWritePending}
      onClick={handleClick}
      className={styles.mintButton}
    >
      {mintButtonText(isConnected)}
    </button>
  );
};

export default MintButton;
