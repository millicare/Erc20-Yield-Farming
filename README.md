## Yield Farm

#### Project: Yield Farm

### Live Website: https://yieldcomp.vercel.app/

Still in progress but core functionality working on testnet

### Overview:

A Flexible, minimalist, and gas-optimized yield farm protocol for earning interest on ERC20 tokens through Compound Finace.
Users deposit token into protol vaults and earn yield through compound on their deposits. Withdrawals include profit minus protocol fees set at 5% and withdrawals are allowed at anytime.

### Deliverables

1. Web App: A user-friendly application to interact with vaults.
   #### Functionality:
   1. Deposits into selected vault(s).
   2. Withdrawals from selected vault(s).
   3. View APY for various vault(s).

### Architecture:

Smart Contracts: Actions performed by Protocol are done onchain and controlled by these smart contracts.
. Vault.sol: ERC4626 standard smart contract for earning interest on any ERC20 token through the compund protocol.
. Vaultfactory.sol: Factory for vault deployments and management.
. interface: Interfaces of external contracts Vaults and modules interact with.
. CErcInterface.sol: Interface for Compound ctoken.

![](Untitled-2022-09-13-21101.png)

### Setup

This is a monorepo setup built built with turbo-repo. The frontend is built with Nextjs and smart contracts with foundry. Ensure forge is installed for foundry.

#### Directory

yield-farm
|** apps
| |** web
|  
 |** packages
| |** contracts
|
|\_\_ package.json

The frontend is contained in web and smart contracts in contracts

#### Clone repo

```sh
git clone repo
cd yield-farm
```

### Working with Smart Contracts

#### install dependecies and packages

```sh
cd packages/contracts
forge install
```

#### Build smart contracts

```sh
forge build
```

#### Test smart contracts

```sh
forge test
```

#### deployment

Create .env and add to file
GOERLI_RPC_URL=....
ETHERSCAN_KEY=....
PRIVATE_KEY=....

```sh
forge script script/AIMVaultFactory.s.sol:MyScript --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
```

### Addresses

#### Goerli Testnet

Vault Factory: 0x7D7B81aeB0aF69d9F9612b1BEfa73ce600f21284
Deployed USDC Vault: 0x7Be4DE03B336BD384de692A5C348806f649D4Bb7
