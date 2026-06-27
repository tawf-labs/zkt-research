import { describe, it, expect } from "vitest";
import { CONTRACT_ADDRESSES, ZKTCoreABI, ShariaReviewManagerABI, PrivateDonationPoolABI, HonkVerifierABI, Groth16VerifierABI, NullifierRegistryABI, ZKVerifierABI, PoolManagerABI, ZakatEscrowManagerABI, MilestoneManagerABI, VotingManagerABI, VotingNFTABI, ProposalManagerABI, ParticipationTrackerABI, TawfPassportABI } from "@/lib/abi";

const addressRegex = /^0x[0-9a-fA-F]{40}$/;

const expectedContracts = [
    "ZKTCore",
    "ShariaReviewManager",
    "PrivateDonationPool",
    "HonkVerifier",
    "Groth16Verifier",
    "NullifierRegistry",
    "ZKVerifier",
    "TawfPassport",
    "TawfReputation",
    "MockIDRX",
    "VotingNFT",
    "DonationReceiptNFT",
    "ProposalManager",
    "VotingManager",
    "MilestoneManager",
    "ParticipationTracker",
    "PoolManager",
    "ZakatEscrowManager",
];

describe("Contract Addresses", () => {
    for (const contract of expectedContracts) {
        it(`${contract} address is a valid Ethereum address`, () => {
            const addr = CONTRACT_ADDRESSES[contract as keyof typeof CONTRACT_ADDRESSES];
            expect(addr).toBeDefined();
            expect(addr).toMatch(addressRegex);
        });
    }

    it("all 18 contracts are registered", () => {
        expect(Object.keys(CONTRACT_ADDRESSES).length).toBe(18);
    });

    it("no zero address for critical contracts", () => {
        const critical = ["ZKTCore", "VotingNFT", "DonationReceiptNFT", "ProposalManager", "MockIDRX"];
        for (const name of critical) {
            const addr = CONTRACT_ADDRESSES[name as keyof typeof CONTRACT_ADDRESSES];
            expect(addr).not.toBe("0x0000000000000000000000000000000000000000");
        }
    });
});

function validateABI(label: string, abi: unknown) {
    describe(label, () => {
        it("is a non-empty array", () => {
            expect(Array.isArray(abi)).toBe(true);
            expect((abi as unknown[]).length).toBeGreaterThan(0);
        });

        it("has valid function/event/error entries", () => {
            const arr = abi as Record<string, unknown>[];
            for (const entry of arr) {
                expect(entry.type).toBeDefined();
                if (entry.type === "function") {
                    expect(entry.name).toBeDefined();
                    expect(typeof entry.name).toBe("string");
                }
            }
        });

        it("has at least one function entry", () => {
            const arr = abi as Record<string, unknown>[];
            expect(arr.some(e => e.type === "function")).toBe(true);
        });
    });
}

validateABI("ZKTCoreABI", ZKTCoreABI);
validateABI("ShariaReviewManagerABI", ShariaReviewManagerABI);
validateABI("PrivateDonationPoolABI", PrivateDonationPoolABI);
validateABI("HonkVerifierABI", HonkVerifierABI);
validateABI("Groth16VerifierABI", Groth16VerifierABI);
validateABI("NullifierRegistryABI", NullifierRegistryABI);
validateABI("ZKVerifierABI", ZKVerifierABI);
validateABI("PoolManagerABI", PoolManagerABI);
validateABI("ZakatEscrowManagerABI", ZakatEscrowManagerABI);
validateABI("MilestoneManagerABI", MilestoneManagerABI);
validateABI("VotingManagerABI", VotingManagerABI);
validateABI("VotingNFTABI", VotingNFTABI);
validateABI("ProposalManagerABI", ProposalManagerABI);
validateABI("ParticipationTrackerABI", ParticipationTrackerABI);
validateABI("TawfPassportABI", TawfPassportABI);
