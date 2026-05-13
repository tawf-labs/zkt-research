// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Test.sol";

interface IZKTCore {
    function donateZK(uint256,uint256,bytes calldata,bytes32[] calldata,bytes32,string calldata) external;
}

contract TestSepoliaFork is Test {
    function test_donateZKOnSepoliaFork() public {
        // Fork Sepolia at current block
        uint256 forkId = vm.createFork("https://ethereum-sepolia.publicnode.com", 10844350);
        vm.selectFork(forkId);
        
        // The ZKTCore with correct verifier
        address zktc = 0x74624198248A1886aBD2623bd783B3fa2c0561ee;
        
        // Read the proof and public inputs from local files
        bytes memory proof = vm.readFileBinary("/tmp/final-deploy/circuit/target/proof3/proof");
        bytes memory piRaw = vm.readFileBinary("/tmp/final-deploy/circuit/target/proof3/public_inputs");
        
        bytes32[] memory pis = new bytes32[](piRaw.length / 32);
        for (uint256 i = 0; i < pis.length; i++) {
            bytes32 val;
            assembly {
                val := mload(add(add(piRaw, 32), mul(i, 32)))
            }
            pis[i] = val;
        }
        
        bytes32 nullifier = pis[5];
        
        // The deployer should have tokens and approval already on Sepolia
        // Call donateZK
        vm.prank(0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB);
        IZKTCore(zktc).donateZK(0, 1000000, proof, pis, nullifier, "QmEndToEnd");
    }
}
