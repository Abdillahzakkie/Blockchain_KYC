const GameItem = artifacts.require('GameItem');
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');
const { expect, assert } = require('chai');

contract('GameItem', async ([deployer, user1, user2]) => {
    const _name = "GameItem";
    const _symbol = "ITM";

    beforeEach(async () => {
        this.contract = await GameItem.new(_name, _symbol, { from: deployer });
    })

    describe('deployment', () => {
        it('should deploy contract properly', async () => {
            expect(this.contract.address).not.equal(ZERO_ADDRESS);
            expect(this.contract.address).not.equal('');
            expect(this.contract.address).not.equal(null);
            expect(this.contract.address).not.equal(undefined);
        })

        it('should set name properly', async () => {
            const name = await this.contract.name();
            expect(name).to.equal(_name);
        })

        it('should set symbol properly', async () => {
            const symbol = await this.contract.symbol();
            expect(symbol).to.equal(_symbol);
        })
    })

    describe('balanceOf', () => {
        it('should return balance of account', async () => {
            const balanceOfDeployer = await this.contract.balanceOf(deployer);
            expect(balanceOfDeployer.toString()).to.equal('0')
        })


        it('should reject if account is ZERO ADDRESS', async () => {
            try {
                await this.contract.balanceOf(ZERO_ADDRESS);
            } catch (error) {
                assert(error.message.includes('ERC721: balance query for the zero address'));
                return;
            }
            assert(false);
        })
    })
    
    describe('ownerOf', () => {
        beforeEach(async () => {
            await this.contract.awardItem(deployer, 'TokenURI', { from: deployer });
        })

        it('should return of a token Id', async () => {
            const ownerOf = await this.contract.ownerOf('1');
            expect(ownerOf).to.equal(deployer);
        })

        it('should reject if token does not exist', async () => {
            try {
                await this.contract.ownerOf('2');
            } catch (error) {
                assert(error.message.includes('ERC721: owner query for nonexistent token'));
                return;
            }
            assert(false);
        })
    })
    
    describe('tokenURI', () => {
        beforeEach(async () => {
            await this.contract.awardItem(deployer, 'TokenURI', { from: deployer })
        })

        it('should return tokenURI', async () => {
            const tokenURI = await this.contract.tokenURI('1');
            expect(tokenURI).to.equal('TokenURI');
        })

        it('should reject if token does not exist', async () => {
            try {
                await this.contract.tokenURI('2');
            } catch (error) {
                assert(error.message.includes("ERC721Metadata: URI query for nonexistent token"));
                return;
            }
            assert(false);
        })
    })
    
    describe('approve', () => {
        const _tokenURI = "TokenURI";
        const _tokenId = "1";


        beforeEach(async () => {
            await this.contract.awardItem(deployer, _tokenURI, { from: deployer });
        })

        it('should set approval properly', async () => {
            await this.contract.approve(user1, _tokenId,{ from: deployer });
            const getApproved = await this.contract.getApproved(_tokenId);
            expect(getApproved).to.equal(user1);
        })

        it('should approve if the reciepient have been approved for all', async () => {
            await this.contract.setApprovalForAll(user1,  true, { from: deployer })
            await this.contract.approve(user2, _tokenId,{ from: user1 });

            const getApproved = await this.contract.getApproved(_tokenId);
            expect(getApproved).to.equal(user2);
        })

        it('should reject if the caller is not the owner', async () => {
            try {
                await this.contract.approve(user1, _tokenId,{ from: user2 });
            } catch (error) {
                assert(error.message.includes("ERC721: approve caller is not owner nor approved for all"));
                return;
            }
            assert(false);
        })
    })

    describe('setApprovalForAll', () => {
        beforeEach(async () => {
            await this.contract.awardItem(deployer, "TOkenURI", { from: deployer });
            await this.contract.setApprovalForAll(user1, true, { from: deployer });
        })

        it('should setApprovalForAll for a single user', async () => {
            const isApprovedForAll = await this.contract.isApprovedForAll(deployer, user1);
            expect(isApprovedForAll).to.equal(true);
        })

        it('should cancel setApprovalForAll', async () => {
            await this.contract.setApprovalForAll(user1, false, { from: deployer });
            const isApprovedForAll = await this.contract.isApprovedForAll(deployer, user1);
            expect(isApprovedForAll).to.equal(false);
        })
    })
    
    


    describe('awardItem', () => {
        beforeEach(async () => {
            await this.contract.awardItem(deployer, 'TokenURI', { from: deployer });
        })

        it('should award new item to user', async () => {
            const balanceOfDeloyer = await this.contract.balanceOf(deployer);
            expect(balanceOfDeloyer.toString()).to.equal('1');
        })

        it('should set token owner properly', async () => {
            const ownerOf = await this.contract.ownerOf('1');
            expect(ownerOf).to.equal(deployer);
        })
    })
})