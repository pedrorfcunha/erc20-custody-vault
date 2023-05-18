const { ethers } = require("hardhat");

async function main() {
    // Deploy HVC contract
    const HVC = await ethers.getContractFactory("HVC");
    const hvc = await HVC.deploy();

    await hvc.deployed();

    console.log("HVC deployed to:", hvc.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });