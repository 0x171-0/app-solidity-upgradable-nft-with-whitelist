const { expect } = require('chai');

// refs: https://hardhat.org/tutorial/testing-contracts
describe("AppWorks contract", function () {
  let AppWorks;
  let contract;
  let _name = "Eye";
  let _symbol = "EVE";
  let account1, otheraccounts;

  beforeEach(async function () {
      AppWorks = await ethers.getContractFactory("AppWorks");
      [owner, account1, ...otheraccounts] = await ethers.getSigners();
      contract = await upgrades.deployProxy(AppWorks, [_name, _symbol]);

  });

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {
    it("Should has the correct configuration", async function () {
      expect(await contract.name()).to.equal(_name);
      expect(await contract.symbol()).to.equal(_symbol);
      expect(await contract.mintActive()).to.equal(false);
      expect(await contract.earlyMintActive()).to.equal(false);
      expect(await contract.revealed()).to.equal(false);
    });

    it("Should not be able to mint, if mintActive is false", async function () {
      expect(await contract.mintActive()).to.equal(false);
      expect(await contract.mint(1, { value: ethers.utils.parseEther("0.01") })).to.be.reverted;
    });

    it("Should be able to mint, if mintActive is true", async function () {
      expect(await contract.toggleMintActive())
      expect(await contract.mintActive()).to.equal(true);
      expect(
        await contract.mint(1, { value: ethers.utils.parseEther("0.001") })
      ).to.be.revertedWith("Public Mint is not yet started");
    });


    // it("Should mint a token with token ID 1 & 2 to account1", async function () {
    //   const address1 = account1.address;
    //   await contract.mint(address1);
    //   expect(await contract.balance(address1)).to.equal(1);

    //   await contract.mint(address1);
    //   expect(await contract.balance(address1)).to.equal(2);

    // });
  });
});