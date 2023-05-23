const { ethers, run, network } = require("hardhat");
const fs = require("fs");

const frontEndAbiFile = "./constants/hvc-token-abi.json";

async function main() {
    // Deploy HVC contract
    const HVC = await ethers.getContractFactory("HVC");
    const hvc = await HVC.deploy();
    await hvc.deployed();

    console.log("HVC Token deployed to:", hvc.address);

    const chainId = network.config.chainId;

    fs.writeFileSync(
        frontEndAbiFile,

        hvc.interface.format(ethers.utils.FormatTypes.json)
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
        await hvc.deployTransaction.wait(6);
        await verify(hvc.address, []);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
