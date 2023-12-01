const { network, deployments, ethers } = require("hardhat");
const { expect } = require("chai");

describe("Custody vault", () => {
    let custodyVault;
    let owner;
    let trustee;
    let nonTrustee;
    let token;
    let allowedTokenAddress;
    let allowedSender;
    beforeEach(async () => {
        [owner, trustee, nonTrustee, allowedSender] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("HVC");
        token = await Token.deploy();
        await token.deployed();
        allowedTokenAddress = token.address;

        const CustodyVault = await ethers.getContractFactory("CustodyVault");
        custodyVault = await CustodyVault.deploy();
        await custodyVault.deployed();
    });

    it("should deploy the contract correctly", async () => {
        expect(custodyVault.address).to.not.equal(0);
        expect(custodyVault.deployTransaction).to.not.be.undefined;
    });

    describe("Trustee Management", function () {
        it("should set trustee address", async function () {
            await custodyVault
                .connect(owner)
                .setTrusteeAddress(trustee.address);
            expect(await custodyVault.isTrustee(trustee.address)).to.be.true;
        });

        it("should prevent non-trustees from setting trustee address", async function () {
            await expect(
                custodyVault
                    .connect(nonTrustee)
                    .setTrusteeAddress(trustee.address)
            ).to.be.revertedWithCustomError(
                custodyVault,
                "CustodyVault__NotTrustee"
            );
        });

        it("should allow setting a token by trustee", async function () {
            await custodyVault
                .connect(owner)
                .setAllowedTokens(allowedTokenAddress);
            expect(await custodyVault.isTokenAllowed(allowedTokenAddress)).to.be
                .true;
        });

        it("should prevent non-trustees from setting allowed tokens", async function () {
            await expect(
                custodyVault
                    .connect(nonTrustee)
                    .setAllowedTokens(allowedTokenAddress)
            ).to.be.revertedWithCustomError(
                custodyVault,
                "CustodyVault__NotTrustee"
            );
        });

        it("should allow setting a sender by trustee", async function () {
            await custodyVault
                .connect(owner)
                .setAllowedSenders(allowedSender.address);
            expect(await custodyVault.isAddressAllowed(allowedSender.address))
                .to.be.true;
        });

        it("should prevent non-trustees from setting allowed senders", async function () {
            await expect(
                custodyVault
                    .connect(nonTrustee)
                    .setAllowedSenders(allowedSender.address)
            ).to.be.revertedWithCustomError(
                custodyVault,
                "CustodyVault__NotTrustee"
            );
        });
    });

    describe("Transfer/Deposit Functionality", function () {
        beforeEach(async function () {
            const mintAmount = 100;
            await custodyVault
                .connect(owner)
                .setAllowedTokens(allowedTokenAddress);
            await custodyVault
                .connect(owner)
                .setAllowedSenders(allowedSender.address);
            await custodyVault
                .connect(owner)
                .setTrusteeAddress(trustee.address);
            await token.connect(owner).mint(allowedSender.address, mintAmount);
            await token
                .connect(allowedSender)
                .approve(custodyVault.address, mintAmount);
        });

        it("should allow deposit for allowed token and sender", async function () {
            await custodyVault
                .connect(allowedSender)
                .deposit(allowedTokenAddress, 10, trustee.address, 1);

            const deposit = (await custodyVault.getAllDeposits())[0];
            await expect(deposit.senderAddress).to.equal(allowedSender.address);
            await expect(deposit.receiverAddress).to.equal(trustee.address);
            await expect(deposit.amount).to.equal(10);
        });

        it("should reject deposit for unallowed address", async function () {
            await expect(
                custodyVault
                    .connect(nonTrustee)
                    .deposit(token.address, 10, trustee.address, 1)
            ).to.be.revertedWith("Address not registered");
        });

        it("should correctly report the status of a pending transfer", async function () {
            await custodyVault
                .connect(allowedSender)
                .deposit(allowedTokenAddress, 10, trustee.address, 1);
            const status = await custodyVault.getTransferStatus(0);
            expect(status).to.equal("Pending");
        });

        it("should correctly report the status of a approved transfer", async function () {
            const depositId = 0;
            await custodyVault
                .connect(allowedSender)
                .deposit(allowedTokenAddress, 10, trustee.address, 1);
            let status = await custodyVault.getTransferStatus(depositId);
            expect(status).to.equal("Pending");

            await custodyVault.connect(trustee).approveTransfer(depositId);
            status = await custodyVault.getTransferStatus(depositId);
            expect(status).to.equal("Transferred");
        });

        it("should reject approval from non-trustees", async function () {
            const depositId = 0;
            await custodyVault
                .connect(allowedSender)
                .deposit(allowedTokenAddress, 10, trustee.address, 1);
            await expect(
                custodyVault.connect(nonTrustee).approveTransfer(depositId)
            ).to.be.revertedWithCustomError(
                custodyVault,
                "CustodyVault__NotTrustee"
            );
        });

        it("should correctly report the status of a reverted transfer", async function () {
            const depositId = 0;
            await custodyVault
                .connect(allowedSender)
                .deposit(allowedTokenAddress, 10, trustee.address, 1);
            let status = await custodyVault.getTransferStatus(depositId);
            expect(status).to.equal("Pending");

            await custodyVault.connect(trustee).revertTransfer(depositId);
            status = await custodyVault.getTransferStatus(depositId);
            expect(status).to.equal("Reverted");
        });

        it("should reject reversion from non-trustees", async function () {
            const depositId = 0;
            await custodyVault
                .connect(allowedSender)
                .deposit(allowedTokenAddress, 10, trustee.address, 1);
            await expect(
                custodyVault.connect(nonTrustee).revertTransfer(depositId)
            ).to.be.revertedWithCustomError(
                custodyVault,
                "CustodyVault__NotTrustee"
            );
        });
    });
});
