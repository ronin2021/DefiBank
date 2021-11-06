// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Functionality:
*       supplyEth: Deployer of contract can call this function to provide
*           collateral for interest paid on withdraw
*       deposit: Account puts in a value amount which can only be
*           implemented once per address
*       fastForward: Sets fake current time (fakeNow) ahead by 100 days to render interest
*       withdraw: Account if deposited prior can withdraw deposit with accrued interest
*/

contract DBank {
    // Global variables to keep track of accounts and the deposits they made
    mapping(address => bool) public isDeposited;
    mapping(address => uint) public etherBalanceOf;
    mapping(address => uint) public depositStart;

    // Deployer of contract gains permission to supply interest collateral
    address payable supplier;
    uint public interestSupply;

    // Manufactured current time for testing
    uint public fakeNow;

    // Set supplier to deployer of contract, fakeNow to time of deployment and
    // any value sent to contract on deployment 
    constructor () payable {
        supplier = payable(msg.sender);
        fakeNow = block.timestamp;
        interestSupply += msg.value;
    }

    // Set manufactured current time ahead by 100 days to simulate gaining interest
    function fastForward() public {
        fakeNow += 100 days;
    }

    // When done with contract or if there are any problems 
    // can withdraw entire eth supply in contract
    function cleanSlate() public OnlySupplier {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    // Checks entire amount of eth in contract currently
    function balanceOfContract() public view returns(uint) {
        return payable(address(this)).balance;
    }

    // Allows only the deployer/supplier to use the function
    modifier OnlySupplier() {
        require(msg.sender == supplier);
        _;
    }

    // Deposits eth into contract from supplier 
    function supplyEth() payable public OnlySupplier {
        interestSupply += msg.value;
    }
    
    // Lets an address that has not made a deposit deposit a value above .01 ETH
    function deposit() payable public {
        require(isDeposited[msg.sender] == false, 'Error, deposit already active');
        require(msg.value >= 1e16, 'Error, deposit must be >= 0.01 ETH');

        // Updates values associated with account
        etherBalanceOf[msg.sender] = msg.value;
        isDeposited[msg.sender] = true;
        depositStart[msg.sender] = fakeNow;
    }

    // Lets an account withdraw their deposit
    function withdraw() public  {
        // Checks to make sure a deposit was made previously
        require(isDeposited[msg.sender] == true, 'Error, user has no funds in the dBank.');

        // Calculates interest to be given
        uint depositTime = fakeNow - depositStart[msg.sender];
        uint interestPerSecond = 300000000 * (etherBalanceOf[msg.sender] / 1e16);
        uint interest = depositTime * interestPerSecond;

        // Transfers deposit amount along with any interest acrued to account
        payable(msg.sender).transfer(interest);
        payable(msg.sender).transfer(etherBalanceOf[msg.sender]);

        // Updates how much interest collateral is available
        interestSupply -= interest;

        // Updates values associated with account
        etherBalanceOf[msg.sender] = 0;
        depositStart[msg.sender] = 0;
        isDeposited[msg.sender] = false;
    }
}