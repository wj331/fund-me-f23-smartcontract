//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //creating fake user to send all transactions
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {   
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        //because run() will deploy a new fundme contract
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
     }
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }
    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        //expects next line to fail
        vm.expectRevert();

        fundMe.fund(); //send 0 value, so fails
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //next transaction will be sent by USER

        fundMe.fund{value : 10e18}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,  10e18);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        //adds USER to getFunder   
        fundMe.fund{value: 10e17} ();

        //check if latest Funder is indeed USER
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    //used for repeated codes etc
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: 10e17}();
        _;
    }

    //add modifer inside 
    function testOnlyOwnerCanWithdraw() public funded {

        vm.expectRevert();
        vm.prank(USER); //USER is not Owner so should revert
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        uint256 gasStart = gasleft(); //gasleft is a built in function in solidity eg 1000
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); //c = 200
        fundMe.withdraw();

        uint256 gasEnd = gasleft(); //left = 800
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        //if want to use numbers to generate addresses, those numbers have to be uint160
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex;  i < numberOfFunders;  i++) {
             //but vm.hoax does both prank and deal together
             hoax(address(i), 10e17);
             fundMe.fund{value: 10e17}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //ACT
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        //if want to use numbers to generate addresses, those numbers have to be uint160
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex;  i < numberOfFunders;  i++) {
             //but vm.hoax does both prank and deal together
             hoax(address(i), 10e17);
             fundMe.fund{value: 10e17}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //ACT
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}