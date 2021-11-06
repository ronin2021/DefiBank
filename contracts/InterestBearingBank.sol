// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
*
*/

contract DBank {
    // 
    mapping(address => bool) public isDeposited;
    mapping(address => uint) public etherBalanceOf;
    mapping(address => uint) public depositStart;

    address payable supplier;
    uint public interestSupply;

    uint public fakeNow;

    constructor () payable {
        supplier = payable(msg.sender);
        fakeNow = block.timestamp;
        interestSupply += msg.value;
    }

    function fastForward() public {
        fakeNow += 100 days;
    }

    function cleanSlate() public OnlySupplier {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function balanceOfContract() public view returns(uint) {
        return payable(address(this)).balance;
    }

    modifier OnlySupplier() {
        require(msg.sender == supplier);
        _;
    }

    function supplyEth() payable public OnlySupplier {
        interestSupply += msg.value;
    }
    
    function deposit() payable public {
        require(isDeposited[msg.sender] == false, 'Error, deposit already active');
        require(msg.value >= 1e16, 'Error, deposit must be >= 0.01 ETH');

        etherBalanceOf[msg.sender] = msg.value;
        isDeposited[msg.sender] = true;
        depositStart[msg.sender] = fakeNow;
    }

    function withdraw() public  {
        require(isDeposited[msg.sender] == true, 'Error, user has no funds in the dBank.');

        uint depositTime = fakeNow - depositStart[msg.sender];
        uint interestPerSecond = 300000000 * (etherBalanceOf[msg.sender] / 1e16);
        uint interest = depositTime * interestPerSecond;

        payable(msg.sender).transfer(interest);
        payable(msg.sender).transfer(etherBalanceOf[msg.sender]);

        interestSupply -= interest;
        etherBalanceOf[msg.sender] = 0;
        depositStart[msg.sender] = 0;
        isDeposited[msg.sender] = false;
    }
}