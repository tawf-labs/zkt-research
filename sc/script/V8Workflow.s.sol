// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "../src/DAO/ZKTCore.sol";

contract V8Workflow is Script {
    function run() external {
        console.log("=== V8 DAO Workflow + donateZK ===");
        vm.startBroadcast();

        ZKTCore dao = ZKTCore(0xb56a8411C769cb0039e9ae1FdA3ea51424B1b60B);

        // 1. Create proposal
        uint256 proposalId = dao.createProposal(
            "V8 E2E Donation Test",
            "End-to-end ZK donation flow on Sepolia",
            1000000000000000000000,
            true,
            bytes32(0),
            new string[](0),
            "",
            new IProposalManager.MilestoneInput[](0)
        );
        console.log("Proposal created:", proposalId);

        // 2. Submit for community vote
        dao.submitForCommunityVote(proposalId);
        console.log("Submitted for community vote");

        vm.stopBroadcast();
        console.log("");
        console.log("Pause here: wait 30s for voting period to pass naturally on-chain");
        console.log("Then run V8Workflow2 to finalize");
        console.log("Proposal ID:", proposalId);
    }
}
