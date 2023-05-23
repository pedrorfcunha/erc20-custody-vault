const { ethers, run, network } = require("hardhat");
const fs = require("fs");

const frontEndAbiFile = "./constants/custody-vault-abi.json";

async function main() {
    // Deploy CustodyVault contract
    const CustodyVaultFactory = await ethers.getContractFactory("CustodyVault");
    const custodyVault = await CustodyVaultFactory.deploy();
    await custodyVault.deployed();

    const chainId = network.config.chainId;

    console.log("CustodyVault deployed to:", custodyVault.address);

    fs.writeFileSync(
        frontEndAbiFile,

        custodyVault.interface.format(ethers.utils.FormatTypes.json)
    );

    const verify = async (contractAddress, args) => {
        console.log("Verifying contract...");
        try {
            await run("verify:verify", {
                address: contractAddress,
                constructorArguments: args,
            });
        } catch (e) {
            if (e.message.toLowerCase().includes("already verified")) {
                console.log("Already Verified!");
            } else {
                console.log(e);
            }
        }
    };

    if (network.config.chainId === 11155111 && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for block confirmations...");
        await custodyVault.deployTransaction.wait(6);
        await verify(custodyVault.address, []);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
