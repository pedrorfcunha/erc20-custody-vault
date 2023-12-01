<h1 align="center">
   Custody Vault Project
</h1>

---

## Description

This project consists of a contract that acts as an ERC20 token custody vault, along with an ERC20 contract for demonstration purposes. With this contract, it's possible to transfer tokens between two addresses, with prior arbitration facilitated by a trusted third party within the custody vault.

## Getting Started

See the instructions down below at [Installation](#installation)
and [Running / Development](#running-/-development) to get a copy of the
project up and running on your local machine.

#### Technologies

-   Solidity
-   JavaScript
-   Mocha

## Installation

-   `git clone https://github.com/pedrorfcunha/erc20-custody-vault.git` this repository
-   `cd erc20-custody-vault`
-   `npm install` or `yarn install`

## Running / Development

### Env Variables

Create a .env file in the root and add the following

```
PRIVATE_KEY="YOUR-PRIVATE-KEY"
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
ETHERSCAN_API_KEY="YOUR_KEY"
```

-   `yarn hardhat run scripts/deploy-custody-vault.js --network sepolia` to deploy the contract on sepolia's network
-   `yarn hardhat tests` to run the contract tests
