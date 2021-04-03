const VProve = artifacts.require('VProve');
const { expectEvent } = require("@openzeppelin/test-helpers")
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const { expect, assert } = require('chai');

const toWei = _amount => web3.utils.toWei(_amount.toString());
const fromWei = _amount => web3.utils.fromWei(_amount.toString());

contract('VProve', async ([deployer, user1, user2]) => {
    const _name = "VProve";
    const _symbol = "ITM";

    beforeEach(async () => {
        this.contract = await VProve.new(_name, _symbol, { from: deployer });
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

        it('should set REGISTRATION_FEE to ZERO', async () => {
            const getRegistrationFees = await this.contract.getRegistrationFees();
            expect(getRegistrationFees.toString()).to.equal(toWei(1));
        })

        it('should set _contractEtherBalance to ZERO', async () => {
            const getContractEtherBalance = await this.contract.getContractEtherBalance();
            expect(getContractEtherBalance.toString()).to.equal('0');
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

    describe('createPrivateAccount', () => {
        const _name = "Nameless";
        const _tokenURI = "TokenURI";
        let _amount;
        let _reciept;

        beforeEach(async () => {
            _amount = (await this.contract.getRegistrationFees()).toString();
            _reciept = await this.contract.createPrivateAccount(_name, _tokenURI, { from: user1, value: _amount });
        })

        it('should create a private account', async () => {
            const { account, name, id } = await this.contract.persons(user1);
            const ownerOf = await this.contract.ownerOf('1');

            expect(account).to.equal(user1);
            expect(ownerOf).to.equal(account);
            expect(id.toString()).to.equal('1');
            expect(name).to.equal(_name);
        })

        it("should track REGISTRATION_FEE properly", async () => {
            const getContractEtherBalance = await this.contract.getContractEtherBalance();
            const getRegistrationFees = await this.contract.getRegistrationFees();
            expect(getContractEtherBalance.toString()).to.equal(getRegistrationFees.toString());
        })

        it("should reject if name field is blank", async () => {
            try {
                await this.contract.createPrivateAccount("", _tokenURI, { from: user2, value: _amount });
            } catch (error) {
                assert(error.message.includes("VProve: 'Name' must not be blank"));
                return;
            }
            assert(false);
        })

        it("should reject duplicate accounts", async () => {
            try {
                await this.contract.createPrivateAccount(_name, _tokenURI, { from: user1, value: _amount });
            } catch (error) {
                assert(error.message.includes("VProve: Account has already been registered"));
                return;
            }
            assert(false);
        })

        it("should reject if ETH sent is less than registration fee", async () => {
            try {
                _amount = parseInt(
                    (await this.contract.getRegistrationFees()).toString()
                ) - toWei(.002);
                await this.contract.createPrivateAccount(_name, _tokenURI, { from: user2, value: _amount.toString() });
            } catch (error) {
                assert(error.message.includes("VProve: ETHER amount must >= REGISTRATION_FEE"));
                return;
            }
            assert(false);
        })

        it("should reject if name have already been taken", async () => {
            try {
                await this.contract.createPrivateAccount(_name, _tokenURI, { from: user2, value: _amount });
            } catch (error) {
                assert(error.message.includes("VProve: Name has already been taken"));
                return;
            }
            assert(false);
        })

        it("should emit NewAccountCreated event", async () => {
            expectEvent(_reciept, "NewAccountCreated", {
                user: user1,
                id: "1"
            });
        })
    })

    describe('createBussinessAccount', () => {
        const _name = "My Comapny";
        const _tokenURI = "TokenURI";
        let _amount;
        let _reciept;
        let creator;
        let company;

        beforeEach(async () => {
            _amount = (await this.contract.getRegistrationFees()).toString();
            await this.contract.createPrivateAccount("Nameless", _tokenURI, { from: user1, value: _amount });
            _reciept = await this.contract.createBussinessAccount(_name, _tokenURI, { from: user1, value: _amount });

            const _result = _reciept.receipt.logs[_reciept.receipt.logs.length - 1].args;
            creator = _result.creator;
            company = _result.company;
        })

        it('should create a bussiness account', async () => {
            const { account, name, id } = await this.contract.companies(user1, company);
            const ownerOf = await this.contract.ownerOf('2');

            expect(account).to.equal(company);
            expect(ownerOf).to.equal(creator);
            expect(id.toString()).to.equal('2');
            expect(name).to.equal(_name);
        })

        it("should track REGISTRATION_FEE properly", async () => {
            const getContractEtherBalance = fromWei(await this.contract.getContractEtherBalance());
            const getRegistrationFees = fromWei(await this.contract.getRegistrationFees());
            expect(getContractEtherBalance).to.equal((parseFloat(getRegistrationFees) * 2).toString());
        })

        it("should reject if name field is blank", async () => {
            try {
                await this.contract.createPrivateAccount("Unknown", _tokenURI, { from: user2, value: _amount });
                await this.contract.createBussinessAccount("", _tokenURI, { from: user2, value: _amount });
            } catch (error) {
                assert(error.message.includes("VProve: 'Name' must not be blank"));
                return;
            }
            assert(false);
        })

        it("should reject if name have already been taken", async () => {
            try {
                await this.contract.createPrivateAccount("Unknown", _tokenURI, { from: user2, value: _amount });
                await this.contract.createBussinessAccount(_name, _tokenURI, { from: user2, value: _amount });
            } catch (error) {
                assert(error.message.includes("VProve: Name has already been taken"));
                return;
            }
            assert(false);
        })

        it("should reject if ETH sent is less than registration fee", async () => {
            try {
                _amount = parseInt(
                    (await this.contract.getRegistrationFees()).toString()
                ) - toWei(.002);
                await this.contract.createPrivateAccount(_name, _tokenURI, { from: user2, value: _amount });
                await this.contract.createBussinessAccount(_name, _tokenURI, { from: user2, value: _amount.toString() });
            } catch (error) {
                assert(error.message.includes("VProve: ETHER amount must >= REGISTRATION_FEE"));
                return;
            }
            assert(false);
        })

        it("should emit NewComapanyCreated event", async () => {
            expectEvent(_reciept, "NewComapanyCreated", {
                creator,
                company,
                id: "2"
            });
        })
    })  
    
    describe('setRegistrationFees', () => {
        beforeEach(async () => {
            await this.contract.setRegistrationFees('0', { from: deployer });
        })

        it("should update REGISTRATION_FEE", async () => {
            const getRegistrationFees = await this.contract.getRegistrationFees();
            expect(getRegistrationFees.toString()).to.equal('0');
        })

        it("should reject if caller is not the owner", async () => {
            try {
                await this.contract.setRegistrationFees('0', { from: user1 });
            } catch (error) {
                assert(error.message.includes("Ownable: caller is not the owner"));
                return; 
            }
            assert(false);
        })
    })

    describe('brandNameToId', () => {
        const _name = "Nameless";
        let _amount;

        beforeEach(async () => {
            _amount = (await this.contract.getRegistrationFees()).toString();
            await this.contract.createPrivateAccount(_name, "TokenURI", { from: user1, value: _amount });
        })

        it("should return registered brand name", async () => {
            const brandNameToOwner = await this.contract.brandNameToOwner(_name);
            expect(brandNameToOwner).to.equal(user1);
        })

        it("should returns blank string if name is not registered", async () => {
            const brandNameToOwner = await this.contract.brandNameToOwner("Unknow");
            expect(brandNameToOwner.toString()).to.equal(ZERO_ADDRESS);
        })
    })
    
    
})