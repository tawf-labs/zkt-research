// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "@tawf-gov/tokens/MockIDRX.sol";
import "../src/DAO/ZKTCore.sol";

contract V8Workflow3 is Script {
    function run() external {
        console.log("=== V8 Step 3: Finalize + Sharia + Pool + donateZK ===");
        vm.startBroadcast();

        ZKTCore dao = ZKTCore(0xb56a8411C769cb0039e9ae1FdA3ea51424B1b60B);

        // Grant Sharia Council role
        dao.grantRole(dao.SHARIA_COUNCIL_ROLE(), 0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB);
        dao.grantShariaCouncilRole(0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB);

        // Finalize community vote
        dao.finalizeCommunityVote(1);
        console.log("Community vote finalized");

        // Sharia review
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256 bundleId = dao.createShariaReviewBundle(ids);
        console.log("Bundle created:", bundleId);
        dao.reviewProposal(bundleId, 1, true, IProposalManager.CampaignType.ZakatCompliant, bytes32(0));
        console.log("Proposal reviewed");
        dao.finalizeShariaBundle(bundleId);
        console.log("Bundle finalized");

        // Create campaign pool
        uint256 poolId = dao.createCampaignPool(1);
        console.log("Campaign pool created:", poolId);

        // Approve tokens for escrow
        MockIDRX idrx = MockIDRX(0x1b84E74b5b291903Ee44FfbabBc87cD6535c59b5);
        idrx.adminMint(0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB, 1000000000000000000000);
        idrx.approve(0x8A085b6Bd8A2f9eCb712c7d861238EdAe982eED1, 1000000000000000000000);

        // Read proof
        bytes memory proofData = vm.readFileBinary("v7_proof.bin");
        bytes memory publicInputsRaw = vm.readFileBinary("v7_public_inputs.bin");

        bytes32[] memory publicInputs = new bytes32[](publicInputsRaw.length / 32);
        for (uint256 i = 0; i < publicInputs.length; i++) {
            bytes32 val;
            assembly {
                val := mload(add(add(publicInputsRaw, 32), mul(i, 32)))
            }
            publicInputs[i] = val;
        }
        bytes32 nullifier = publicInputs[5];

        // donateZK
        dao.donateZK(poolId, 1000000, proofData, publicInputs, nullifier, "QmV8E2ETest");
        console.log("donateZK() success!");

        vm.stopBroadcast();

        console.log("");
        console.log("=== V8 E2E COMPLETE ===");
        console.log("ZKTCore:", 0xb56a8411C769cb0039e9ae1FdA3ea51424B1b60B);
        console.log("Pool:", poolId);
        console.log("STATUS: SUCCESS");
    }
}
