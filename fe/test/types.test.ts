import { describe, it, expect } from "vitest";
import { ProposalStatus, KYCStatus, CampaignType, VoteSupport, ZakatChecklistItem } from "@/lib/types";

describe("ProposalStatus enum", () => {
    it("has all lifecycle states", () => {
        expect(ProposalStatus.Draft).toBe(0);
        expect(ProposalStatus.CommunityVote).toBe(1);
        expect(ProposalStatus.CommunityPassed).toBe(2);
        expect(ProposalStatus.CommunityRejected).toBe(3);
        expect(ProposalStatus.ShariaReview).toBe(4);
        expect(ProposalStatus.ShariaApproved).toBe(5);
        expect(ProposalStatus.ShariaRejected).toBe(6);
        expect(ProposalStatus.PoolCreated).toBe(7);
        expect(ProposalStatus.Completed).toBe(8);
        expect(ProposalStatus.Canceled).toBe(9);
    });

    it("has 10 unique values", () => {
        const values = Object.values(ProposalStatus).filter(v => typeof v === "number");
        expect(new Set(values).size).toBe(10);
    });
});

describe("KYCStatus enum", () => {
    it("matches contract enum values", () => {
        expect(KYCStatus.NotRequired).toBe(0);
        expect(KYCStatus.Pending).toBe(1);
        expect(KYCStatus.Verified).toBe(2);
        expect(KYCStatus.Rejected).toBe(3);
    });
});

describe("CampaignType enum", () => {
    it("matches contract enum values", () => {
        expect(CampaignType.Normal).toBe(0);
        expect(CampaignType.ZakatCompliant).toBe(1);
        expect(CampaignType.Emergency).toBe(2);
    });
});

describe("VoteSupport enum", () => {
    it("has correct vote values", () => {
        expect(VoteSupport.Against).toBe(0);
        expect(VoteSupport.For).toBe(1);
        expect(VoteSupport.Abstain).toBe(2);
    });
});

describe("ZakatChecklistItem enum", () => {
    it("has 5 checklist items", () => {
        expect(ZakatChecklistItem.RecipientsVerified).toBe(0);
        expect(ZakatChecklistItem.FundsDistributionPlan).toBe(1);
        expect(ZakatChecklistItem.CompliantWithSharia).toBe(2);
        expect(ZakatChecklistItem.TransparencyCommitment).toBe(3);
        expect(ZakatChecklistItem.RegularReporting).toBe(4);
    });
});
