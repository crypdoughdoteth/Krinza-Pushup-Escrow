import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("@nomicfoundation/hardhat-foundry");

const config: HardhatUserConfig = {
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

export default config;
