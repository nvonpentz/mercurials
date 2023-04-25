import React from "react";
import styles from "../../styles/TransactionInfo.module.css";
import { MintAttempt } from "../../utils/types";

type TransactionInfoProps = {
  waitIsFetching: boolean;
  receipt: any;
  waitForTransactionError: any;
  mintAttempt: MintAttempt | undefined;
  address: string;
};

const TransactionInfo: React.FC<TransactionInfoProps> = ({
  waitIsFetching,
  receipt,
  waitForTransactionError,
  mintAttempt,
  address,
}) => {
  const openSeaLink = `https://opensea.io/assets/ethereum/${address}/${mintAttempt?.tokenId}`;
  return (
    <div className={styles.transactionInfo}>
      <div>{waitIsFetching && <div><a href={`https://etherscan.io/tx/${mintAttempt?.transactionHash}`} target="_blank" rel="noreferrer">Transaction</a> sent, waiting for confirmation.</div>}</div>
      <div>
        {receipt && (
          <div>
            Token {mintAttempt?.tokenId} minted successfully! View on {" "}
            <a
              href={openSeaLink}
              target="_blank"
              rel="noreferrer"
            >
              OpenSea
            </a>
            .
          </div>
        )}
      </div>
      <div>
        {waitForTransactionError && (
          <div>
            Mint failed. View the {" "}
            <a
              href={`https://etherscan.io/tx/${mintAttempt?.transactionHash}`}
              target="_blank"
              rel="noreferrer"
            >
              transaction on Etherscan
            </a>
            .
          </div>
        )}
      </div>
    </div>
  );
};

export default TransactionInfo;
