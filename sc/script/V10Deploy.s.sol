// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "../src/DAO/ZKTCore.sol";
import "../src/DAO/core/PrivateDonationPool.sol";
import "../src/DAO/core/ShariaReviewManager.sol";
import "../src/DAO/verifiers/HonkVerifier.sol";
import "../src/DAO/verifiers/Groth16Verifier.sol";
import "../src/DAO/NullifierRegistry.sol";

/**
 * @title V10Deploy
 * @notice Deploy ZKTCore and ZK contracts, wired to pre-deployed tawf-gov contracts.
 *         Must run AFTER tawf-gov DeployTawfSystem.s.sol.
 *
 *         Run: export SEPOLIA_RPC_URL=https://sepolia...
 *              export TAWF_PASSPORT=0x... (from tawf-gov deploy)
 *              forge script script/V10Deploy.s.sol --rpc-url sepolia --account tawf-deployer --broadcast
 */
contract V10Deploy is Script {
    function run() external {
        // ── Read tawf-gov addresses from env ──
        address passportAddr   = vm.envAddress("TAWF_PASSPORT");
        address reputationAddr = vm.envAddress("TAWF_REPUTATION");
        address votingNFTAddr  = vm.envAddress("TAWF_VOTING_NFT");
        address receiptNFTAddr = vm.envAddress("TAWF_RECEIPT_NFT");
        address idrxAddr       = vm.envAddress("TAWF_IDRX");
        address pmAddr         = vm.envAddress("TAWF_PROPOSAL_MANAGER");
        address vmgrAddr       = vm.envAddress("TAWF_VOTING_MANAGER");
        address mmAddr         = vm.envAddress("TAWF_MILESTONE_MANAGER");
        address trackerAddr    = vm.envAddress("TAWF_PARTICIPATION_TRACKER");
        address poolMgrAddr    = vm.envAddress("TAWF_POOL_MANAGER");
        address escrowAddr     = vm.envAddress("TAWF_ZAKAT_ESCROW");
        address coreTeam       = vm.envAddress("CORE_TEAM_ADDRESS");

        console.log("=== V10 ZKT Deploy (wired to tawf-gov) ===");
        console.log("TawfPassport:", passportAddr);
        console.log("Core Team:", coreTeam);

        vm.startBroadcast();

        // 1. ZK Infrastructure
        HonkVerifier honk = new HonkVerifier();
        Groth16Verifier groth16 = new Groth16Verifier();
        NullifierRegistry nullifierReg = new NullifierRegistry();
        PrivateDonationPool privatePool = new PrivateDonationPool(idrxAddr);

        // 2. ShariaReviewManager with groth16 verifier
        ShariaReviewManager srm = new ShariaReviewManager(
            payable(pmAddr),
            address(groth16)
        );

        // 3. ZKTCore orchestrator (wired to all tawf-gov contracts)
        ZKTCore dao = new ZKTCore(
            idrxAddr, receiptNFTAddr, votingNFTAddr,
            trackerAddr,
            pmAddr, vmgrAddr, address(srm),
            poolMgrAddr, escrowAddr, mmAddr,
            address(honk), address(nullifierReg),
            address(privatePool)
        );

        // 4. Grant ZKTCore roles on all sub-contracts
        // ProposalManager roles
        (bool pok,) = pmAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("ORGANIZER_ROLE"), address(dao)));

        // Receipt NFT minter roles
        (bool rok,) = receiptNFTAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("MINTER_ROLE"), address(dao)));

        // VotingNFT roles
        (bool vok,) = votingNFTAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("MINTER_ROLE"), address(dao)));

        // ShariaReviewManager
        srm.grantRole(srm.SHARIA_COUNCIL_ROLE(), address(dao));
        srm.grantRole(srm.ADMIN_ROLE(), address(dao));

        // PoolManager
        (bool pmgr,) = poolMgrAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("ADMIN_ROLE"), address(dao)));

        // ZakatEscrowManager
        (bool eok,) = escrowAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("ADMIN_ROLE"), address(dao)));

        // PrivateDonationPool
        privatePool.grantRole(privatePool.CORE_ROLE(), address(dao));

        // MilestoneManager
        (bool mok,) = mmAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("ORGANIZER_ROLE"), address(dao)));

        // ParticipationTracker
        (bool tok,) = trackerAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("TRACKER_ROLE"), address(dao)));

        // Grant core team roles on ZKTCore
        dao.grantOrganizerRole(coreTeam);
        dao.grantShariaCouncilRole(coreTeam);
        dao.grantKYCOracleRole(coreTeam);

        // Cross-module permissions
        (bool p1,) = pmAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("VOTING_MANAGER_ROLE"), vmgrAddr));
        (bool p2,) = pmAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("VOTING_MANAGER_ROLE"), address(srm)));
        (bool p3,) = pmAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("VOTING_MANAGER_ROLE"), poolMgrAddr));
        (bool p4,) = pmAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("VOTING_MANAGER_ROLE"), escrowAddr));
        (bool p5,) = pmAddr.call(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("MILESTONE_MANAGER_ROLE"), mmAddr));

        vm.stopBroadcast();

        console.log("\n=== V10 Deployed Addresses ===");
        console.log("ZKTCore:", address(dao));
        console.log("ShariaReviewManager:", address(srm));
        console.log("PrivateDonationPool:", address(privatePool));
        console.log("HonkVerifier:", address(honk));
        console.log("Groth16Verifier:", address(groth16));
        console.log("NullifierRegistry:", address(nullifierReg));
    }
}
