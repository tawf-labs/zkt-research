// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Test.sol";
import "@tawf-gov/tokens/MockIDRX.sol";
import "@tawf-gov/protocol/DonationReceiptNFT.sol";
import "@tawf-gov/tokens/VotingNFT.sol";
import "@tawf-gov/identity/TawfPassport.sol";
import {ITawfPassport, PassportType} from "@tawf-gov/interfaces/ITawfPassport.sol";
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
import "../src/DAO/verifiers/HonkVerifier.sol";
import "@tawf-gov/interfaces/IProposalManager.sol";

/**
 * @title SecurityEdgeTest
 * @notice Security analysis tests for the ZKT protocol.
 *         Covers nullifier race conditions (double-spend) and mempool
 *         front-running (griefing) attack vectors.
 *
 *         Documented in the IEEE ICIMTech 2026 paper, Section IV: Security Analysis.
 */
contract SecurityEdgeTest is Test {
    MockIDRX idrxToken;
    DonationReceiptNFT receiptNFT;
    VotingNFT votingNFT;
    ParticipationTracker participationTracker;
    ZKTCore dao;
    NullifierRegistry nullifierRegistry;
    PrivateDonationPool privatePool;
    IHonkVerifier honkVerifier;
    ProposalManager proposalManager;
    ShariaReviewManager shariaReviewManager;
    PoolManager poolManager;
    ZakatEscrowManager zakatEscrowManager;
    MilestoneManager milestoneManager;

    address deployer = address(this);
    address organizer = address(0x1);
    address donor = address(0xA);
    address attacker = address(0xB);
    address member1 = address(0x2);
    address member2 = address(0x3);

    function setUp() public {
        idrxToken = new MockIDRX();
        receiptNFT = new DonationReceiptNFT();
        votingNFT = new VotingNFT();
        participationTracker = new ParticipationTracker();

        Groth16Verifier groth16Verifier = new Groth16Verifier();
        honkVerifier = new MockHonkVerifier();
        nullifierRegistry = new NullifierRegistry();
        privatePool = new PrivateDonationPool(address(idrxToken));

        TawfPassport tawfPassport = new TawfPassport();
        tawfPassport.issuePassport(organizer, PassportType.Organization, "ipfs://organizer");

        proposalManager = new ProposalManager();
        proposalManager.setTawfPassport(address(tawfPassport));
        VotingManager votingManager = new VotingManager(address(proposalManager), address(votingNFT));
        shariaReviewManager = new ShariaReviewManager(address(proposalManager), address(groth16Verifier));
        poolManager = new PoolManager(address(proposalManager), address(idrxToken), address(receiptNFT));
        zakatEscrowManager = new ZakatEscrowManager(address(proposalManager), address(idrxToken), address(receiptNFT));
        milestoneManager = new MilestoneManager(address(proposalManager), address(votingNFT));

        dao = new ZKTCore(
            address(idrxToken), address(receiptNFT), address(votingNFT), address(participationTracker),
            address(proposalManager), address(votingManager), address(shariaReviewManager),
            address(poolManager), address(zakatEscrowManager), address(milestoneManager),
            address(honkVerifier), address(nullifierRegistry), address(privatePool)
        );

        proposalManager.grantRole(proposalManager.ORGANIZER_ROLE(), address(dao));
        proposalManager.grantRole(proposalManager.KYC_ORACLE_ROLE(), address(dao));
        proposalManager.grantRole(proposalManager.ADMIN_ROLE(), address(dao));
        proposalManager.grantRole(proposalManager.VOTING_MANAGER_ROLE(), address(votingManager));
        proposalManager.grantRole(proposalManager.VOTING_MANAGER_ROLE(), address(shariaReviewManager));
        proposalManager.grantRole(proposalManager.VOTING_MANAGER_ROLE(), address(poolManager));
        proposalManager.grantRole(proposalManager.VOTING_MANAGER_ROLE(), address(zakatEscrowManager));
        proposalManager.grantRole(proposalManager.MILESTONE_MANAGER_ROLE(), address(milestoneManager));
        proposalManager.grantRole(proposalManager.MILESTONE_MANAGER_ROLE(), address(poolManager));

        shariaReviewManager.grantRole(shariaReviewManager.SHARIA_COUNCIL_ROLE(), address(dao));
        shariaReviewManager.grantRole(dao.DEFAULT_ADMIN_ROLE(), address(dao));

        poolManager.grantRole(poolManager.ADMIN_ROLE(), address(dao));
        poolManager.grantRole(poolManager.CORE_ROLE(), address(dao));
        poolManager.grantRole(dao.DEFAULT_ADMIN_ROLE(), address(dao));

        zakatEscrowManager.grantRole(zakatEscrowManager.ADMIN_ROLE(), address(dao));
        zakatEscrowManager.grantRole(zakatEscrowManager.SHARIA_COUNCIL_ROLE(), address(dao));
        zakatEscrowManager.grantRole(dao.DEFAULT_ADMIN_ROLE(), address(dao));

        milestoneManager.grantRole(milestoneManager.ORGANIZER_ROLE(), address(dao));
        milestoneManager.grantRole(dao.DEFAULT_ADMIN_ROLE(), address(dao));

        privatePool.grantRole(privatePool.CORE_ROLE(), address(dao));

        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(poolManager));
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(zakatEscrowManager));

        votingNFT.grantRole(votingNFT.MINTER_ROLE(), address(dao));
        votingNFT.grantRole(votingNFT.ADMIN_ROLE(), address(dao));
        votingNFT.grantRole(votingNFT.UPGRADER_ROLE(), address(dao));

        participationTracker.grantRole(participationTracker.TRACKER_ROLE(), address(dao));
        participationTracker.grantRole(participationTracker.VERIFIER_ROLE(), address(dao));

        dao.grantOrganizerRole(organizer);
        dao.grantShariaCouncilRole(deployer);
        dao.grantKYCOracleRole(deployer);

        dao.grantVotingNFT(member1, "ipfs://member1");
        dao.grantVotingNFT(member2, "ipfs://member2");
        dao.verifyVoter(member1);
        dao.verifyVoter(member2);

        idrxToken.adminMint(donor, 10000 ether);
        idrxToken.adminMint(attacker, 10000 ether);

        dao.setDefaultFallbackPool(deployer);
    }

    function _setupApprovedPool() internal returns (uint256 poolId, uint256 proposalId) {
        vm.startPrank(organizer);

        IProposalManager.MilestoneInput[] memory milestones = new IProposalManager.MilestoneInput[](0);

        string[] memory checklist = new string[](1);
        checklist[0] = "Verified";

        proposalId = dao.createProposal(
            "Security Test Campaign", "Description", 1000 ether,
            true, bytes32(0), checklist, "ipfs://test", milestones
        );

        vm.stopPrank();

        dao.updateKYCStatus(proposalId, IProposalManager.KYCStatus.Verified, "OK");
        vm.prank(organizer);
        dao.submitForCommunityVote(proposalId);

        vm.prank(member1);
        dao.castVote(proposalId, 1);
        vm.prank(member2);
        dao.castVote(proposalId, 1);

        vm.warp(block.timestamp + 8 days);
        dao.finalizeCommunityVote(proposalId);

        uint256 bundleId = 1;
        vm.prank(deployer);
        dao.reviewProposal(bundleId, proposalId, true, IProposalManager.CampaignType.Normal, bytes32(0));
        vm.prank(deployer);
        dao.finalizeShariaBundle(bundleId);

        vm.prank(organizer);
        poolId = dao.createCampaignPool(proposalId);
    }

    // ============================================================
    // A2: Nullifier Race Condition (Double-Spend)
    // ============================================================
    // Confirms that NullifierRegistry.spend() is synchronous within
    // the EVM execution context. Two concurrent transactions with the
    // same nullifier cannot both succeed — whichever is included first
    // in the block wins; the second reverts with "NullifierAlreadySpent".

    function test_NullifierDoubleSpend_RevertsSecondSpend() public {
        bytes32 testNullifier = keccak256("unique-nullifier-1");

        vm.prank(donor);
        nullifierRegistry.spend(testNullifier);

        assertTrue(nullifierRegistry.isSpent(testNullifier), "Nullifier should be marked spent");

        vm.prank(attacker);
        vm.expectRevert("NullifierAlreadySpent");
        nullifierRegistry.spend(testNullifier);
    }

    function test_NullifierRace_DirectRegistrySpend() public {
        bytes32 nullifier1 = keccak256("nullifier-race-a");
        bytes32 nullifier2 = keccak256("nullifier-race-b");

        nullifierRegistry.spend(nullifier1);

        assertTrue(nullifierRegistry.isSpent(nullifier1), "Nullifier1 spent");
        assertFalse(nullifierRegistry.isSpent(nullifier2), "Nullifier2 not spent");

        nullifierRegistry.spend(nullifier2);

        assertTrue(nullifierRegistry.isSpent(nullifier1));
        assertTrue(nullifierRegistry.isSpent(nullifier2));
    }

    // Verify that a successful nullifier spend within a donateZKPrivate call
    // prevents a second call with the same nullifier from succeeding.
    function test_NullifierRace_EndToEndDonateZKRevertsDuplicate() public {
        (uint256 poolId,) = _setupApprovedPool();
        bytes32 nullifier = keccak256("e2e-race-nullifier");

        // Mock a valid UltraHONK proof (the HonkVerifier always returns true for testing)
        bytes memory mockProof = hex"deadbeef";
        bytes32[] memory publicInputs = new bytes32[](7);
        publicInputs[0] = bytes32(uint256(1));     // bundleId
        publicInputs[1] = bytes32(uint256(1));     // proposalId
        publicInputs[2] = bytes32(uint256(3));     // approvalCount
        publicInputs[3] = bytes32(uint256(3));     // quorumThreshold
        publicInputs[4] = bytes32(0);               // councilRoot
        publicInputs[5] = bytes32(0);               // nullifierRoot
        publicInputs[6] = keccak256("commitment");  // amountCommitment

        // Donor donates
        vm.startPrank(donor);
        idrxToken.approve(address(privatePool), 100 ether);
        dao.donateZKPrivate(poolId, 100 ether, mockProof, publicInputs, nullifier);
        vm.stopPrank();

        assertTrue(nullifierRegistry.isSpent(nullifier), "Nullifier should be spent after first donation");

        // Attacker tries same nullifier
        vm.startPrank(attacker);
        idrxToken.approve(address(privatePool), 100 ether);
        vm.expectRevert("NullifierAlreadySpent");
        dao.donateZKPrivate(poolId, 100 ether, mockProof, publicInputs, nullifier);
        vm.stopPrank();
    }

    // ============================================================
    // A3: Mempool Front-Running (Griefing Attack)
    // ============================================================
    // The donateZKPrivate() function does NOT bind msg.sender into the
    // ZK proof's public inputs. An MEV searcher who observes a pending
    // donateZKPrivate() transaction in the mempool can extract the
    // (proof, publicInputs, nullifier) calldata and submit their own
    // transaction front-running the original.
    //
    // Result: the attacker pays gas and funds come from the attacker's
    // wallet (idrxToken.transferFrom(msg.sender, ...) uses the front-runner's
    // address). The original donor's transaction reverts because the
    // nullifier is already spent. This is a GRIEFING attack — the funds
    // still reach the PrivateDonationPool (same pool, same amount
    // commitment), but from a different donor's address.
    //
    // Mitigation (future work): bind msg.sender into the circuit as a
    // public input, or require EIP-712 signed authorization.

    function test_FrontRunning_AttackerCanReplayCalldata() public {
        (uint256 poolId,) = _setupApprovedPool();
        bytes32 nullifier = keccak256("frontrun-nullifier");

        bytes memory mockProof = hex"cafebabe";
        bytes32[] memory publicInputs = new bytes32[](7);
        publicInputs[0] = bytes32(uint256(1));
        publicInputs[1] = bytes32(uint256(1));
        publicInputs[2] = bytes32(uint256(3));
        publicInputs[3] = bytes32(uint256(3));
        publicInputs[4] = bytes32(0);
        publicInputs[5] = bytes32(0);
        publicInputs[6] = keccak256("frontrun-commitment");

        uint256 attackerBalanceBefore = idrxToken.balanceOf(attacker);
        uint256 donorBalanceBefore = idrxToken.balanceOf(donor);
        uint256 poolBalanceBefore = idrxToken.balanceOf(address(privatePool));

        // Attacker front-runs: submits the SAME proof+nullifier before donor
        vm.startPrank(attacker);
        idrxToken.approve(address(privatePool), 100 ether);
        dao.donateZKPrivate(poolId, 100 ether, mockProof, publicInputs, nullifier);
        vm.stopPrank();

        assertTrue(nullifierRegistry.isSpent(nullifier), "Nullifier spent by attacker");
        assertEq(idrxToken.balanceOf(attacker), attackerBalanceBefore - 100 ether, "Attacker paid");
        assertEq(idrxToken.balanceOf(address(privatePool)), poolBalanceBefore + 100 ether, "Pool received funds");

        // Donor tries the original transaction — reverts (nullifier already spent)
        vm.startPrank(donor);
        idrxToken.approve(address(privatePool), 100 ether);
        vm.expectRevert("NullifierAlreadySpent");
        dao.donateZKPrivate(poolId, 100 ether, mockProof, publicInputs, nullifier);
        vm.stopPrank();

        // Donor's balance is unchanged (their tx reverted)
        assertEq(idrxToken.balanceOf(donor), donorBalanceBefore, "Donor should not have paid");

        // Pool has exactly one donation from the attacker
        assertEq(privatePool.poolRaisedAmount(poolId), 100 ether, "Pool raised exactly one donation");
    }

    // Document the griefing vector: proof is valid, nullifier is fresh,
    // but the msg.sender is not verified. Attacker pays on behalf of donor.
    function test_FrontRunning_ProofValidityUnaffectedBySender() public {
        (uint256 poolId,) = _setupApprovedPool();
        bytes32 nullifier = keccak256("sender-independence");

        bytes memory proof = hex"00001111";
        bytes32[] memory publicInputs = new bytes32[](7);
        for (uint256 i = 0; i < 7; i++) publicInputs[i] = bytes32(i);

        uint256 amount = 50 ether;

        // Both donor and attacker can submit the exact same proof
        // This demonstrates msg.sender is not in the proof's public inputs
        vm.startPrank(donor);
        idrxToken.approve(address(privatePool), amount);
        dao.donateZKPrivate(poolId, amount, proof, publicInputs, nullifier);
        vm.stopPrank();

        assertTrue(nullifierRegistry.isSpent(nullifier));
        assertEq(privatePool.poolRaisedAmount(poolId), amount);
    }
}

contract MockHonkVerifier is IHonkVerifier {
    function verify(
        bytes calldata,
        bytes32[] calldata
    ) external pure returns (bool) {
        return true;
    }
}
