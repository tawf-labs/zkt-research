// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;

/**
 * @title NullifierRegistry
 * @notice On-chain registry of spent nullifiers for double-donation prevention
 * @dev Uses a mapping for O(1) lookup. For large-scale deployments, a Merkle tree
 *      would reduce storage costs, but a flat mapping is sufficient for prototype scope.
 */
contract NullifierRegistry {
    mapping(bytes32 => bool) public spentNullifiers;

    event NullifierSpent(bytes32 indexed nullifier, address indexed spender, uint256 timestamp);

    /**
     * @notice Spend a nullifier (reverts if already spent)
     * @param nullifier The nullifier to mark as spent
     */
    function spend(bytes32 nullifier) external {
        require(!spentNullifiers[nullifier], "NullifierAlreadySpent");
        spentNullifiers[nullifier] = true;
        emit NullifierSpent(nullifier, msg.sender, block.timestamp);
    }

    /**
     * @notice Check if a nullifier has been spent
     */
    function isSpent(bytes32 nullifier) external view returns (bool) {
        return spentNullifiers[nullifier];
    }
}
