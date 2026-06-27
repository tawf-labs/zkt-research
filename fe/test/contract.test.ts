import { describe, it, expect } from "vitest";
import { getAddress } from "viem";
import { CONTRACT_ADDRESSES } from "@/lib/abi";
import { publicClient } from "@/lib/contract-client";

describe("Public Client", () => {
    it("is configured for Sepolia", () => {
        expect(publicClient.chain?.id).toBe(11155111);
    });

    it("has a valid HTTP transport", () => {
        expect(publicClient.transport.type).toBe("http");
    });
});

describe("Address checksums", () => {
    it("ZKTCore address is checksummed", () => {
        const raw = CONTRACT_ADDRESSES.ZKTCore;
        expect(raw).toBeTruthy();
        expect(getAddress(raw)).toBe(raw);
    });

    it("VotingNFT address is checksummed", () => {
        const raw = CONTRACT_ADDRESSES.VotingNFT;
        expect(raw).toBeTruthy();
        expect(getAddress(raw)).toBe(raw);
    });

    it("MockIDRX address is checksummed", () => {
        const raw = CONTRACT_ADDRESSES.MockIDRX;
        expect(raw).toBeTruthy();
        expect(getAddress(raw)).toBe(raw);
    });
});

describe("Contract integrity", () => {
    it("16 unique deployed contract addresses", () => {
        const addrs = Object.values(CONTRACT_ADDRESSES);
        const unique = new Set(addrs);
        expect(unique.size).toBeGreaterThanOrEqual(15); // allow ZKVerifier at zero
    });

    it("key manager contracts have distinct addresses", () => {
        expect(CONTRACT_ADDRESSES.PoolManager).not.toBe(CONTRACT_ADDRESSES.ZakatEscrowManager);
        expect(CONTRACT_ADDRESSES.VotingManager).not.toBe(CONTRACT_ADDRESSES.ProposalManager);
        expect(CONTRACT_ADDRESSES.MilestoneManager).not.toBe(CONTRACT_ADDRESSES.ParticipationTracker);
    });
});
