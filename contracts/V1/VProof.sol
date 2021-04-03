// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Company.sol";

/// @title Vprove A Unique Name Token
/// @author Zakriyya Abdullah (DragonLord)
/// @notice This contract create both private accoount and company account
/// @dev All function calls are currently implemented without side effects
contract VProve is ERC721, Ownable  {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter public tokenIds;
    address payable immutable companyImplementation;


    uint256 private REGISTRATION_FEE;
    uint256 private _contractEtherBalance;

    /// @notice Returns an account description containing (address account, uint256 id, string name)
    mapping(address => Description) public persons;

    /// @notice Returns company description at the index of companies[creator][company]
    mapping(address => mapping(address => Description)) public companies;

    /// @notice Returns the ID of a uniquely registered Brand name.
    //    Returns zero for unregistered Brand
    mapping(string => uint256) public brandNameToId;

    struct Description {
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

    /// @param _name Set name of VProve NFT
    /// @param _symbol Set symbol of VProve NFT
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) public {
        companyImplementation = payable(new Company());
        REGISTRATION_FEE = 1 ether;
        _contractEtherBalance = 0;
    }

    receive() external payable {
        revert("VProve: Direct ETH transfer is not allowed");
    }

    /// @param _brandName Accept brand name and passes it to the initialize method of the newly deployed clone contract
    /// @return Returns the address of the newly deployed clone contract
    function deployInstance(string calldata _brandName) internal returns(address payable) {
        // creates a new clone using the deployed companyImplementation contracts in the constructor
        address payable clone = payable(Clones.clone(companyImplementation));

        // initialize the newly deployed clone contract
        Company(clone).initialize(_brandName);

        // returns the clone address
        return clone;
    }
    
    /// @param _name Accept the brand name
    function createPrivateAccount(string calldata _name, string memory _tokenURI) external payable {
        require(persons[_msgSender()].account == address(0), "VProve: Account has already been registered");

        // A flag variable that tracks whether the newly account to be created is Private or Business account
        bool _isPrivate = true;

        // _createAccount returns the ID of the newly created user and address of the user.
        // Note:: The second result returned by _createAccount is not needed since it's the same as msg.sender
        (uint256 _id, ) = _createAccount(_name, _tokenURI, _isPrivate);

        persons[_msgSender()] = Description(
            _msgSender(),
            _id,
            _name
        );

        // emit an event with three arguments:
        // 1. Address of msg.sender
        // 2. Id of the newly created user
        // 3. timestamp of the creation
        emit NewAccountCreated(_msgSender(), _id, block.timestamp);
    }

    function createBussinessAccount(string calldata _brandName, string memory _tokenURI) external payable {
        require(persons[_msgSender()].account != address(0), "VProve: User not registered");

        // A flag variable that tracks whether the newly account to be created is Private or Business account
        bool _isPrivate = false;

        // _createAccount returns the ID of the newly created user and address of the user.
        // Note:: The second result returned by _createAccount is the address of the newly deployed clone contract
        (uint256 _id, address _clonedContractAddress) = _createAccount(_brandName, _tokenURI, _isPrivate);

        companies[_msgSender()][_account] = Description(
            _clonedContractAddress,
            _id,
            _brandName
        );

        // emit an event with three arguments:
        // 1. Address of the creator (msg.sender)
        // 2. Address of the deployed cloned contract
        // 3. Id of the newly created company
        // 4. timestamp of the creation
        emit NewComapanyCreated(_msgSender(), _clonedContractAddress, _id, block.timestamp);
    }

    function _createAccount(string calldata _brandName, string memory _tokenURI, bool _private) internal returns(uint256, address) {
        require(msg.value >= REGISTRATION_FEE, "VProve: ETHER amount must >= REGISTRATION_FEE");
        require(brandNameToId[_brandName] == 0, "VProve: Name has already been taken");
        require(!isNull(_brandName), "VProve: 'Name' must not be blank");

        address payable _account = _msgSender();

        _contractEtherBalance = _contractEtherBalance.add(REGISTRATION_FEE);

        // checks whether msg.value > REGISTRATION_FEE
        // transfer excess amount back to msg.sender
        if(msg.value > REGISTRATION_FEE) {
            uint256 _excessAmount = msg.value.sub(REGISTRATION_FEE);
            (bool _success, ) = payable(_msgSender()).call{ value: _excessAmount }("");
            require(_success, "VProve: Error while transfering exccess REGISTRATION_FEE");
        }

        tokenIds.increment();
        uint256 _id = tokenIds.current();
        
        _safeMint(_msgSender(), _id);
        _setTokenURI(_id, _tokenURI);

        // map _brandName to token ID
        brandNameToId[_brandName] = _id;

        // checks if _private = false
        // if _private = false, create a new Company contract using "companyImplementation" above
        if(!_private) _account = deployInstance(_brandName);

        // return token ID and the _account
        // Note:: _account = _msgSender() if isPrivate = true
        // else _account = new deployed Company's clone address
        return (_id, _account);
    }

    function getContractEtherBalance() external view returns(uint256) {
        return _contractEtherBalance;
    }

    function getRegistrationFees() external view returns(uint256) {
        return REGISTRATION_FEE;
    }

    function setRegistrationFees(uint256 _newAmount) external onlyOwner {
        REGISTRATION_FEE = _newAmount;
    }

    function withdraw() external onlyOwner {
        uint256 _amount = _contractEtherBalance;
        _contractEtherBalance = 0;
        (bool _success, ) = payable(_msgSender()).call{ value: _amount }("");
        require(_success, "VProve: Ether withdrawal failed");
    }

    /// @notice This function checks whether the hash of the param matches that of an empty string
    /// @param _data String
    /// @return Returns true if the hash of the param matches the hash of an empty string
    function isNull(string memory _data) internal pure returns(bool) {
        return keccak256(abi.encodePacked(_data)) == keccak256(abi.encodePacked(""));
    }
}