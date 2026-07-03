// Zakat Eligibility Circuit (Noir)
// Verifies recipient meets Sharia-compliant eligibility criteria:
// 1. Nisab: total wealth below threshold
// 2. Hawl: assets held for at least one lunar year
// 3. Nullifier hash via pedersen_hash for double-claim prevention

fn verify_nisab(income: u64, assets: u64, nisab_threshold: u64) -> bool {
    let max_income: u64 = 18446744073709551615 / 12;
    assert(income <= max_income, "Income overflow: monthly income too large");
    let annual_income = income * 12;
    let total_wealth = annual_income + assets;
    total_wealth < nisab_threshold
}

fn verify_hawl(hawl_start: u64, current_time: u64) -> bool {
    let one_lunar_year: u64 = 30569760;
    let max_start: u64 = 18446744073709551615 - one_lunar_year;
    assert(hawl_start <= max_start, "Hawl start overflow: timestamp too large");
    current_time >= hawl_start + one_lunar_year
}

fn main(
    income: u64,
    assets: u64,
    hawl_start: u64,
    secret: Field,
    amount: Field,
    nisab_threshold: pub u64,
    current_time: pub u64,
    recipient_address: pub Field,
    cycle_id: pub u64,
    expected_nullifier: pub Field
) -> pub (Field, Field) {
    let nisab_valid = verify_nisab(income, assets, nisab_threshold);
    assert(nisab_valid, "Recipient exceeds nisab threshold");

    let hawl_valid = verify_hawl(hawl_start, current_time);
    assert(hawl_valid, "Hawl period not met");

    let nullifier = std::hash::pedersen_hash([
        secret,
        recipient_address,
        cycle_id as Field
    ]);

    assert(nullifier == expected_nullifier, "Invalid nullifier");

    let amount_commitment = std::hash::pedersen_hash([
        secret,
        amount
    ]);

    (nullifier, amount_commitment)
}

#[test]
fn test_eligible_recipient() {
    let is_eligible = verify_nisab(5000000, 10000000, 85000000);
    assert(is_eligible);
}

#[test]
fn test_ineligible_recipient() {
    let is_eligible = verify_nisab(10000000, 50000000, 85000000);
    assert(!is_eligible);
}

#[test]
fn test_hawl_met() {
    let hawl_start = 1704067200;
    let current_time = 1750000000;
    let hawl_met = verify_hawl(hawl_start, current_time);
    assert(hawl_met);
}

// ==========================================================
// Boundary Value Analysis Tests (Security Analysis Section IV)
// ==========================================================

#[test]
fn test_nisab_at_exact_threshold() {
    let is_eligible = verify_nisab(5_000_000, 25_000_000, 85_000_000);
    assert(!is_eligible);
}

#[test]
fn test_nisab_just_below_threshold() {
    let is_eligible = verify_nisab(5_000_000, 24_999_999, 85_000_000);
    assert(is_eligible);
}

#[test]
fn test_nisab_overflow_rejected() {
    let income = 1_537_228_672_809_129_300;
    let assets: u64 = 0;
    let nisab: u64 = 85_000_000;
    let _ = verify_nisab(income, assets, nisab);
}

#[test(should_fail)]
fn test_nisab_overflow_panics() {
    let income = 1_537_228_672_809_129_302;
    let assets: u64 = 0;
    let nisab: u64 = 85_000_000;
    let _ = verify_nisab(income, assets, nisab);
}

#[test(should_fail)]
fn test_hawl_overflow_rejected() {
    let hawl_start: u64 = 18446744073709551615;
    let current_time: u64 = 0;
    let _ = verify_hawl(hawl_start, current_time);
}

#[test]
fn test_hawl_overflow_max_valid() {
    let hawl_start = 18446744073709551615 - 30569760;
    let current_time: u64 = 18446744073709551615;
    let hawl_met = verify_hawl(hawl_start, current_time);
    assert(hawl_met);
}

#[test]
fn test_zero_income_zero_assets() {
    let is_eligible = verify_nisab(0, 0, 85_000_000);
    assert(is_eligible);
}

#[test]
fn test_hawl_exactly_at_deadline() {
    let hawl_start = 1704067200;
    let current_time = 1704067200 + 30569760;
    let hawl_met = verify_hawl(hawl_start, current_time);
    assert(hawl_met);
}

#[test]
fn test_hawl_one_second_before_deadline() {
    let hawl_start = 1704067200;
    let current_time = 1704067200 + 30569760 - 1;
    let hawl_met = verify_hawl(hawl_start, current_time);
    assert(!hawl_met);
}