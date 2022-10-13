require("@nomicfoundation/hardhat-toolbox");

import "@openzeppelin/hardhat-upgrades";

require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
const { API_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;
/** 
 * @type import('hardhat/config').HardhatUserConfig 
 * */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: API_URL,
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY,
  },
};
