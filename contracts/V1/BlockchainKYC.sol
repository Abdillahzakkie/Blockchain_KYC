// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Company.sol";

contract BlockchainKYC is ERC721Pausable, Ownable  {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter public tokenIds;
    address payable immutable companyImplementation;


    uint256 private REGISTRATION_FEE;
    uint256 private _contractEtherBalance;

    mapping(address => Person) public persons;
    mapping(address => mapping(address => Person)) public companies;

    struct Person {
        address account;
        uint256 id;
        string name;
    }

    event NewAccountCreated(
        address indexed user, 
        uint256 indexed id, 
        uint256 timestamp
    );

    event NewComapanyCreated(
        address indexed creator, 
        address indexed company, 
        uint256 indexed id, 
        uint256 timestamp
    );

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) public {
        companyImplementation = payable(new Company());
        REGISTRATION_FEE = 1 ether;
        _contractEtherBalance = 0;
    }

    receive() external payable {
        revert("BlockchainKYC: Direct ETH transfer is not allowed");
    }

    function deployInstance(string calldata name) internal returns(address payable) {
        address payable clone = payable(Clones.clone(companyImplementation));
        Company(clone).initialize(name);
        return clone;
    }
    function createPrivateAccount(string calldata _name, string memory _tokenURI) external payable {
        require(persons[_msgSender()].account == address(0), "BlockchainKYC: Duplicate registration found!");
        bool _isPrivate = true;
        (uint256 _id, ) = _createAccount(_name, _tokenURI, _isPrivate);
        persons[_msgSender()] = Person(
            _msgSender(),
            _id,
            _name
        );
        emit NewAccountCreated(_msgSender(), _id, block.timestamp);
    }

    function createBussinessAccount(string calldata _name, string memory _tokenURI) external payable {
        require(persons[_msgSender()].account != address(0), "BlockchainKYC: User not registered");

        bool _isPrivate = false;
        (uint256 _id, address _account) = _createAccount(_name, _tokenURI, _isPrivate);

        companies[_msgSender()][_account] = Person(
            _account,
            _id,
            _name
        );
        emit NewComapanyCreated(_msgSender(), _account, _id, block.timestamp);
    }

    function _createAccount(string calldata _name, string memory _tokenURI, bool _isPrivate) internal returns(uint256, address) {
        require(msg.value >= REGISTRATION_FEE, "BlockchainKYC: ETHER amount must >= REGISTRATION_FEE");
        require(!isNull(_name), "BlockchainKYC: 'Name' must not be blank");
        address payable _account = _msgSender();
        

        _contractEtherBalance = _contractEtherBalance.add(REGISTRATION_FEE);
        if(msg.value > REGISTRATION_FEE) {
            uint256 _remainingBalance = msg.value.sub(REGISTRATION_FEE);
            (bool _success, ) = payable(_msgSender()).call{ value: _remainingBalance }("");
            require(_success, "BlockchainKYC: Error while transfering exccess REGISTRATION_FEE");
        }

        tokenIds.increment();
        uint256 _id = tokenIds.current();
        
        _safeMint(_msgSender(), _id);
        _setTokenURI(_id, _tokenURI);

        if(!_isPrivate) _account = deployInstance(_name);
        return (_id, _account);
    }

    function getContractEtherBalance() external view returns(uint256) {
        return _contractEtherBalance;
    }

    function isContract(address _account) internal view returns(bool) {
        uint256 _size;
        assembly {
            _size := extcodesize(_account)
        }
        if(_size > 0) return true;
        return false;
    }

    function getRegistrationFees() external view returns(uint256) {
        return REGISTRATION_FEE;
    }

    function withdraw(address _tokenAddress, uint256 _amount) external onlyOwner returns(bool) {
        if(_tokenAddress != address(0) && _amount > 0) {
            // Checks whether the "_tokenAddress" is a contract
            if(!isContract(_tokenAddress)) return false;
            (bool _success, ) = _tokenAddress.call{ value: 0 }(abi.encodeWithSignature("transfer(address,uint256)", _msgSender(), _amount));
            require(_success, "BlockchainKYC: Error while interracting with token contract");
            return true;
        }

        uint256 _withdrawAmount = _amount > 0 ? _amount : _contractEtherBalance;
        _contractEtherBalance = _contractEtherBalance.sub(_withdrawAmount);
        (bool _success, ) = payable(_msgSender()).call{ value: _withdrawAmount }("");
        require(_success, "BlockchainKYC: Ether withdrawal failed");
        return true;
    }

    function isNull(string memory _data) internal pure returns(bool) {
        return keccak256(abi.encodePacked(_data)) == keccak256(abi.encodePacked(""));
    }
}