require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
const { ethers } = require("hardhat");
const { CRYPTO_DEVS_NFT_CONTRACT_ADDRESS } = require("../constants");

const cryptoDevsNFTContract = CRYPTO_DEVS_NFT_CONTRACT_ADDRESS;

async function main() {
  const fakeNFTMarketplace = await ethers.getContractFactory(
    "FakeNFTMarketplace"
  );
  const deployedFakeNFTMarketplace = await fakeNFTMarketplace.deploy();
  await deployedFakeNFTMarketplace.deployed();

  console.log(
    `FakeNFTMarketplace deployed to ${deployedFakeNFTMarketplace.address}`
  );

  const cryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO");
  const deployedCryptoDevsDAO = await cryptoDevsDAO.deploy(
    deployedFakeNFTMarketplace.address,
    cryptoDevsNFTContract,
    {
      value: ethers.utils.parseEther("0.01"),
    }
  );
  await deployedCryptoDevsDAO.deployed();

  console.log(`CryptoDevsDAO deployed to:${deployedCryptoDevsDAO.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
