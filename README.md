# <img src="https://github.com/user-attachments/assets/4f01ef6e-3c1e-4201-83db-fac4b383a3b0" alt="durin" width="33%">

> [!WARNING]
> This is an experimental project and may include frequent breaking changes. Do not rely on it for production workflows.

Durin is an opinionated approach to ENS L2 subnames. This repo includes:

1. Registry factory on [supported chains](#active-registry-factory-deployments)
2. Registrar template
3. Gateway server
4. L1 resolver

## Instructions To Deploy L2 ENS Subnames

This repo is meant to be used in conjuction with [Durin.dev](https://durin.dev/), which provides a frontend for deploying the registry & enabling name resolution.

### 1. Deploy a Registry

Go to [Durin.dev](https://durin.dev/). Choose Sepolia or Mainnet ENS name resolution. Pick a supported L2. Deploy.

Once complete, note the deployed L2 registry address.

### 2. Enable Name Resolution

To connect your newly deployed L2 registry with your ENS name on L1, change the name's resolver to `0x8A968aB9eb8C084FBC44c531058Fc9ef945c3D61` and call `setL2Registry()` with the L2 registry's address and chain ID.

Both of these steps can be done via [durin.dev](https://durin.dev) or the [ENS manager app](http://app.ens.domains).

### 3. Customize the Registrar Template

> [!NOTE]  
> Durin uses [Foundry](https://github.com/foundry-rs/foundry). To install it, follow the [instructions](https://book.getfoundry.sh/getting-started/installation).

Durin provides a registrar template that is meant to be customized. Common customizations include adding pricing, implementing allow lists, and enabling token gating.

You can either clone this repo and modify [L2Registrar.sol](./src/examples/L2Registrar.sol) directly, or write a new contract in your existing project. If you prefer the latter, simply import [IL2Registry.sol](./src/interfaces/IL2Registry.sol) to your project so you can interact with the registry you deployed earlier and skip to step 5.

To get started, clone this repo:

```shell
git clone https://github.com/namestonehq/durin.git
cd durin
```

Once cloned, modify [L2Registrar.sol](./src/examples/L2Registrar.sol) as needed.

### 4. Deploy L2Registrar Contract

To deploy the L2Registrar contract, you will need to prepare a `.env` file and run the deploy script.

```shell
cp .env.example .env
```

Open the new `.env` file and set the variables that are marked as required at the top, then run the following command:

```shell
bash ./bash/DeployL2Registrar.sh
```

### 5. Connect Registrar to L2Registry

Only approved Registrars can call `createSubnode()` on the Registry. The owner of the registry can add as many Registrars as they want.

To add a Registrar, visit your Registry on Etherscan and call `addRegistrar()` with the newly deployed Registrar's address.

Finally, you'll be able to mint subnames via the Registrar.

## Contracts

This repo includes all of the smart contract (L1 and L2) required to enable subname issuance.

- [L1Resolver](./src/L1Resolver.sol): L1 contract that forwards ENS queries to the L2.
- [L2RegistryFactory](./src/L2RegistryFactory.sol): L2 contract for creating new registries.
- [L2Registry](./src/L2Registry.sol): L2 contract that stores subnames as ERC721 NFTs. This contract is also responsible for storing data like address and text records.
- [L2Registrar](./src/examples/L2Registrar.sol): An example registrar contract that can mint subnames. This is meant to be customized.

## Active Registry Factory Deployments

| L2                 | Registry Factory                                                                                                                         |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Arbitrum           | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://arbiscan.io/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)                   |
| Arbitrum Sepolia   | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://sepolia.arbiscan.io/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)           |
| Base               | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://basescan.org/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)                  |
| Base Sepolia       | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://sepolia.basescan.org/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)          |
| Celo               | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://celoscan.io/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)                   |
| Celo Sepolia       | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://celo-sepolia.blockscout.com/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)   |
| Linea              | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://lineascan.build/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)               |
| Linea Sepolia      | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://sepolia.lineascan.build/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)       |
| Optimism           | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://optimistic.etherscan.io/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)       |
| Optimism Sepolia   | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://sepolia-optimism.etherscan.io/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d) |
| Polygon            | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://polygonscan.com/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)               |
| Polygon Amoy       | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://amoy.polygonscan.com/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)          |
| Scroll             | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://scrollscan.com/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)                |
| Scroll Sepolia     | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://sepolia.scrollscan.com/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)        |
| Worldchain         | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://worldscan.org/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)                 |
| Worldchain Sepolia | [`0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d`](https://sepolia.worldscan.org/address/0xDddddDdDDD8Aa1f237b4fa0669cb46892346d22d)         |

## Architecture

![architecture](https://github.com/user-attachments/assets/06065784-0516-498e-a512-d7b63892599a)

> [!NOTE]  
> A dependency for supporting `-withSignature` methods on new chains is a deployment of UniversalSigValidator to `0x164af34fAF9879394370C7f09064127C043A35E9`. The deployment is permissionless and can be found [here](https://github.com/ensdomains/ens-contracts/blob/8c414e4c41dce49c49efd0bf82c10a145cdc8f0a/deploy/utils/00_deploy_universal_sig_validator.ts).

## Deploying Durin

> [!NOTE]  
> Developers that want to issue subnames on one of the chains listed above in the [Active Registry Factory Deployments](#active-registry-factory-deployments) section do not need to read any further.

1. Create a `.env` file via `cp .env.example .env`. You don't need to change anything.
2. Add/uncomment the chains you want to deploy to in [foundry.toml](./foundry.toml#L23) and [DeployL2Contracts.s.sol](./scripts/DeployL2Contracts.s.sol#L30).
3. Run `./bash/DeployL2Contracts.sh` to deploy the registry implementation and factory contracts to the specified chains.
4. Run `./bash/VerifyL2Contracts.sh` for each chain you deployed to, changing `NETWORK` and `BLOCK_EXPLORER_API_KEY` in the files, to verify all the contracts you just deployed.
5. Add your chain(s) to [query.ts](./gateway/src/ccip-read/query.ts#L8) in the gateway config.

## Initial Setup

Run `./bash/DeployL1Resolver.sh` followed by `./bash/VerifyL1Resolver.sh` to deploy and verify the L1 Resolver. This is L2 chain agnostic, so only needs to be done once.

## CREATE2 Tips

For generating a CREATE2 salt to deploy the L2RegistryFactory, run the command below. Use [./scripts/L2RegistryFactoryInitCode.s.sol](./scripts/L2RegistryFactoryInitCode.s.sol) to calculate the init code hash.

```bash
export FACTORY="0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2"
export INIT_CODE_HASH="<HASH_OF_YOUR_CONTRACT_INIT_CODE_GOES_HERE>"
cast create2 --starts-with dddddd --deployer $FACTORY --init-code-hash $INIT_CODE_HASH
```

Once you have a salt that you're happy with, update `L2_REGISTRY_FACTORY_SALT` in `.env` so it's used in the deployment script.
