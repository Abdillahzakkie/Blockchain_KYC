// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract Company is Ownable  {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter public tokenIds;

    string public name;
    uint8 private _initialize;

    mapping(address => Member) public members;

    struct Member {
        address account;
        string role;
        uint256 id;
    }

    modifier initializer() {
        require(_initialize == 0, "Contract has already been initialized");
        _;
        _initialize = 1;
    }

    event NewAccountCreated(
        address indexed admin, 
        address indexed account, 
        uint256 indexed id, 
        string role, 
        uint256 timestamp
    );

    event AccountDeleted(
        address indexed admin, 
        address indexed account, 
        uint256 id, 
        uint256 timestamp
    );

    event RoleUpdated(
        address indexed admin, 
        address indexed account, 
        uint256 timestamp,
        string role
    );

    receive() external payable {
        revert("BlockchainKYC: Direct ETH transfer is not allowed");
    }

    function initialize(string calldata _name) external onlyOwner initializer {
        name = _name;
    }

    function registerNewUser(address _account, string memory _role) public onlyOwner {
        require(members[_account].account == address(0), "Account have already been created");
        tokenIds.increment();

        uint256 _newUserId = tokenIds.current();
        members[_account] = Member(
            _account,
            _role,
            _newUserId
        );
        emit NewAccountCreated(_msgSender(), _account, _newUserId, _role, block.timestamp);
    }

    function removeUser(address _account) external onlyOwner {
        require(members[_account].account != address(0), "Account doesn't exist");
        uint256 _index = members[_account].id;
        members[_account] = Member(address(0), "", 0);
        emit AccountDeleted(_msgSender(), _account, _index, block.timestamp);
    }

    function updateRole(address _account, string memory _newRole) external onlyOwner {
        require(members[_account].account != address(0), "Account doesn't exist");
        members[_account].role = _newRole;
        emit RoleUpdated(_msgSender(), _account, block.timestamp, _newRole);
    }
}