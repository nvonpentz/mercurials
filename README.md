# Mercurials
Solidity and frontend code for the [Mercurials](https://mercurials.wtf) project.

## Development
1. Start local test blockchain RPC node on http://localhost:8545 
  ```
  $ anvil --block-time 12
  ```
2. Deploy the contracts
  ```
  $ forge script script/Deploy.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  ```
3. Start the Next.js server frontend
  ```
  $ npm run dev
  ```
