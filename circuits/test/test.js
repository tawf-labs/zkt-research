const snarkjs = require("snarkjs");
const path = require("path");
const assert = require("assert");
const Scalar = require("ffjavascript").Scalar;
const circomlibjs = require("circomlibjs");

const WASM_PATH = path.join(__dirname, "..", "build", "ShariaVoteAggregator_js", "ShariaVoteAggregator.wasm");
const ZKEY_PATH = path.join(__dirname, "..", "build", "sharia_0000.zkey");

let poseidon;

async function poseidonHash(inputs) {
    return Scalar.e(poseidon.F.toString(poseidon(inputs.map(i => BigInt(i)))));
}

async function buildMerkleTree(leaves, depth) {
    const width = 1 << depth;
    const tree = new Array(2 * width);
    for (let i = 0; i < width; i++) {
        tree[width + i] = Scalar.e(i < leaves.length ? leaves[i] : 0);
    }
    for (let i = width - 1; i > 0; i--) {
        tree[i] = await poseidonHash([tree[2 * i], tree[2 * i + 1]]);
    }
    return { tree, root: tree[1], width };
}

function getMerkleProof(merkle, leafIndex) {
    const { tree, width } = merkle;
    const proofElements = [];
    const proofPathIndices = [];
    let idx = width + leafIndex;
    for (let level = 0; level < Math.log2(width); level++) {
        const siblingIdx = idx % 2 === 0 ? idx + 1 : idx - 1;
        proofElements.push(Scalar.toString(tree[siblingIdx]));
        proofPathIndices.push(idx % 2 === 0 ? 0 : 1);
        idx = Math.floor(idx / 2);
    }
    return { proofElements, proofPathIndices };
}

async function buildInput(N_COUNCIL, TREE_DEPTH, bundleId, proposalId, quorumThreshold, votes) {
    const memberIds = Array.from({ length: N_COUNCIL }, (_, i) => Scalar.e(BigInt(10000 + i * 70000)));
    const memberSecrets = Array.from({ length: N_COUNCIL }, (_, i) => Scalar.e(BigInt(99999 + i * 77777)));

    const memberCommitments = [];
    for (let i = 0; i < N_COUNCIL; i++) {
        memberCommitments.push(await poseidonHash([memberIds[i], memberSecrets[i]]));
    }

    const councilMerkle = await buildMerkleTree(memberCommitments, TREE_DEPTH);
    const nullifierMerkle = await buildMerkleTree(memberSecrets, TREE_DEPTH);

    const approvalCount = votes.reduce((sum, v) => sum + v, 0);

    const voteNullifiers = [];
    for (let i = 0; i < N_COUNCIL; i++) {
        voteNullifiers.push(await poseidonHash([memberSecrets[i], Scalar.e(BigInt(bundleId * 10000 + proposalId))]));
    }

    const merkleProofElements = [];
    const merkleProofPathIndices = [];
    for (let i = 0; i < N_COUNCIL; i++) {
        const proof = getMerkleProof(councilMerkle, i);
        merkleProofElements.push(proof.proofElements);
        merkleProofPathIndices.push(proof.proofPathIndices);
    }

    return {
        councilMemberVote: votes,
        memberCommitment: memberCommitments.map(c => Scalar.toString(c)),
        voteNullifier: voteNullifiers.map(n => Scalar.toString(n)),
        merkleProofElements,
        merkleProofPathIndices,
        bundleId,
        proposalId,
        approvalCount,
        quorumThreshold,
        councilRoot: Scalar.toString(councilMerkle.root),
        nullifierRoot: Scalar.toString(nullifierMerkle.root),
    };
}

async function getVerificationKey() {
    return await snarkjs.zKey.exportVerificationKey(ZKEY_PATH);
}

async function testValidProof() {
    console.log("\n--- Test: Valid Proof (3/5 Quorum) ---");

    const input = await buildInput(5, 3, 1, 42, 3, [1, 1, 1, 0, 0]);

    console.log("Generating Groth16 proof...");
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, WASM_PATH, ZKEY_PATH);

    assert.ok(proof, "Proof should be generated");
    assert.ok(publicSignals.length > 0, "Should have public signals");

    console.log("Verifying Groth16 proof...");
    const vKey = await getVerificationKey();
    const valid = await snarkjs.groth16.verify(vKey, publicSignals, proof);

    assert.strictEqual(valid, true, "Groth16 proof should verify");
    console.log("PASS: Valid proof generated and verified");
}

async function testInsufficientQuorum() {
    console.log("\n--- Test: Insufficient Quorum (2/5, need 3) ---");

    const input = await buildInput(5, 3, 2, 99, 3, [1, 1, 0, 0, 0]);

    try {
        await snarkjs.groth16.fullProve(input, WASM_PATH, ZKEY_PATH);
        assert.fail("Should have failed due to insufficient quorum");
    } catch (err) {
        const msg = err.message || String(err);
        assert.ok(
            msg.includes("Constraint") || msg.includes("assert") || msg.includes("Error") || msg.includes("FAIL") || msg.includes("not"),
            `Expected constraint error, got: ${msg}`
        );
        console.log("PASS: Insufficient quorum rejected by circuit");
    }
}

async function testNonBinaryVote() {
    console.log("\n--- Test: Non-Binary Vote (contains vote=2) ---");

    const input = await buildInput(5, 3, 3, 55, 3, [1, 1, 1, 2, 0]);

    try {
        await snarkjs.groth16.fullProve(input, WASM_PATH, ZKEY_PATH);
        assert.fail("Should have failed due to non-binary vote");
    } catch (err) {
        const msg = err.message || String(err);
        assert.ok(
            msg.includes("Constraint") || msg.includes("assert") || msg.includes("Error") || msg.includes("FAIL") || msg.includes("not"),
            `Expected constraint error, got: ${msg}`
        );
        console.log("PASS: Non-binary vote rejected by circuit");
    }
}

async function testUnanimousApproval() {
    console.log("\n--- Test: Unanimous Approval (5/5) ---");

    const input = await buildInput(5, 3, 4, 100, 3, [1, 1, 1, 1, 1]);

    console.log("Generating Groth16 proof...");
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, WASM_PATH, ZKEY_PATH);

    const vKey = await getVerificationKey();
    const valid = await snarkjs.groth16.verify(vKey, publicSignals, proof);

    assert.strictEqual(valid, true, "Unanimous approval proof should verify");
    console.log("PASS: Unanimous approval proof generated and verified");
}

async function testMismatchedApprovalCount() {
    console.log("\n--- Test: Mismatched Approval Count (claims 4, actual 3) ---");

    const input = await buildInput(5, 3, 5, 77, 3, [1, 1, 1, 0, 0]);
    input.approvalCount = 4;

    try {
        await snarkjs.groth16.fullProve(input, WASM_PATH, ZKEY_PATH);
        assert.fail("Should have failed due to mismatched count");
    } catch (err) {
        const msg = err.message || String(err);
        assert.ok(
            msg.includes("Constraint") || msg.includes("assert") || msg.includes("Error") || msg.includes("FAIL") || msg.includes("not"),
            `Expected constraint error, got: ${msg}`
        );
        console.log("PASS: Mismatched approval count rejected");
    }
}

async function main() {
    console.log("=== ShariaVoteAggregator Circuit Test Suite ===\n");

    console.log("Initializing Poseidon hash...");
    poseidon = await circomlibjs.buildPoseidon();
    console.log("Poseidon initialized.\n");

    let passed = 0;
    let failed = 0;

    const tests = [
        ["Valid Proof (3/5 Quorum)", testValidProof],
        ["Insufficient Quorum", testInsufficientQuorum],
        ["Non-Binary Vote", testNonBinaryVote],
        ["Unanimous Approval", testUnanimousApproval],
        ["Mismatched Approval Count", testMismatchedApprovalCount],
    ];

    for (const [name, testFn] of tests) {
        try {
            await testFn();
            passed++;
        } catch (err) {
            failed++;
            console.error(`\nFAIL: ${name}`);
            console.error(err.message);
        }
    }

    console.log(`\n=== Results: ${passed} passed, ${failed} failed ===`);
    process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
    console.error("Fatal error:", err);
    process.exit(1);
});
