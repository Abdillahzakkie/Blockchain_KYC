// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GameItem is ERC721Pausable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) public {  }

    function awardItem(address _player, string memory _tokenURI) public returns(uint256 _newItemId) {
        _tokenIds.increment();

        _newItemId = _tokenIds.current();
        _safeMint(_player, _newItemId);
        _setTokenURI(_newItemId, _tokenURI);
        return _newItemId;
    }
}