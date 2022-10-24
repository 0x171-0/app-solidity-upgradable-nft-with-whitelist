const { ethers, upgrades } = require("hardhat");

async function main() {
  let _name = "Eye";
  let _symbol = "EYE";
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ImplementationContract = await ethers.getContractFactory("AppWorks");

  proxyContract = await upgrades.deployProxy(ImplementationContract, [_name, _symbol]);

  console.log(`Deployed to ${proxyContract.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
