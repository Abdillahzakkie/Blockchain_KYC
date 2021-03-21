// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockchainKYC is ERC721Pausable, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter public tokenIds;
    uint256 private REGGISTRATION_FEE;
    uint256 private _contractEtherBalance;

    mapping(address => Person) public persons;

    struct Person {
        address user;
        uint256 tokenId;
        bool isPrivate;
        bool accredited;
    }

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) public {
        REGGISTRATION_FEE = 0;
        _contractEtherBalance = 0;
    }

    receive() external payable {
        revert("Direct ETH transfer is not allowed");
    }

    function registerUser(address _player, string memory _tokenURI, bool _isPrivate, bool _isAccredited) public onlyOwner returns(uint256 _newUserId) {
        require(persons[_msgSender()].user == address(0), "Account have already been created");
        tokenIds.increment();

        _newUserId = tokenIds.current();
        _safeMint(_player, _newUserId);
        _setTokenURI(_newUserId, _tokenURI);
        persons[_msgSender()] = Person(
            _player,
            _newUserId,
            _isPrivate,
            _isAccredited
        );
        return _newUserId;
    }

    function createAccount(string memory _tokenURI) external payable returns(uint256 _newUserId) {
        require(persons[_msgSender()].user == address(0), "Account have already been created");
        require(msg.value >= REGGISTRATION_FEE, "BlockchainKYC: ETHER amount must >= REGGISTRATION_FEE");

        _contractEtherBalance += REGGISTRATION_FEE;
        if(msg.value > REGGISTRATION_FEE) {
            uint256 _remainingBalance = msg.value - REGGISTRATION_FEE;
            (bool _success, ) = payable(_msgSender()).call{ value: _remainingBalance }("");
            require(_success, "BlockchainKYC: Error while transfering exccess REGGISTRATION_FEE");
        }

        tokenIds.increment();
        _newUserId = tokenIds.current();
        _safeMint(_msgSender(), _newUserId);
        _setTokenURI(_newUserId, _tokenURI);
        persons[_msgSender()] = Person(
            _msgSender(),
            _newUserId,
            true,
            false
        );
        return _newUserId;
    }

    function accredite(uint256 _userId) external onlyOwner returns(bool) {
        address _user = ownerOf(_userId);
        require(!persons[_user].accredited, "BlockchainKYC: account has already been accredited");
        return true;
    }


    function getContractEtherBalance() external view returns(uint256) {
        return _contractEtherBalance;
    }

    function withdraw() external onlyOwner returns(bool) {
        (bool _success, ) = payable(_msgSender()).call{ value: _contractEtherBalance }("");
        require(_success, "BlockchainKYC: Ether transfer failed");
        return true;
    }
}