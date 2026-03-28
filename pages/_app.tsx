import "../styles/globals.css";
import "@rainbow-me/rainbowkit/styles.css";
import type { AppProps } from "next/app";
import {
  RainbowKitProvider,
  lightTheme,
  connectorsForWallets,
} from "@rainbow-me/rainbowkit";
import {
  metaMaskWallet,
  rainbowWallet,
  coinbaseWallet,
  injectedWallet,
} from "@rainbow-me/rainbowkit/wallets";
import { WagmiProvider, createConfig } from "wagmi";
import { mainnet, goerli, foundry } from "wagmi/chains";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { Analytics } from "@vercel/analytics/react";
import { http } from "viem";

const chains = process.env.NEXT_PUBLIC_ENV === "production"
  ? [mainnet] as const
  : [mainnet, goerli, foundry] as const;

const connectors = connectorsForWallets(
  [
    {
      groupName: "Popular",
      wallets: [metaMaskWallet, rainbowWallet, coinbaseWallet, injectedWallet],
    },
  ],
  {
    appName: "Mercurials",
    projectId: "mercurials", // placeholder - WalletConnect mobile won't work but injected wallets will
  }
);

const config = createConfig({
  connectors,
  chains,
  transports: {
    [mainnet.id]: http(
      `https://eth-mainnet.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_API_KEY}`
    ),
    [goerli.id]: http(
      `https://eth-goerli.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_API_KEY}`
    ),
    [foundry.id]: http("http://localhost:8545"),
  },
  ssr: true,
});

const queryClient = new QueryClient();

function MyApp({ Component, pageProps }: AppProps) {
  const [ready, setReady] = useState(false);
  useEffect(() => {
    setReady(true);
  }, []);

  return (
    <>
      {ready ? (
        <WagmiProvider config={config}>
          <QueryClientProvider client={queryClient}>
            <RainbowKitProvider
              theme={lightTheme({
                accentColor: "#7b3fe4",
                accentColorForeground: "white",
                borderRadius: "medium",
              })}
            >
              <Component {...pageProps} />
              <Analytics />
            </RainbowKitProvider>
          </QueryClientProvider>
        </WagmiProvider>
      ) : null}
    </>
  );
}

export default MyApp;
