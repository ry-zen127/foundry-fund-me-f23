//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether; //Thats largeeeeeeeee
    uint256 constant WITHDRAW_VALUE = 0.01 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Had to send ether to USER so they have funds to send
    }

    function testMinimumDollarIsFive() public  {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        if (block.chainid == 1115511) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        }
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //The next tx will be sent by USER

        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testAddressToAmountFundedIsCorrect() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}(); //😅 ps always remember () its a function remember

        uint256 funder = fundMe.getAddressToAmountFunded(USER);
        assertEq(funder, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();

        vm.prank(USER);
        fundMe.fund{value: 0}();
    }

    function testWithDrawWithASingleFunder() public funded {
       // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;

        //Act
        
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();




        //Assert

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;
        assertEq(endingFundBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundBalance);  

    }

    function testWithdrawFromMultipleFunders() public funded {
    //Arrange 

        //We are using 1 because sometimes the 0 address reverts
        uint160 startingfunderIndex = 1;
        uint160 numberOfFunders = 10;
        
        for(uint160 i = startingfunderIndex; i < numberOfFunders; i++){
            
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        } 

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;

    //Act

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;
        assert(address(fundMe).balance == 0);
        assert(startingFundBalance + startingOwnerBalance == endingOwnerBalance);
    }


    function testWithdrawFromMultipleFundersCheaper() public funded {
    //Arrange 

        //We are using 1 because sometimes the 0 address reverts
        uint160 startingfunderIndex = 1;
        uint160 numberOfFunders = 10;
        
        for(uint160 i = startingfunderIndex; i < numberOfFunders; i++){
            
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        } 

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;

    //Act

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;
        assert(address(fundMe).balance == 0);
        assert(startingFundBalance + startingOwnerBalance == endingOwnerBalance);

    }

    function testFuzz_withdrawfunction(address funder, uint256 amount) public funded {
      
      uint256 minamoumt = 5e18;
      vm.assume(amount >= minamoumt && amount < 100 ether);

      vm.deal(funder, amount);
       vm.prank(funder);
       fundMe.fund{value: amount}();

    uint256 startingownerbalance = fundMe.getOwner().balance;
    uint256 startingcontractbalance = address(fundMe).balance;
    
    vm.prank(fundMe.getOwner());
    fundMe.cheaperWithdraw();

    uint256 endinggownerbalance = fundMe.getOwner().balance;
    uint256 endingcontractbalance = address(fundMe).balance;
    
       
        assertEq(address(fundMe).balance , 0);
        assert(endinggownerbalance == startingownerbalance + startingcontractbalance);

    }
}


