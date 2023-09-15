const {expect} = require('chai');
const {ethers} = require('hardhat');

const run = async () => {
    describe('Testing functionality', () => {
        let nftContract, marketplace, externalMarketplace, investDAO, deployer, user1, user2, user3;

        beforeEach(async () => {
            [deployer, user1, user2, user3] = await ethers.getSigners();
            nftContract = await ethers.deployContract('NftContract');
            await nftContract.waitForDeployment();
            marketplace = await ethers.deployContract('Marketplace', [nftContract.target]);
            await marketplace.waitForDeployment()
            externalMarketplace = await ethers.deployContract('ExternalMarketplace');
            await externalMarketplace.waitForDeployment();
            investDAO = await ethers.deployContract('InvestDAO', [nftContract.target, externalMarketplace.target, marketplace.target]);
            await investDAO.waitForDeployment();
        });

        const marketplaceTransactions = async () => {
            await marketplace.connect(user1).purchase(0, {value: ethers.parseUnits('0.00001', 'ether')});
            await marketplace.connect(user1).purchase(4, {value: ethers.parseUnits('0.00001', 'ether')});
            await marketplace.connect(user1).purchase(2, {value: ethers.parseUnits('0.00001', 'ether')});
            await marketplace.connect(user2).purchase(7, {value: ethers.parseUnits('0.00001', 'ether')});
            await marketplace.connect(user2).purchase(5, {value: ethers.parseUnits('0.00001', 'ether')});
        }

        it('Complete test', async () => {
            for(var i=0;i<10;i++) {
                await nftContract.mint(`metadata${i}`);
            }
            await nftContract.setApprovalForAll(marketplace.target, true);
            await marketplaceTransactions();
            expect(await nftContract.ownerOf(0)).to.equal(user1.address);
            await investDAO.createProposal(2);
            await investDAO.connect(user1).vote(0, 0);
            await investDAO.connect(user2).vote(0, 1);
            console.log('waiting to decide on the proposal');
            setTimeout(async () => {
                const proposals = await investDAO.proposals();
                console.log(proposals[0].yayVotes, proposals[0].nayVotes);
                await investDAO.executeProposal(0);
                expect(await externalMarketplace.available(2)).to.equal(false);
            }, 120*1000);
        });
    });
    
}

run().catch((error) => {console.log(error)});