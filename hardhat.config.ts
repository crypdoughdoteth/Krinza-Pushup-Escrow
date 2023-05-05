// import { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";
require("@nomicfoundation/hardhat-foundry");
require('dotenv').config();

module.exports = {
  zksolc: {
    version: "1.3.10",
    compilerSource: "binary",
    settings: {},
  },
  defaultNetwork: "zkSyncTestnet",

  networks: {
    goerli: {
      url: `${process.env.GOERLI_RPC_URL}` // The Ethereum Web3 RPC URL (optional).
    },
    zkSyncTestnet: {
      url: "https://testnet.era.zksync.dev",
      ethNetwork: `${process.env.GOERLI_RPC_URL}`, // RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
      zksync: true,
      verifyURL: 'https://zksync2-testnet-explorer.zksync.dev/contract_verification'
    },
  },
  solidity: {
        compilers: [
          {
            version: "0.8.18",
            settings: {
              optimizer: {
                enabled: true,
                runs: 200,
              },
            },
          },
          {
            version: "0.8.19",
            settings: {
              optimizer: {
                enabled: true,
                runs: 200,
              },
            },
          }
        ],
      },
};

// const config: HardhatUserConfig = {
//   solidity: {
//     compilers: [
//       {
//         version: "0.8.18",
//         settings: {
//           optimizer: {
//             enabled: true,
//             runs: 200,
//           },
//         },
//       },
//       {
//         version: "0.8.19",
//         settings: {
//           optimizer: {
//             enabled: true,
//             runs: 200,
//           },
//         },
//       }
//     ],
//   },
// };

// export default config;
