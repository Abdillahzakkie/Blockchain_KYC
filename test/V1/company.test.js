const Company = artifacts.require('Company');
const { expectEvent } = require("@openzeppelin/test-helpers")
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const { expect, assert } = require('chai');

const toWei = _amount => web3.utils.toWei(_amount.toString());
const fromWei = _amount => web3.utils.fromWei(_amount.toString());

contract("Company", async ([deployer, user1, user2, user3]) => {
    beforeEach(async () => {
        this.contract = await Company.new({ from: deployer });
    })

    describe('deployment', () => {
        it("should deploy contract properly", async () => {
            expect(this.contract.address).not.equal(ZERO_ADDRESS);
            expect(this.contract.address).not.equal('');
            expect(this.contract.address).not.equal(null);
            expect(this.contract.address).not.equal(undefined);
        })
    })

    describe('initialize', () => {
        const _name = "Nameless";

        beforeEach(async () => {
            await this.contract.initialize(_name, { from: deployer });
        })

        it("should initialize contract", async () => {
            const name = await this.contract.name();
            expect(name).to.equal(_name);
        })

        it("should reject if caller is not the creator", async () => {
            try {
                await this.contract.initialize(_name, { from: user1 })
            } catch (error) {
                assert(error.message.includes("Ownable: caller is not the owner"));
                return;
            }
            assert(false);
        })

        it("should reject if contract has already been initialized", async () => {
            try {
                await this.contract.initialize(_name, { from: deployer });
            } catch (error) {
                assert(error.message.includes("Contract has already been initialized"));
                return;
            }
            assert(false);
        })
    })
    
    describe('registerNewUser', () => {
        const _role = "MODERATOR";
        let _reciept;

        beforeEach(async () => {
            _reciept = await this.contract.registerNewUser(user1, _role, { from: deployer });
        })

        it("should register new user", async () => {
            const { account, role , id  } =  await this.contract.members(user1);
            expect(account).to.equal(user1);
            expect(role).to.equal(role);
            expect(id.toString()).to.equal("1");
        })

        it("should reject if caller is not the admin", async () => {
            try {
                await this.contract.registerNewUser(user2, _role, { from: user1 });
            } catch (error) {
                assert(error.message.includes("Ownable: caller is not the owner"));
                return;
            }
            assert(false);
        })

        it("shoule emit NewAccountCreated event", async () => {
            expectEvent(_reciept, "NewAccountCreated", {
                admin: deployer,
                account: user1,
                id: "1",
                role: _role
            });
        })
    })
    
    describe('removeUser', () => {
        let _reciept;

        beforeEach(async () => {
            await this.contract.registerNewUser(user1, "MODERATOR", { from: deployer });
            _reciept = await this.contract.removeUser(user1, { from: deployer });
        })

        it("should remove account", async () => {
            const { account, id, role } = await this.contract.members(user1);
            expect(account).to.equal(ZERO_ADDRESS);
            expect(id.toString()).to.equal('0');
            expect(role).to.equal("");
        })

        it("should reject if account does not exist", async () => {
            try {
                await this.contract.removeUser(user1, { from: deployer });
            } catch (error) {
                assert(error.message.includes("Account doesn't exist"));
                return;
            }
            assert(false);
        })

        it("should reject if caller is not the admin", async () => {
            try {
                await this.contract.removeUser(user1, { from: user1 });
            } catch (error) {
                assert(error.message.includes("Ownable: caller is not the owner"));
                return;
            }
            assert(false);
        })

        it("should emit AccountDeleted event", async () => {
            expectEvent(_reciept, "AccountDeleted", {
                admin: deployer,
                account: user1,
                id: "1"
            });
        })
    })

    describe('updateRole', () => {
        const _newRole = "ADMIN";
        let _reciept;

        beforeEach(async () => {
            await this.contract.registerNewUser(user1, "MODERATOR", { from: deployer });
            _reciept = await this.contract.updateRole(user1, _newRole, { from: deployer });
        })

        it("should update role of an account", async () => {
            const { role } = await this.contract.members(user1);
            expect(role).to.equal(_newRole);
        })


        it("should reject if account does not exist", async () => {
            try {
                await this.contract.updateRole(user2, _newRole, { from: deployer });
            } catch (error) {
                assert(error.message.includes("Account doesn't exist"));
                return;
            }
            assert(false);
        })

        it("should reject if caller is not the admin", async () => {
            try {
                await this.contract.updateRole(user1, _newRole, { from: user1 });
            } catch (error) {
                assert(error.message.includes("Ownable: caller is not the owner"));
                return;
            }
            assert(false);
        })
        
        it("should emit RoleUpdated event", async () => {
            expectEvent(_reciept, "RoleUpdated", {
                admin: deployer,
                account: user1,
                role: _newRole
            });
        })
    })
    
})