# Mercurials

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
If your transactions are not being processed by Anvil, try resetting the nonce used by your wallet.  They could be getting ignored by the local RPC node because of this.

## Goerli deploy

```
$ forge script script/Deploy.sol --rpc-url https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161 --broadcast --interactives 1 --sender 0x595a0583621FDe81A935021707e81343f75F9324
```

### Lint
```
$ prettier --write pages/*.tsx contracts/src/*.sol contracts/script/Deploy.sol contracts/test/*.sol
```

### Check nonce
```
$ cast nonce 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url localhost:8545
```

### Etherscan verify
```
$ forge verify-contract 0x618c0126ad50969dd39bfa310a554a7c086eecb0 src/Mercurials.sol:Mercurials --chain 5
```
