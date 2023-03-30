import React from "react";
import styles from "../../styles/TransactionInfo.module.css";
import { MintAttempt } from "../../utils/types";

type TransactionInfoProps = {
  waitIsFetching: boolean;
  receipt: any;
  waitForTransactionError: any;
  mintAttempt: MintAttempt;
  address: string;
};

const TransactionInfo: React.FC<TransactionInfoProps> = ({
  waitIsFetching,
  receipt,
  waitForTransactionError,
  mintAttempt,
  address,
}) => {
  const openSeaLink = `https://opensea.io/assets/ethereum/${address}/${mintAttempt.tokenId}`;
  return (
    <div className={styles.transactionInfo}>
      <div>{waitIsFetching && <div>Transaction sent, waiting for confirmation. View on <a href={`https://etherscan.io/tx/${mintAttempt.transactionHash}`} target="_blank" rel="noreferrer">Etherscan</a>.</div>}</div>
      <div>
        {receipt && (
          <div>
            Token {mintAttempt.tokenId} minted successfully! View on {" "}
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
            Mint failed. View the transaction on{" "}
            <a
              href={`https://etherscan.io/tx/${mintAttempt.transactionHash}`}
              target="_blank"
              rel="noreferrer"
            >
              Etherscan
            </a>
            .
          </div>
        )}
      </div>
    </div>
  );
};

export default TransactionInfo;
