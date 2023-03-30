import React from "react";
import styles from "../../styles/TransactionInfo.module.css";

type TransactionInfoProps = {
  waitIsFetching: boolean;
  receipt: any;
  waitForTransactionError: any;
};

const TransactionInfo: React.FC<TransactionInfoProps> = ({
  waitIsFetching,
  receipt,
  waitForTransactionError,
}) => {
  return (
    <div className={styles.transactionInfo}>
      <div>{waitIsFetching && "Waiting for transaction to be mined..."}</div>
      <div>
        {receipt && (
          <div>
            Success! View the transaction on{" "}
            <a
              href={`https://etherscan.io/tx/${receipt.transactionHash}`}
              target="_blank"
              rel="noreferrer"
            >
              Etherscan
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
              href={`https://etherscan.io/tx/${receipt.transactionHash}`}
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

