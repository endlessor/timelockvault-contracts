const { gweiToWei } = require("./utils");
const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 8545, // Standard Ethereum port (default: none)
      network_id: "*", // Any network (default: none)
    },

    kovan: {
      provider: () =>
        new HDWalletProvider(
          [process.env.PRIVATE_KEY],
          "https://kovan.infura.io/v3/" + process.env.INFURA_KEY
        ),
      network_id: 42,
      gasPrice: gweiToWei(process.env.GWEI_GAS_PRICE),
    },

    ropsten: {
      provider: () =>
        new HDWalletProvider(
          [process.env.PRIVATE_KEY],
          "https://ropsten.infura.io/v3/" + process.env.INFURA_KEY
        ),
      network_id: 3,
      gasPrice: gweiToWei(process.env.GWEI_GAS_PRICE),
    },

    mainnet: {
      provider: () =>
        new HDWalletProvider(
          [process.env.PRIVATE_KEY],
          "https://mainnet.infura.io/v3/" + process.env.INFURA_KEY
        ),
      network_id: 1,
      gasPrice: gweiToWei(process.env.GWEI_GAS_PRICE),
    },
  },

  compilers: {
    solc: {
      version: "0.7.6", // Fetch exact version from solc-bin (default: truffle's version)
      docker: false, // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "istanbul",
      },
    },
  },

  plugins: ["solidity-coverage", "truffle-plugin-verify"],

  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY,
  },
};
