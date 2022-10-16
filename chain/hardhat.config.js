require('@openzeppelin/hardhat-upgrades');
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

require("dotenv").config();

const { API_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;
/** 
 * @type import('hardhat/config').HardhatUserConfig 
 * */
module.exports = {
  solidity: "0.8.9",
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
