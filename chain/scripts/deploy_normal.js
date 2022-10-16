const { ethers, upgrades } = require("hardhat");

async function main() {
const AppWorks = await ethers.getContractFactory("AppWorksNormal");
  const appWorks = await AppWorks.deploy();
  await appWorks.deployed();
  console.log(`Deployed to ${appWorks.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});