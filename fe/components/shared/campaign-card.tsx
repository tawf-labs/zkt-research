"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Users, Clock, CircleCheck } from "lucide-react";
import { Campaign } from "@/hooks/useCampaigns";
import { DonationDialog } from "@/components/donations/donation-dialog";
import { Heart } from "lucide-react";

interface CampaignCardProps {
  campaign: Campaign;
  onDonationSuccess?: () => void;
}

const calculateProgress = (raised: number, goal: number) => {
  const progress = (raised / goal) * 100;
  return Math.min(progress, 100) - 100;
};

const formatCurrency = (amount: number) => {
  return `${amount.toLocaleString('id-ID', { maximumFractionDigits: 0 })} IDRX`;
};

// Real-time daysLeft calculator
const calculateRealTimeDaysLeft = (endDate: number): number => {
  const now = Math.floor(Date.now() / 1000);
  const daysLeft = Math.ceil((endDate - now) / 86400);
  return Math.max(daysLeft, 0);
};

export function CampaignCard({ campaign, onDonationSuccess }: CampaignCardProps) {
  const router = useRouter();
  const [showDonationDialog, setShowDonationDialog] = useState(false);
  const [daysLeft, setDaysLeft] = useState(calculateRealTimeDaysLeft(campaign.endDate));
  const [raisedAmount, setRaisedAmount] = useState(campaign.raised);
  const progress = calculateProgress(raisedAmount, campaign.goal);

  const handleCardClick = () => {
    router.push(`/campaigns/${campaign.id}`);
  };

  const handleDonateClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setShowDonationDialog(true);
  };

  // Real-time countdown timer
  useEffect(() => {
    const timer = setInterval(() => {
      setDaysLeft(calculateRealTimeDaysLeft(campaign.endDate));
    }, 60_000); // Update every minute for efficiency

    return () => clearInterval(timer);
  }, [campaign.endDate]);

  // Sync raised amount with campaign prop
  useEffect(() => {
    setRaisedAmount(campaign.raised);
  }, [campaign.raised]);

  return (
    <div
      onClick={handleCardClick}
      className="bg-card text-card-foreground rounded-2xl gap-6 border border-primary/10 hover:shadow-xl hover:border-primary/30 transition-all duration-300 group h-full flex flex-col cursor-pointer overflow-hidden"
    >
      <div className="relative h-56 overflow-hidden rounded-t-2xl bg-secondary/20">
        <Image
          src={campaign.image || campaign.imageUrl || "https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?w=500"}
          alt={campaign.title}
          fill
          className="object-cover transition-transform duration-500 group-hover:scale-105"
        />

        {/* Better overlay gradient */}
        <div className="absolute inset-0 bg-gradient-to-t from-primary/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />

        <div className="absolute top-4 left-4 flex flex-col gap-2">
          {/* Updated with uppercase tracking-wide-label per guidelines */}
          <span className="inline-flex items-center justify-center rounded-full px-4 py-1.5 text-xs font-semibold bg-white/95 backdrop-blur-sm border border-primary/10 text-primary w-fit uppercase tracking-wide-label">
            {campaign.category || "General"}
          </span>
          {/* NEW: Families Helped Badge */}
          {campaign.familiesHelped && (
            <span className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full bg-primary/95 backdrop-blur-sm text-white text-xs font-medium shadow-md">
              <Heart className="h-3 w-3 fill-white" />
              {campaign.familiesHelped} families helped
            </span>
          )}
        </div>

        <div className="absolute bottom-4 right-4">
          {/* Updated with uppercase tracking-wide-label per guidelines */}
          <span className="inline-flex items-center gap-1.5 bg-primary text-primary-foreground px-3 py-1.5 rounded-full text-xs font-medium shadow-md uppercase tracking-wide-label">
            <CircleCheck className="h-3 w-3" /> {campaign.isVerified ? "Verified" : "Unverified"}
          </span>
        </div>
      </div>

      <div className="@container/card-header grid auto-rows-min grid-rows-[auto_auto] items-start gap-1.5 p-6 pb-2 space-y-2">
        <div className="text-xs text-muted-foreground font-medium flex items-center gap-1">
          by{" "}
          <span className="text-primary font-semibold hover:underline cursor-pointer">
            {campaign.organizationName || "Unknown"}
          </span>
        </div>

        <h3 className="font-serif font-extrabold text-lg leading-snug line-clamp-2 group-hover:text-primary transition-colors">
          {campaign.title}
        </h3>
      </div>

      <div className="p-6 pt-2 flex-1">
        <div className="space-y-3">
          <div className="flex justify-between text-sm">
            <span className="font-bold text-foreground">
              {formatCurrency(campaign.raised)}
            </span>
            <span className="text-muted-foreground">
              of {formatCurrency(campaign.goal)}
            </span>
          </div>

          <div className="w-full h-2.5 bg-secondary/20 rounded-full overflow-hidden shadow-inner">
            <div
              className="bg-gradient-to-r from-primary to-primary/80 h-full rounded-full transition-all duration-500"
              style={{ width: `${Math.min((campaign.raised / campaign.goal) * 100, 100)}%` }}
            />
          </div>

          <div className="flex justify-between items-center text-xs text-muted-foreground pt-1">
            <div className="flex items-center gap-1">
              <Users className="h-3.5 w-3.5" />
              <span>{campaign.donors.toLocaleString()} donors</span>
            </div>

            {/* Updated with uppercase tracking-wide-label per guidelines */}
            <div className="flex items-center gap-1 bg-secondary/30 px-3 py-1.5 rounded-full">
              <Clock className="h-3.5 w-3.5" />
              <span className="font-medium text-foreground uppercase tracking-wide-label">
                {campaign.daysLeft} days left
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="p-6 pt-0">
        {/* Updated with uppercase tracking-wide-label per guidelines */}
        <button
          onClick={handleDonateClick}
          className="w-full h-12 rounded-full bg-primary text-primary-foreground font-semibold hover:bg-primary/90 hover:shadow-md hover:shadow-primary/20 transition-all uppercase tracking-wide-label"
        >
          Donate Now
        </button>
      </div>

      <DonationDialog
        open={showDonationDialog}
        onOpenChange={setShowDonationDialog}
        campaignId={campaign.id}
        campaignTitle={campaign.title}
        campaignGoal={campaign.goal}
        campaignRaised={campaign.raised}
      />
    </div>
  );
}
