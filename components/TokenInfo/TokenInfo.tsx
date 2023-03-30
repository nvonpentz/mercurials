import React, { useState, useEffect } from "react";
import ExpiresIn from "../ExpiresIn/ExpiresIn";
import styles from "../../styles/TokenInfo.module.css";
import { ethers } from "ethers";
import { Result } from "ethers/lib/utils";

type TokenInfoProps = {
  blockNumber: number | undefined;
  nextToken: Result | undefined;
};

const TokenInfo: React.FC<TokenInfoProps> = ({
  blockNumber,
  nextToken,
}) => {
  // UI Helpers
  const numberWithCommas = (x: string | undefined) => {
    return x?.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  };

  // Fetches USD price of ETH
  const [ethPrice, setEthPrice] = useState();
  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch(
          "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd"
        );
        const data = await response.json();
        setEthPrice(data.ethereum.usd);
      } catch (error) {
        console.error(error);
      }
    };
    fetchData();
  }, [blockNumber]);

  return (
    <div className={styles.tokenInfo}>
      <div className={styles.tokenInfoColumn}>
        <div>Current block:</div>
        <div>Expires in:</div>
        <div>Current price:</div>
      </div>
      <div className={styles.tokenInfoColumn}>
        <div>{numberWithCommas(blockNumber?.toString())}</div>
        <ExpiresIn blocks={nextToken?.[4]?.toString()} />
        <div>
          <strong>
            Ξ{" "}
            {nextToken &&
              parseFloat(
                ethers.utils.formatEther(nextToken?.[2].toString())
              ).toFixed(5)}
          </strong>
          <span>
            ($
            {ethPrice &&
              nextToken &&
              (
                ethPrice *
                parseFloat(
                  ethers.utils.formatEther(nextToken?.[2].toString())
                )
              ).toFixed(2)}
            )
          </span>
        </div>
      </div>
    </div>
  );
};

export default TokenInfo;

