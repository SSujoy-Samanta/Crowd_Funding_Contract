// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/CrowdfundingFactory.sol";
import "../src/CrowdFunding.sol";

contract CrowdfundingFactoryTest is Test {
    CrowdfundingFactory c;
    CrowdFunding crowdFunding;
    address deployer = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);
    address user3 = address(0x213);
    address user4 = address(0x875);

    function setUp() public {
        vm.prank(deployer);
        c = new CrowdfundingFactory();
    }

    function test_Deployment() public {
        assertEq(c.owner(), deployer, "Factory owner should be the deployer");
    }
    function test_CreateCrowdfunding_Success() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        address x = c.createCrowdfunding(1 ether);
        
        CrowdFunding[] memory contracts = c.getUserContracts(user1);
        assertEq(contracts.length, 1, "User should have 1 deployed contract");

        crowdFunding = contracts[0]; // Assign the deployed contract
        assertEq(address(crowdFunding), address(x), "Deployed address should match");
        //Fund the project
        vm.deal(user2, 2 ether);
        vm.prank(user2);
        crowdFunding.creditFund{value: 1 ether}();

        assertEq(crowdFunding.fundsRaised(), 1 ether, "Funds raised should be 1 ETH");

        //Test Voting Logic
        vm.prank(user2);
        crowdFunding.vote(true); // User votes YES

        assertEq(crowdFunding.yesVotes(), 1 ether, "Yes votes should be 1 ETH");

        //Test Refunds (If Funding Goal Not Met)
        vm.expectRevert("You are not the contract owner"); // Expect failure if goal not met
        vm.prank(user2);
        crowdFunding.withdrawFunds();
    }
    
    function testWithdraw() public{
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        c.createCrowdfunding(5 ether);
        
        CrowdFunding[] memory contracts = c.getUserContracts(user1);

        crowdFunding = contracts[0]; // Assign the deployed contract

        //Fund the project
        vm.deal(user2, 2 ether);
        vm.prank(user2);
        crowdFunding.creditFund{value: 1 ether}();

        vm.deal(user3, 3 ether);
        vm.prank(user3);
        crowdFunding.creditFund{value: 2 ether}();

        vm.deal(user4, 3 ether);
        vm.prank(user4);
        crowdFunding.creditFund{value: 2 ether}();

        vm.deal(user3, 2 ether);
        vm.prank(user3);
        crowdFunding.creditFund{value: 1 ether}();


        assertEq(crowdFunding.fundsRaised(), 6 ether, "Funds raised should be 1 ETH");

        //Test Voting Logic
        vm.prank(user2);
        crowdFunding.vote(true); // User votes YES

        vm.prank(user4);
        crowdFunding.vote(false); // User votes YES  

        vm.prank(user3);
        crowdFunding.vote(true); // User votes YES
        assertEq(crowdFunding.yesVotes(), 4 ether, "Yes votes should be 4 ETH");

        vm.deal(user1, 1);
        vm.prank(user1);
        crowdFunding.withdrawFunds();
        assertEq(crowdFunding.fundsRaised(), 0 ether, "Raised fund has been withdrawn");
        
    }

    // function testFailWithDraw() public{

    // }

    function testClaimRefund() public{
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        c.createCrowdfunding(5 ether);
        
        CrowdFunding[] memory contracts = c.getUserContracts(user1);

        crowdFunding = contracts[0]; // Assign the deployed contract

        //Fund the project
        vm.deal(user2, 2 ether);
        vm.prank(user2);
        crowdFunding.creditFund{value: 1 ether}();

        vm.deal(user3, 3 ether);
        vm.prank(user3);
        crowdFunding.creditFund{value: 2 ether}();

        vm.deal(user4, 3 ether);
        vm.prank(user4);
        crowdFunding.creditFund{value: 2 ether}();

        vm.deal(user3, 2 ether);
        vm.prank(user3);
        crowdFunding.creditFund{value: 1 ether}();


        assertEq(crowdFunding.fundsRaised(), 6 ether, "Funds raised should be 1 ETH");

        //Test Voting Logic
        vm.prank(user2);
        crowdFunding.vote(true); // User votes YES

        vm.prank(user4);
        crowdFunding.vote(true); // User votes YES  

        vm.prank(user3);
        crowdFunding.vote(false); // User votes YES
        assertEq(crowdFunding.yesVotes(), 3 ether, "Yes votes should be 4 ETH");

        // vm.expectRevert("Funding not approved");
        // vm.prank(user1);
        // crowdFunding.withdrawFunds();
        assertEq(crowdFunding.fundsRaised(), 6 ether, "Raised fund has been claimed");

        vm.prank(user2);
        crowdFunding.claimRefund();

        vm.prank(user3);
        crowdFunding.claimRefund();
        
    }

    // function testFailClaimRefund() public{

    // }
}
