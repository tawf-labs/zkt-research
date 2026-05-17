// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Test.sol";
import "../src/DAO/ZKTCore.sol";
import "../src/DAO/NullifierRegistry.sol";
import "../src/DAO/verifiers/Groth16Verifier.sol";
import "../src/tokens/MockIDRX.sol";
import "../src/tokens/DonationReceiptNFT.sol";
import "../src/tokens/VotingNFT.sol";
import "../src/tokens/OrganizerNFT.sol";
import "../src/DAO/core/ProposalManager.sol";
import "../src/DAO/core/VotingManager.sol";
import "../src/DAO/core/ShariaReviewManager.sol";
import "../src/DAO/core/PoolManager.sol";
import "../src/DAO/core/ZakatEscrowManager.sol";
import "../src/DAO/core/PrivateDonationPool.sol";
import "../src/DAO/core/MilestoneManager.sol";
import "../src/DAO/core/ParticipationTracker.sol";

contract TestDonateZK is Test {
    function test_donateZKRevertReason() public {
        // Deploy minimal setup and try donateZK to see exact revert reason
        MockIDRX idrxToken = new MockIDRX();
        DonationReceiptNFT receiptNFT = new DonationReceiptNFT();
        VotingNFT votingNFT = new VotingNFT();
        OrganizerNFT organizerNFT = new OrganizerNFT();
        ParticipationTracker participationTracker = new ParticipationTracker();
        Groth16Verifier groth16Verifier = new Groth16Verifier();
        HonkVerifier honkVerifier = new HonkVerifier();
        NullifierRegistry nullifierRegistry = new NullifierRegistry();
        
        ProposalManager proposalManager = new ProposalManager();
        VotingManager votingManager = new VotingManager(address(proposalManager), address(votingNFT));
        ShariaReviewManager shariaReviewManager = new ShariaReviewManager(address(proposalManager), address(groth16Verifier));
        PoolManager poolManager = new PoolManager(address(proposalManager), address(idrxToken), address(receiptNFT));
        ZakatEscrowManager zakatEscrowManager = new ZakatEscrowManager(address(proposalManager), address(idrxToken), address(receiptNFT));
        PrivateDonationPool privatePool = new PrivateDonationPool(address(idrxToken));
        MilestoneManager milestoneManager = new MilestoneManager(address(proposalManager), address(votingNFT));
        
        ZKTCore dao = new ZKTCore(
            address(idrxToken), address(receiptNFT), address(votingNFT),
            address(organizerNFT), address(participationTracker),
            address(proposalManager), address(votingManager),
            address(shariaReviewManager), address(poolManager),
            address(zakatEscrowManager), address(milestoneManager),
            address(honkVerifier), address(nullifierRegistry),
            address(privatePool)
        );

        // Give ZKTCore MINTER_ROLE
        receiptNFT.grantRole(receiptNFT.MINTER_ROLE(), address(dao));
        
        // Mint tokens + approve
        idrxToken.adminMint(address(this), 1000000);
        idrxToken.approve(address(dao), 1000000);
        
        // Call donateZK with empty proof
        bytes32[] memory pis = new bytes32[](6);
        pis[0] = bytes32(uint256(85000000));
        pis[1] = bytes32(uint256(1750000000));
        pis[2] = bytes32(uint256(10));
        pis[3] = bytes32(uint256(1));
        pis[4] = bytes32(uint256(0));
        pis[5] = bytes32(uint256(12345));
        
        // This should revert since HonkVerifier.verify() returns false
        vm.expectRevert("Invalid ZK proof");
        dao.donateZK(0, 1000000, "", pis, bytes32(uint256(12345)), "QmTest");
    }
}
