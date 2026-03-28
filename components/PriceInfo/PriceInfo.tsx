import React, { useState, useEffect } from "react";
import ExpiresIn from "../ExpiresIn/ExpiresIn";
import styles from "../../styles/PriceInfo.module.css";
import { formatEther } from "viem";

type PriceInfoProps = {
  blockNumber: bigint | undefined;
  nextToken: readonly [bigint, string, bigint, `0x${string}`, bigint] | undefined;
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
  const [ethPrice, setEthPrice] = useState<number>();
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

  const priceInEth = nextToken ? parseFloat(formatEther(nextToken[2])) : 0;

  return (
    <div className={styles.tokenInfo}>
      <div className={styles.tokenInfoColumn}>
        <div className={styles.tokenPrice}>
          Ξ{" "}
          <strong>
            {nextToken && priceInEth.toFixed(5)}
          </strong>
          <span>
            ($
            {ethPrice && nextToken && (ethPrice * priceInEth).toFixed(2)})
          </span>
        </div>

        {nextToken && <ExpiresIn blocks={Number(nextToken[4])} />}
      </div>
    </div>
  );
};

export default PriceInfo;
