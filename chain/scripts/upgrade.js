const { ethers, upgrades } = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const proxyAddress = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512';
    const AppWorks = await ethers.getContractFactory("AppWorks");
    
  const address = await upgrades.upgradeProxy(proxyAddress, AppWorks);
  
    console.log("Upgrade at:", address);
  }

  main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });