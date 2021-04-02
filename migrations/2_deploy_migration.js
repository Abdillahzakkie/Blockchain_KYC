const VProof = artifacts.require('VProof');

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(VProof, 'VProof', 'VIP', { from: accounts[0] });
}