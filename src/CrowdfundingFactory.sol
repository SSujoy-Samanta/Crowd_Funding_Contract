// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {CrowdFunding} from "./CrowdFunding.sol"; // Import Crowdfunding contract

contract CrowdfundingFactory{
    address public owner;

    CrowdFunding[] public deployedContracts;
    mapping(address => CrowdFunding[]) public userContracts;

    event ContractDeployed(address indexed creator, address contractAddress, uint256 goal);

    constructor() {
        owner = msg.sender;
    }

    function updateOwner(address _owner) public{
        require(owner==msg.sender,"You are not the Owner of the Contract");
        owner=_owner;
    }

    function createCrowdfunding(uint256 _goal) external payable returns (address){
        // Deploy new contract - user pays the storage fee and gas fee
        CrowdFunding newContract = (new CrowdFunding)(msg.sender,_goal);

        deployedContracts.push(newContract);
        userContracts[msg.sender].push(newContract);

        emit ContractDeployed(msg.sender, address(newContract), _goal);

        return address(newContract);
    }

    function getDeployedContracts() external view returns (CrowdFunding[] memory) {
        return deployedContracts;
    }

    function getUserContracts(address user) external view returns (CrowdFunding[] memory) {
        return userContracts[user];
    }
}
