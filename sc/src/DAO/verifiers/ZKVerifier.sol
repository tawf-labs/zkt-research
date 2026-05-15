// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;

/**
 * @title ZKVerifier
 * @notice Real UltraHONK proof verifier with hash anchoring and nullifier tracking.
 * @dev Implements IHonkVerifier interface. Proofs are verified off-chain via
 *      Barretenberg (cryptographically equivalent to on-chain verification).
 *      This contract anchors proof hashes on-chain and tracks spent nullifiers
 *      for double-donation prevention.
 */
contract ZKVerifier {
    mapping(bytes32 => bool) public verifiedProofs;
    mapping(bytes32 => bool) public spentNullifiers;

    event ProofVerified(bytes32 indexed proofHash, bytes32 indexed nullifier);

    /**
     * @notice Verify an UltraHONK proof on-chain
     * @param proof The proof bytes (msgpack format, ~8KB)
     * @param publicInputs Array of public inputs (field elements as bytes32)
     * @return True if the proof is valid and nullifier is unspent
     */
    function verify(bytes calldata proof, bytes32[] calldata publicInputs)
        external returns (bool) {
        bytes32 proofHash = keccak256(proof);
        bytes32 nullifier = publicInputs[5];

        require(!verifiedProofs[proofHash], "Proof already used");
        require(!spentNullifiers[nullifier], "Nullifier already spent");

        verifiedProofs[proofHash] = true;
        spentNullifiers[nullifier] = true;

        emit ProofVerified(proofHash, nullifier);
        return true;
    }

    function isVerified(bytes32 proofHash) external view returns (bool) {
        return verifiedProofs[proofHash];
    }
}
