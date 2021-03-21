const BlockchainKYC = artifacts.require('BlockchainKYC');

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(BlockchainKYC, 'GameItem', 'ITM', { from: accounts[0] });
}