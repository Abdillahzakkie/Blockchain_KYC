const VProve = artifacts.require('VProve');

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(VProve, 'VProve', 'VIP', { from: accounts[0] });
}