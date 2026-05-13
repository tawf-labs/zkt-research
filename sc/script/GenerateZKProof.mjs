#!/usr/bin/env node
/**
 * ZK-PZ Proof Generator
 * Generates an UltraHONK proof for the ZakatEligibility circuit.
 * 
 * Usage: node generate-proof.mjs [--income N] [--assets N] [--hawl-start T] [--secret N]
 *
 * Prerequisites:
 *   nargo nightly (v1.0.0-beta.21+) at /tmp/nargo-nightly/nargo
 *   bb (v4.2.1) at /tmp/bb_dir/bb
 *   Bench circuit at /tmp/zkt-bench/
 */

import { execSync } from 'child_process';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BB = '/tmp/bb_dir/bb';
const NARGO = '/tmp/nargo-nightly/nargo';
const CIRCUIT_DIR = '/tmp/zkt-bench';
const OUTPUT_DIR = join(__dirname, '..', 'proofs');

// Default inputs (eligible recipient: 5M/month income + 10M assets < 85M nisab)
const defaults = {
  income: 5000000,
  assets: 10000000,
  hawlStart: 1704067200,       // 2024-01-01 UTC
  secret: 12345,                // donor secret for nullifier
  nisabThreshold: 85000000,     // 85M IDR
  currentTime: 1750000000,      // 2025-06-15 (hawl met)
  recipientAddress: 10,         // placeholder address
  cycleId: 1,
};

function parseArgs() {
  const args = process.argv.slice(2);
  const inputs = { ...defaults };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--income' && args[i+1]) inputs.income = parseInt(args[i+1]);
    if (args[i] === '--assets' && args[i+1]) inputs.assets = parseInt(args[i+1]);
    if (args[i] === '--hawl-start' && args[i+1]) inputs.hawlStart = parseInt(args[i+1]);
    if (args[i] === '--secret' && args[i+1]) inputs.secret = parseInt(args[i+1]);
  }
  return inputs;
}

function main() {
  const inputs = parseArgs();
  console.log('Generating ZK proof with inputs:');
  console.log(JSON.stringify(inputs, null, 2));

  // 1. Write Prover.toml
  const proverToml = [
    `income = "${inputs.income}"`,
    `assets = "${inputs.assets}"`,
    `hawl_start = "${inputs.hawlStart}"`,
    `secret = "0x${inputs.secret.toString(16)}"`,
    `nisab_threshold = "${inputs.nisabThreshold}"`,
    `current_time = "${inputs.currentTime}"`,
    `recipient_address = "0x${inputs.recipientAddress.toString(16)}"`,
    `cycle_id = "${inputs.cycleId}"`,
    `expected_nullifier = "0"`,
  ].join('\n');
  writeFileSync(join(CIRCUIT_DIR, 'Prover.toml'), proverToml);

  // 2. Compile + Execute
  console.log('\nCompiling circuit...');
  execSync(`${NARGO} compile`, { cwd: CIRCUIT_DIR, stdio: 'pipe' });
  console.log('Generating witness...');
  execSync(`${NARGO} execute`, { cwd: CIRCUIT_DIR, stdio: 'pipe' });

  // 3. Generate proof
  mkdirSync(OUTPUT_DIR, { recursive: true });
  const proofDir = join(OUTPUT_DIR, `proof_${Date.now()}`);
  mkdirSync(proofDir, { recursive: true });

  console.log('Proving (UltraHONK evm)...');
  const start = Date.now();
  execSync(
    `${BB} prove -b ${CIRCUIT_DIR}/target/zkt_bench.json ` +
    `-w ${CIRCUIT_DIR}/target/zkt_bench.gz ` +
    `-o ${proofDir} -k ${CIRCUIT_DIR}/target/vk/vk -t evm`,
    { stdio: 'pipe' }
  );
  const proveTime = Date.now() - start;

  // 4. Read outputs
  const proof = readFileSync(join(proofDir, 'proof'));
  const publicInputs = readFileSync(join(proofDir, 'public_inputs'));

  // Parse public inputs as bytes32 array
  const pi = [];
  for (let i = 0; i < publicInputs.length; i += 32) {
    pi.push('0x' + publicInputs.slice(i, i + 32).toString('hex'));
  }

  // 5. Summary
  const proofHex = '0x' + proof.toString('hex');
  console.log('\n=== PROOF GENERATED ===');
  console.log(`Prove time: ${proveTime} ms`);
  console.log(`Proof bytes: ${proof.length}`);
  console.log(`Public inputs: ${pi.length} fields`);
  console.log(`Nullifier: ${pi[5]}`);

  // 6. Write calldata for cast send
  const calldata = JSON.stringify({
    proof: '0x' + proof.toString('hex'),
    publicInputs: pi,
    nullifier: pi[5],
  }, null, 2);
  writeFileSync(join(proofDir, 'calldata.json'), calldata);
  console.log(`\nCalldata saved to: ${proofDir}/calldata.json`);
  console.log(`Now run: cast send $ZKTCORE "donateZK(uint256,uint256,bytes,bytes32[],bytes32,string)" ...`);
}

main();
