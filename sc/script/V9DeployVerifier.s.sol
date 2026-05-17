// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "../src/DAO/verifiers/Groth16Verifier.sol";

contract V9DeployVerifier is Script {
    function run() external {
        console.log("=== V9 Verifier Deploy ===");
        vm.startBroadcast();
        Groth16Verifier groth16 = new Groth16Verifier();
        vm.stopBroadcast();
        console.log("Groth16Verifier:", address(groth16));
    }
}
