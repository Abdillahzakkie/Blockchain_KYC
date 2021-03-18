const GameItem = artifacts.require('GameItem');

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(GameItem, 'GameItem', 'ITM', { from: accounts[0] });
}