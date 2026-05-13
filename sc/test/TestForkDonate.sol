pragma solidity ^0.8.31;
import "forge-std/Test.sol";

contract TestForkDonate is Test {
    function test_donateZKFork() public {
        vm.createSelectFork("https://ethereum-sepolia.publicnode.com");
        
        address zktc = 0x74624198248A1886aBD2623bd783B3fa2c0561ee;
        bytes memory proof = hex"00";
        bytes32[] memory pis = new bytes32[](6);
        pis[0] = bytes32(uint256(85000000));
        pis[1] = bytes32(uint256(1750000000));
        pis[2] = bytes32(uint256(10));
        pis[3] = bytes32(uint256(1));
        pis[4] = bytes32(uint256(0));
        pis[5] = bytes32(uint256(999999));

        vm.prank(0x236c6ea9DDc48ae72DCFb8724BF8a136aa3C6EBB);
        
        (bool ok, bytes memory ret) = zktc.call(
            abi.encodeWithSignature(
                "donateZK(uint256,uint256,bytes,bytes32[],bytes32,string)",
                uint256(0), uint256(1000000), proof, pis, bytes32(uint256(999999)), "QmTest"
            )
        );
        console.log("Success:", ok);
        if (!ok && ret.length > 0) {
            console.log("Revert bytes:");
            console.logBytes(ret);
        } else if (!ok) {
            console.log("Reverted with empty data");
        }
    }
}
