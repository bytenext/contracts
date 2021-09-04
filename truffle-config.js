const HDWalletProvider = require('@truffle/hdwallet-provider');
const privateKey = "";
const apiKey = "PGDW32RST6PVSWRCN8W191XQF9DIU5EV1A";

module.exports = {
  networks: {
    development: {
     host: "127.0.0.1", 
     port: 8545,
     network_id: "*",
    },
    testnet: {
      provider: () => new HDWalletProvider(privateKey, `https://data-seed-prebsc-1-s1.binance.org:8545/`),
      network_id: 97,
      confirmations: 3,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    mainnet: {
      provider: () => new HDWalletProvider(privateKey, `https://bsc-dataseed.binance.org`),
      network_id: 56,
      confirmations: 3,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    bscscan: apiKey
  },
  mocha: {
    // timeout: 100000
  },
  compilers: {
    solc: {
       version: "^0.8.0",
    },
  }
};