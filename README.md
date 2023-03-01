# Mercurials

## Development
1. Start local test blockchain RPC node on http://localhost:8545 
  ```
  $ anvil --block-time 12
  ```
1. Deploy the contracts
  ```
  $ forge script script/Deploy.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  ```
1. Start the Next.js server frontend
  ```
  $ npm run dev

  ```
If your transactions are not being processed by Anvil, try resetting the nonce used by your wallet.  They could be getting ignored by the local RPC node because of this.

```
$ cast nonce 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url localhost:8545
```
