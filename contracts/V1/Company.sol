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

    mapping(address => Member) private members;

    struct Member {
        address account;
        string role;
        uint8 id;
    }

    modifier initializer() {
        require(_initialize == 0, "Contract has already been initialized");
        _;
        _initialize = 1;
    }

    event NewAccountCreated(address indexed account, uint8 indexed id, string role, uint256 timestamp);
    event AccountDeleted(address indexed account, uint8 id, uint256 timestamp);

    receive() external payable {
        revert("BlockchainKYC: Direct ETH transfer is not allowed");
    }

    function initialize(string calldata _name) external initializer {
        name = _name;
    }

    function register(address _account, string memory _role) public onlyOwner {
        require(members[_account].account == address(0), "BlockchainKYC: Account have already been created");
        tokenIds.increment();

        uint8 _newUserId = uint8(tokenIds.current());
        members[_account] = Member(
            _account,
            _role,
            _newUserId
        );
        emit NewAccountCreated(_account, _newUserId, _role, block.timestamp);
    }

    function removeUser(address _account) external onlyOwner {
        require(members[_account].account != address(0), "account doesn't exist");
        uint8 _index = uint8(members[_account].id);
        members[_account] = Member(address(0), "", 0);
        emit AccountDeleted(_account, _index, block.timestamp);
    }
}