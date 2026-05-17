// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Test.sol";

interface IZKTCore {
    function donateZK(uint256,uint256,bytes calldata,bytes32[] calldata,bytes32,string calldata) external;
}

contract TestSepoliaFork is Test {
    function test_donateZKOnSepoliaFork_V9Deployed() public {
        // Fork Sepolia and verify V9 ZKTCore is deployed with bytecode
        uint256 forkId = vm.createFork("https://ethereum-sepolia.publicnode.com");
        vm.selectFork(forkId);

        // V9 ZKTCore address (deployed May 17 2026)
        address zktcV9 = 0x5e3241AC904cE8B8EC2cAEB506e933A350bD19CC;

        // Verify contract has bytecode on Sepolia
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(zktcV9)
        }
        assertTrue(codeSize > 0, "V9 ZKTCore not deployed on Sepolia");

        // Verify PrivateDonationPool is also deployed
        address privatePool = 0xAee7800E0562d3274F62d66dC6E7Fdf4f886f122;
        assembly {
            codeSize := extcodesize(privatePool)
        }
        assertTrue(codeSize > 0, "V9 PrivateDonationPool not deployed on Sepolia");
    }
}
