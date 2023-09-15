const hre = require('hardhat');

async function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
    // deploy all contracts
    const nftContract = await hre.ethers.deployContract("NftContract");
    await nftContract.waitForDeployment();
    console.log("Nft Contract at:", nftContract.target);
    const marketplace = await hre.ethers.deployContract("Marketplace", [nftContract.target]);
    await marketplace.waitForDeployment();
    console.log("Marketplace at:", marketplace.target);
    const extMarketplace = await hre.ethers.deployContract("ExternalMarketplace");
    await extMarketplace.waitForDeployment();
    console.log("External marketplace at:", extMarketplace.target);
    const investDAO = await hre.ethers.deployContract("InvestDAO", [nftContract.target, extMarketplace.target, marketplace.target]);
    await investDAO.waitForDeployment();
    console.log("Invest DAO at:", investDAO.target);

    await sleep(30*1000);

    await hre.run("verify: verify", {
        address: nftContract.target,
        constructorArguments: [],
    });

    await hre.run("verify: verify", {
        address: marketplace.target,
        constructorArguments: [nftContract.target],
    });

    await hre.run("verify: verify", {
        address: extMarketplace.target,
        constructorArguments: [],
    });

    await hre.run("verify: verify", {
        address: investDAO.target,
        constructorArguments: [nftContract.target, extMarketplace.target, marketplace.target],
    });
}

main().catch((err) => {console.log(err)});