import React, { useState, useEffect } from "react";
import ExpiresIn from "../ExpiresIn/ExpiresIn";
import styles from "../../styles/PriceInfo.module.css";
import { ethers } from "ethers";
import { Result } from "ethers/lib/utils";

type PriceInfoProps = {
  blockNumber: number | undefined;
  nextToken: Result | undefined;
};

const PriceInfo: React.FC<PriceInfoProps> = ({
  blockNumber,
  nextToken,
}) => {
  // UI Helpers
  const numberWithCommas = (x: string | undefined) => {
    return x?.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  };

  // Fetches USD price of ETH
  const [ethPrice, setEthPrice] = useState();
  // useEffect(() => {
  //   const fetchData = async () => {
  //     try {
  //       const response = await fetch(
  //         "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd"
  //       );
  //       const data = await response.json();
  //       setEthPrice(data.ethereum.usd);
  //     } catch (error) {
  //       console.error(error);
  //     }
  //   };
  //   fetchData();
  // }, [blockNumber]);

  return (
    <div className={styles.tokenInfo}>
      <div className={styles.tokenInfoColumn}>
        <div className={styles.tokenPrice}>
          Ξ{" "}
          <strong>
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

        <ExpiresIn blocks={nextToken?.[4]?.toString()} />
      </div>
    </div>
  );
};

export default PriceInfo;
