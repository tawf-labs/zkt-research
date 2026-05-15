// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";

interface IZKTCoreE2E {
    function createProposal(
        string calldata title, string calldata description, uint256 fundingGoal,
        bool isEmergency, bytes32 mockZKKYCProof, string[] calldata zakatChecklistItems,
        string calldata metadataURI, bytes calldata milestoneInputs
    ) external returns (uint256);
    function submitForCommunityVote(uint256) external;
    function castVote(uint256,uint8) external;
    function finalizeCommunityVote(uint256) external;
    function createCampaignPool(uint256) external returns (uint256);
    function donateZK(uint256,uint256,bytes calldata,bytes32[] calldata,bytes32,string calldata) external;
}

contract TestV7E2E is Script {
    function run() external {
        address dao = 0xCa849Dad720C870cb2738c9Ed02D978ca357a7F7;
        IZKTCoreE2E zkt = IZKTCoreE2E(dao);
        
        vm.startBroadcast();
        
        bytes memory emptyMilestones = hex"0000000000000000000000000000000000000000000000000000000000000000";
        
        uint256 proposalId = zkt.createProposal(
            "V7 Test", "E2E ZK donation", 1000000000000000000000,
            true, bytes32(0), new string[](0), "", emptyMilestones
        );
        console.log("Proposal:", proposalId);
        
        zkt.submitForCommunityVote(proposalId);
        zkt.castVote(proposalId, 1);
        zkt.castVote(proposalId, 1);
        vm.warp(block.timestamp + 604801);
        zkt.finalizeCommunityVote(proposalId);
        uint256 poolId = zkt.createCampaignPool(proposalId);
        console.log("Pool:", poolId);
        
        vm.stopBroadcast();
    }
}
