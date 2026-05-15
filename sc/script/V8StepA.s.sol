// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "../src/DAO/ZKTCore.sol";

contract V8StepA is Script {
    function run() external {
        console.log("=== V8 Step A: Create + Submit + Vote ===");
        vm.startBroadcast();

        ZKTCore dao = ZKTCore(0xb56a8411C769cb0039e9ae1FdA3ea51424B1b60B);

        uint256 pid = dao.createProposal(
            "V8 Final E2E Test",
            "End-to-end ZK donation flow on Sepolia",
            1000000000000000000000,
            true,
            bytes32(0),
            new string[](0),
            "",
            new IProposalManager.MilestoneInput[](0)
        );
        console.log("Proposal ID:", pid);

        dao.submitForCommunityVote(pid);
        console.log("Submitted for community vote (votingPeriod=0, instant)");

        dao.castVote(pid, 1);
        console.log("Vote cast FOR");

        vm.stopBroadcast();
        console.log("");
        console.log("NOW run V8StepB in next block to finalize");
    }
}
