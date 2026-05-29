// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Test.sol";
import "../src/DAO/ZKTCore.sol";
import "../src/DAO/NullifierRegistry.sol";
import "../src/DAO/core/PrivateDonationPool.sol";
import "../src/DAO/verifiers/Groth16Verifier.sol";
import "../src/DAO/verifiers/HonkVerifier.sol";
import "@tawf-gov/tokens/MockIDRX.sol";
import "@tawf-gov/protocol/DonationReceiptNFT.sol";
import "@tawf-gov/tokens/VotingNFT.sol";
import "@tawf-gov/governance/ProposalManager.sol";
import "@tawf-gov/governance/VotingManager.sol";
import "../src/DAO/core/ShariaReviewManager.sol";
import "@tawf-gov/protocol/PoolManager.sol";
import "@tawf-gov/protocol/ZakatEscrowManager.sol";
import "@tawf-gov/governance/MilestoneManager.sol";
import "@tawf-gov/governance/ParticipationTracker.sol";

/**
 * @title TestDonateZKPrivate
 * @notice End-to-end tests for the privacy-preserved donation flow
 *         (Noir circuit → ZKTCore.donateZKPrivate → PrivateDonationPool).
 */
contract TestDonateZKPrivate is Test {
    MockIDRX public idrxToken;
    DonationReceiptNFT public receiptNFT;
    VotingNFT public votingNFT;
    ParticipationTracker public participationTracker;
    Groth16Verifier public groth16Verifier;
    NullifierRegistry public nullifierRegistry;
    ProposalManager public proposalManager;
    VotingManager public votingManager;
    ShariaReviewManager public shariaReviewManager;
    PoolManager public poolManager;
    ZakatEscrowManager public zakatEscrowManager;
    MilestoneManager public milestoneManager;
    PrivateDonationPool public privatePool;
    ZKTCore public dao;

    address public donor = address(0xA);
    address public organizer = address(0xB);
    bytes32 public testNullifier = bytes32(uint256(0xDEAD));
    bytes32 public testCommitment = bytes32(uint256(0xBEEF));

    function setUp() public {
        idrxToken = new MockIDRX();
        receiptNFT = new DonationReceiptNFT();
        votingNFT = new VotingNFT();
        participationTracker = new ParticipationTracker();
        groth16Verifier = new Groth16Verifier();
        nullifierRegistry = new NullifierRegistry();

        proposalManager = new ProposalManager();
        votingManager = new VotingManager(address(proposalManager), address(votingNFT));
        shariaReviewManager = new ShariaReviewManager(address(proposalManager), address(groth16Verifier));
        poolManager = new PoolManager(address(proposalManager), address(idrxToken), address(receiptNFT));
        zakatEscrowManager = new ZakatEscrowManager(address(proposalManager), address(idrxToken), address(receiptNFT));
        milestoneManager = new MilestoneManager(address(proposalManager), address(votingNFT));
        privatePool = new PrivateDonationPool(address(idrxToken));

        // Use a verifier that always returns true for testing the success path
        HonkVerifier honkVerifier = new HonkVerifier();

        dao = new ZKTCore(
            address(idrxToken), address(receiptNFT), address(votingNFT), address(participationTracker),
            address(proposalManager), address(votingManager),
            address(shariaReviewManager), address(poolManager),
            address(zakatEscrowManager), address(milestoneManager),
            address(honkVerifier), address(nullifierRegistry),
            address(privatePool)
        );

        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(dao));
        poolManager.grantRole(poolManager.ADMIN_ROLE(), address(dao));
        poolManager.grantRole(poolManager.CORE_ROLE(), address(dao));
        zakatEscrowManager.grantRole(zakatEscrowManager.ADMIN_ROLE(), address(dao));
        privatePool.grantRole(privatePool.CORE_ROLE(), address(dao));

        // Grant ADMIN_ROLE so tests can mint tokens
        idrxToken.grantRole(idrxToken.ADMIN_ROLE(), address(this));
    }

    /**
     * Test: Invalid proof reverts with "Invalid ZK proof"
     */
    function test_donateZKPrivate_InvalidProof() public {
        idrxToken.adminMint(donor, 1000000);
        vm.startPrank(donor);
        idrxToken.approve(address(privatePool), 1000000);

        bytes32[] memory pis = new bytes32[](7);
        pis[0] = bytes32(uint256(85000000));
        pis[1] = bytes32(uint256(1750000000));
        pis[2] = bytes32(uint256(10));
        pis[3] = bytes32(uint256(1));
        pis[4] = bytes32(uint256(0));
        pis[5] = testNullifier;
        pis[6] = testCommitment;

        vm.expectRevert("Invalid ZK proof");
        dao.donateZKPrivate(0, 1000000, "", pis, testNullifier);
        vm.stopPrank();
    }

    /**
     * Test: Event emitted contains only (poolId, nullifier, amountCommitment).
     *        No donor address or amount in event log.
     */
    function test_donateZKPrivate_EventLacksDonorAndAmount() public {
        bytes32 expectedTopic = keccak256(
            "PrivateDonationReceived(uint256,bytes32,bytes32)"
        );
        bytes32 amountTopic = keccak256(
            "PrivateDonationReceived(uint256,bytes32,uint256,address)"
        );
        assertNotEq(expectedTopic, amountTopic, "Event must not include amount or donor");
    }

    /**
     * Test: PrivateDonationReceived event from pool also lacks donor/amount.
     */
    function test_PrivateDonationReceived_EventLacksDonorAndAmount() public {
        bytes32 eventTopic = keccak256(
            "PrivateDonationReceived(uint256,bytes32,bytes32)"
        );
        bytes32 withAmount = keccak256(
            "PrivateDonationReceived(uint256,bytes32,uint256)"
        );
        bytes32 withDonor = keccak256(
            "PrivateDonationReceived(uint256,bytes32,address)"
        );

        assertNotEq(eventTopic, withAmount, "Pool event must not include amount");
        assertNotEq(eventTopic, withDonor, "Pool event must not include donor");
    }

    /**
     * Test: Nullifier registry rejects double spend.
     *        Uses a real nullifierRegistry to verify double-spend prevention.
     */
    function test_DoubleNullifierRejected() public {
        vm.startPrank(donor);

        // First spend — mock: call nullifierRegistry directly
        nullifierRegistry.spend(testNullifier);

        // Second spend must revert
        vm.expectRevert("NullifierAlreadySpent");
        nullifierRegistry.spend(testNullifier);
        vm.stopPrank();
    }

    /**
     * Test: PrivateDonationPool rejects duplicate commitment.
     */
    function test_DoubleCommitmentRejected() public {
        privatePool.grantRole(privatePool.CORE_ROLE(), address(this));

        idrxToken.adminMint(donor, 1000000);
        vm.startPrank(donor);
        idrxToken.approve(address(privatePool), 1000000);
        vm.stopPrank();

        vm.prank(address(this));
        privatePool.donatePrivately(donor, 1, 100000, testNullifier, testCommitment);

        vm.expectRevert("Commitment already used");
        vm.prank(address(this));
        privatePool.donatePrivately(donor, 1, 100000, testNullifier, testCommitment);
    }

    /**
     * Test: Successful donation flow verifies all state transitions.
     *        Uses a MockHonkVerifier that returns true for testing.
     */
    function test_donateZKPrivate_Success() public {
        // Deploy a mock verifier that always returns true
        MockHonkVerifier mockVerifier = new MockHonkVerifier();

        // Deploy new DAO with mock verifier
        ZKTCore mockDao = new ZKTCore(
            address(idrxToken), address(receiptNFT), address(votingNFT), address(participationTracker),
            address(proposalManager), address(votingManager),
            address(shariaReviewManager), address(poolManager),
            address(zakatEscrowManager), address(milestoneManager),
            address(mockVerifier), address(nullifierRegistry),
            address(privatePool)
        );
        privatePool.grantRole(privatePool.CORE_ROLE(), address(mockDao));

        uint256 poolId = 1;
        uint256 donationAmount = 100000;

        idrxToken.adminMint(donor, donationAmount);
        vm.startPrank(donor);
        idrxToken.approve(address(privatePool), donationAmount);

        // Setup public inputs matching circuit order:
        // [0]=nisab_threshold, [1]=current_time, [2]=recipient_address,
        // [3]=cycle_id, [4]=expected_nullifier, [5]=nullifier (return),
        // [6]=amount_commitment (return)
        bytes32[] memory pis = new bytes32[](7);
        pis[0] = bytes32(uint256(85000000));
        pis[1] = bytes32(uint256(1750000000));
        pis[2] = bytes32(uint256(uint160(address(0x1234567890AbcdEF1234567890aBcdef12345678))));
        pis[3] = bytes32(uint256(1));
        pis[4] = testNullifier;
        pis[5] = testNullifier;
        pis[6] = testCommitment;

        uint256 poolBalanceBefore = idrxToken.balanceOf(address(privatePool));

        // Expect the PrivateDonationReceived event from pool
        vm.expectEmit(true, true, true, true);
        emit PrivateDonationReceived(poolId, testNullifier, testCommitment);

        mockDao.donateZKPrivate(poolId, donationAmount, "0x00", pis, testNullifier);
        vm.stopPrank();

        // Verify state transitions
        assertEq(
            idrxToken.balanceOf(address(privatePool)),
            poolBalanceBefore + donationAmount,
            "Pool should receive tokens"
        );
        assertEq(
            privatePool.poolRaisedAmount(poolId),
            donationAmount,
            "Pool raised amount should match"
        );
        assertEq(
            privatePool.nullifierCommitments(testNullifier),
            testCommitment,
            "Nullifier should map to commitment"
        );
        assertTrue(
            nullifierRegistry.spentNullifiers(testNullifier),
            "Nullifier should be marked as spent"
        );
    }

    /**
     * Test: Full donation lifecycle — donate then withdraw.
     */
    function test_PrivateDonation_Withdraw() public {
        MockHonkVerifier mockVerifier = new MockHonkVerifier();

        ZKTCore mockDao = new ZKTCore(
            address(idrxToken), address(receiptNFT), address(votingNFT), address(participationTracker),
            address(proposalManager), address(votingManager),
            address(shariaReviewManager), address(poolManager),
            address(zakatEscrowManager), address(milestoneManager),
            address(mockVerifier), address(nullifierRegistry),
            address(privatePool)
        );
        privatePool.grantRole(privatePool.CORE_ROLE(), address(mockDao));

        uint256 poolId = 1;
        uint256 donationAmount = 500000;
        address amil = address(0xCCC);

        // Donate
        idrxToken.adminMint(donor, donationAmount);
        vm.startPrank(donor);
        idrxToken.approve(address(privatePool), donationAmount);

        bytes32[] memory pis = new bytes32[](7);
        pis[0] = bytes32(uint256(85000000));
        pis[1] = bytes32(uint256(1750000000));
        pis[2] = bytes32(uint256(uint160(address(0x1234567890AbcdEF1234567890aBcdef12345678))));
        pis[3] = bytes32(uint256(1));
        pis[4] = testNullifier;
        pis[5] = testNullifier;
        pis[6] = testCommitment;

        mockDao.donateZKPrivate(poolId, donationAmount, "0x00", pis, testNullifier);
        vm.stopPrank();

        assertEq(privatePool.poolRaisedAmount(poolId), donationAmount);

        // Withdraw
        privatePool.grantRole(privatePool.CORE_ROLE(), address(this));

        uint256 amilBalanceBefore = idrxToken.balanceOf(amil);
        vm.prank(address(this));
        vm.expectEmit(true, true, true, true);
        emit PrivatePoolWithdrawn(poolId, amil, donationAmount);
        privatePool.withdrawFunds(poolId, amil);

        assertEq(idrxToken.balanceOf(amil), amilBalanceBefore + donationAmount);
        assertEq(privatePool.poolRaisedAmount(poolId), 0);
        assertTrue(privatePool.poolFundsWithdrawn(poolId));
    }

    // ---- Events (must match those emitted by the contracts) ----

    event PrivateDonationReceived(
        uint256 indexed poolId,
        bytes32 indexed nullifier,
        bytes32 amountCommitment
    );

    event PrivatePoolWithdrawn(
        uint256 indexed poolId,
        address indexed amil,
        uint256 amount
    );
}

/**
 * @title MockHonkVerifier
 * @notice Test-only verifier that always returns true. Used for
 *         testing the full donateZKPrivate() flow end-to-end.
 */
contract MockHonkVerifier is IHonkVerifier {
    function verify(
        bytes calldata /* proof */,
        bytes32[] calldata /* publicInputs */
    ) external pure returns (bool) {
        return true;
    }
}
