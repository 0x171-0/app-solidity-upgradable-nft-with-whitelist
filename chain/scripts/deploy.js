const hre = require("hardhat");

async function main() {
  const AppWorks = await hre.ethers.getContractFactory("AppWorks");
  const appWorks = await AppWorks.deploy();
  await appWorks.deployed();
  console.log(`Deployed to ${appWorks.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
