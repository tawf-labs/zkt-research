// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "../src/tokens/MockIDRX.sol";
import "../src/tokens/DonationReceiptNFT.sol";
import "../src/tokens/VotingNFT.sol";
import "../src/tokens/OrganizerNFT.sol";
import "../src/DAO/ZKTCore.sol";
import "../src/DAO/core/ProposalManager.sol";
import "../src/DAO/core/VotingManager.sol";
import "../src/DAO/core/ShariaReviewManager.sol";
import "../src/DAO/core/PoolManager.sol";
import "../src/DAO/core/ZakatEscrowManager.sol";
import "../src/DAO/core/PrivateDonationPool.sol";
import "../src/DAO/core/MilestoneManager.sol";
import "../src/DAO/core/ParticipationTracker.sol";
import "../src/DAO/verifiers/HonkVerifier.sol";
import "../src/DAO/NullifierRegistry.sol";

/**
 * @title CoreTeamDeploy
 * @notice Deploy all ZKT contracts but concentrate ALL roles in a core team multisig.
 *         DAO contracts exist (required by ZKTCore constructor) but governance functions
 *         are dormant until roles are delegated to community members.
 *
 *         Use case: The core team acts as the interim DAO, holding all authority.
 *         Later, grant roles to community members and transition to decentralized governance.
 *
 *         Run: forge script script/CoreTeamDeploy.s.sol --rpc-url mainnet --broadcast
 */
contract CoreTeamDeploy is Script {
    function run() external {
        address coreTeam = msg.sender; // or replace with multisig address

        console.log("=== Core Team ZKT Deploy ===");
        console.log("Core Team:", coreTeam);

        vm.startBroadcast();

        // 1. Tokens
        MockIDRX idrx = new MockIDRX();
        DonationReceiptNFT receiptNFT = new DonationReceiptNFT();
        VotingNFT votingNFT = new VotingNFT();
        OrganizerNFT organizerNFT = new OrganizerNFT();
        ParticipationTracker tracker = new ParticipationTracker();

        // 2. ZK Infrastructure
        HonkVerifier honk = new HonkVerifier();
        NullifierRegistry nullifierReg = new NullifierRegistry();
        PrivateDonationPool privatePool = new PrivateDonationPool(address(idrx));

        // 3. Managers (required by ZKTCore constructor)
        ProposalManager pm = new ProposalManager();
        VotingManager vmgr = new VotingManager(address(pm), address(votingNFT));
        ShariaReviewManager srm = new ShariaReviewManager(address(pm), address(honk)); // honk as placeholder
        PoolManager poolMgr = new PoolManager(address(pm), address(idrx), address(receiptNFT));
        ZakatEscrowManager escrow = new ZakatEscrowManager(address(pm), address(idrx), address(receiptNFT));
        MilestoneManager mm = new MilestoneManager(address(pm), address(votingNFT));

        // 4. Orchestrator
        ZKTCore dao = new ZKTCore(
            address(idrx), address(receiptNFT), address(votingNFT),
            address(organizerNFT), address(tracker),
            address(pm), address(vmgr), address(srm),
            address(poolMgr), address(escrow), address(mm),
            address(honk), address(nullifierReg),
            address(privatePool)
        );

        // 5. Grant sub-contract roles to ZKTCore (ZKTCore is the caller)
        pm.grantRole(pm.ORGANIZER_ROLE(), address(dao));
        pm.grantRole(pm.ADMIN_ROLE(), address(dao));
        pm.grantRole(pm.KYC_ORACLE_ROLE(), address(dao));

        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(dao));
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(poolMgr));
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(escrow));

        votingNFT.grantRole(votingNFT.MINTER_ROLE(), address(dao));
        votingNFT.grantRole(votingNFT.ADMIN_ROLE(), address(dao));

        srm.grantRole(srm.SHARIA_COUNCIL_ROLE(), address(dao));
        srm.grantRole(srm.ADMIN_ROLE(), address(dao));

        poolMgr.grantRole(poolMgr.ADMIN_ROLE(), address(dao));
        poolMgr.grantRole(poolMgr.CORE_ROLE(), address(dao));

        escrow.grantRole(escrow.ADMIN_ROLE(), address(dao));
        escrow.grantRole(escrow.SHARIA_COUNCIL_ROLE(), address(dao));

        privatePool.grantRole(privatePool.CORE_ROLE(), address(dao));

        mm.grantRole(mm.ORGANIZER_ROLE(), address(dao));

        tracker.grantRole(tracker.TRACKER_ROLE(), address(dao));
        tracker.grantRole(tracker.VERIFIER_ROLE(), address(dao));

        // Cross-module permissions
        pm.grantRole(pm.VOTING_MANAGER_ROLE(), address(vmgr));
        pm.grantRole(pm.VOTING_MANAGER_ROLE(), address(srm));
        pm.grantRole(pm.VOTING_MANAGER_ROLE(), address(poolMgr));
        pm.grantRole(pm.VOTING_MANAGER_ROLE(), address(escrow));
        pm.grantRole(pm.MILESTONE_MANAGER_ROLE(), address(mm));
        pm.grantRole(pm.MILESTONE_MANAGER_ROLE(), address(poolMgr));

        // 6. Grant ZKTCore-level roles to core team
        dao.grantOrganizerRole(coreTeam);
        dao.grantShariaCouncilRole(coreTeam);
        dao.grantKYCOracleRole(coreTeam);

        // 7. Core team single-sig: lower quorums to 1
        dao.setShariaQuorum(1);
        dao.setVotingPeriod(1 hours); // fast iteration for team-controlled phase

        escrow.setDefaultFallbackPool(coreTeam);

        console.log("=== Deploy Complete ===");
        console.log("ZKTCore:", address(dao));
        console.log("PoolManager:", address(poolMgr));
        console.log("ZakatEscrowManager:", address(escrow));
        console.log("PrivateDonationPool:", address(privatePool));
        console.log("All roles held by:", coreTeam);

        vm.stopBroadcast();
    }
}
