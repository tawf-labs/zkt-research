#!/usr/bin/env bash
set -e

# ============================================================================
# ZKT End-to-End Pipeline Test
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCR="$SCRIPT_DIR"
SC_DIR="$SCR/sc"
NOIR_DIR="$SCR/noir-circuits/zkat_eligibility"
CIRCUITS_DIR="$SCR/circuits"
OFFCHAIN_DIR="$SC_DIR/offchain-coordinator"
FE_DIR="$SCR/fe"
export PATH="$HOME/.foundry/bin:$PATH"

PASS=0
FAIL=0

header() { echo ""; echo "═══════════════════════════════════════"; echo "═══ $1"; echo "═══════════════════════════════════════"; echo ""; }

run_step() {
    local name="$1"
    local cmd="$2"
    echo "--- $name ---"
    if eval "$cmd" 2>&1; then
        echo "  >>> PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "  >>> FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
    echo ""
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         ZKT End-to-End Pipeline                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ---------------------------------------------------------------
header "Step 1: Smart Contract Compilation"
cd "$SC_DIR"
run_step "Forge build" "forge build"

# ---------------------------------------------------------------
header "Step 2: Foundry Unit Tests (41 tests)"
cd "$SC_DIR"
run_step "Forge tests (full governance + donations + milestones + ZK)" \
    "forge test -vvv 2>&1 | tail -15"

# ---------------------------------------------------------------
header "Step 3: Noir ZK Circuit Tests (3 tests)"
cd "$NOIR_DIR"
run_step "Noir nargo test (nisab + hawl eligibility)" \
    "nargo test 2>&1"

# ---------------------------------------------------------------
header "Step 4: Circom Sharia Circuit Tests (5 tests)"
cd "$CIRCUITS_DIR"
run_step "Circom ZK proof test (Groth16 fullProve + verify)" \
    "timeout 300 npm test 2>&1"

# ---------------------------------------------------------------
header "Step 5: Offchain Coordinator Tests (9 tests)"
cd "$OFFCHAIN_DIR"
run_step "Coordinator API tests (health, council, voting)" \
    "timeout 30 npm test 2>&1"

# ---------------------------------------------------------------
header "Step 6: Frontend Smoke Tests (78 tests)"
cd "$FE_DIR"
run_step "Vitest (ABI validation, types, contract integrity)" \
    "npx vitest run 2>&1"

# ---------------------------------------------------------------
# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  E2E Pipeline Complete                                      ║"
echo "║  Passed: $PASS  |  Failed: $FAIL                              "
echo "╚══════════════════════════════════════════════════════════════╝"

exit $FAIL
