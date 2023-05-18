const { ethers } = require("hardhat");

async function main() {
    // Deploy HVC contract
    const CustodyVaultFactory = await ethers.getContractFactory("CustodyVault");
    const custodyVault = await CustodyVaultFactory.deploy();

    await custodyVault.deployed();

    console.log("CustodyVault deployed to:", custodyVault.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
