// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "@tawf-gov/tokens/MockIDRX.sol";
import "@tawf-gov/protocol/DonationReceiptNFT.sol";
import "@tawf-gov/tokens/VotingNFT.sol";
import "../src/DAO/ZKTCore.sol";
import "@tawf-gov/governance/ProposalManager.sol";
import "@tawf-gov/governance/VotingManager.sol";
import "../src/DAO/core/ShariaReviewManager.sol";
import "@tawf-gov/protocol/PoolManager.sol";
import "@tawf-gov/protocol/ZakatEscrowManager.sol";
import "../src/DAO/core/PrivateDonationPool.sol";
import "@tawf-gov/governance/MilestoneManager.sol";
import "@tawf-gov/governance/ParticipationTracker.sol";
import "../src/DAO/verifiers/Groth16Verifier.sol";
import "../src/DAO/verifiers/ZKVerifier.sol";
import "../src/DAO/NullifierRegistry.sol";

contract V8Deploy is Script {
    function run() external {
        console.log("=== V8 Deploy Phase ===");
        vm.startBroadcast();

        MockIDRX idrx = new MockIDRX();
        DonationReceiptNFT receiptNFT = new DonationReceiptNFT();
        VotingNFT votingNFT = new VotingNFT();
        ParticipationTracker tracker = new ParticipationTracker();
        Groth16Verifier groth16 = new Groth16Verifier();
        ZKVerifier zkVerifier = new ZKVerifier();
        NullifierRegistry nullifierReg = new NullifierRegistry();
        ProposalManager pm = new ProposalManager();
        VotingManager vmgr = new VotingManager(address(pm), address(votingNFT));
        ShariaReviewManager srm = new ShariaReviewManager(address(pm), address(groth16));
        PoolManager poolMgr = new PoolManager(address(pm), address(idrx), address(receiptNFT));
        ZakatEscrowManager escrow = new ZakatEscrowManager(address(pm), address(idrx), address(receiptNFT));
        PrivateDonationPool privatePool = new PrivateDonationPool(address(idrx));
        MilestoneManager mm = new MilestoneManager(address(pm), address(votingNFT));
        ZKTCore dao = new ZKTCore(
            address(idrx), address(receiptNFT), address(votingNFT), address(tracker),
            address(pm), address(vmgr), address(srm),
            address(poolMgr), address(escrow), address(mm),
            address(zkVerifier), address(nullifierReg),
            address(privatePool)
        );

        pm.grantRole(pm.ORGANIZER_ROLE(), address(dao));
        pm.grantRole(pm.ADMIN_ROLE(), address(dao));
        pm.grantRole(pm.VOTING_MANAGER_ROLE(), address(vmgr));
        pm.grantRole(pm.VOTING_MANAGER_ROLE(), address(srm));
        pm.grantRole(pm.VOTING_MANAGER_ROLE(), address(escrow));
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(dao));
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(escrow));
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(poolMgr));
        srm.grantRole(srm.ADMIN_ROLE(), address(dao));
        srm.grantRole(srm.SHARIA_COUNCIL_ROLE(), address(dao));
        escrow.grantRole(escrow.ADMIN_ROLE(), address(dao));
        escrow.setDefaultFallbackPool(0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB);
        privatePool.grantRole(privatePool.CORE_ROLE(), address(dao));
        dao.grantOrganizerRole(0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB);
        pm.grantRole(pm.ADMIN_ROLE(), 0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB);

        vm.stopBroadcast();

        console.log("ZKTCore:", address(dao));
        console.log("ZKVerifier:", address(zkVerifier));
        console.log("NullifierRegistry:", address(nullifierReg));
        console.log("ProposalManager:", address(pm));
        console.log("VotingManager:", address(vmgr));
        console.log("ShariaReviewManager:", address(srm));
        console.log("PoolManager:", address(poolMgr));
        console.log("ZakatEscrowManager:", address(escrow));
        console.log("PrivateDonationPool:", address(privatePool));
        console.log("VERSION: V8");
    }
}
