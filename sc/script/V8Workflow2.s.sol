// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "forge-std/Script.sol";
import "@tawf-gov/tokens/VotingNFT.sol";
import "../src/DAO/ZKTCore.sol";

contract V8Workflow2 is Script {
    function run() external {
        console.log("=== V8 Step 2: Vote ===");
        vm.startBroadcast();

        VotingNFT vnft = VotingNFT(0x62AF745f9b7689720129A3A60e2ab0A2892C89B4);
        try vnft.mintVotingNFT(0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB, "") {
            console.log("VotingNFT minted");
        } catch {
            console.log("VotingNFT already minted, using existing");
        }

        ZKTCore dao = ZKTCore(0xb56a8411C769cb0039e9ae1FdA3ea51424B1b60B);
        dao.castVote(1, 1);
        console.log("Vote cast FOR proposal 1");

        vm.stopBroadcast();
    }
}
