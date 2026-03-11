"use client";

import { useEffect, useState } from "react";
import { AlertTriangle, Clock, Flame, Users } from "lucide-react";

interface UrgencyInfo {
  type: 'families-waiting' | 'deadline' | 'limited-spots';
  message: string;
  count?: number;
}

interface UrgencyBannerProps {
  urgency: UrgencyInfo;
}

// Simulated recent donations for live feed
const recentDonations = [
  { amount: 50000, time: 'just now' },
  { amount: 25000, time: '2 mins ago' },
  { amount: 100000, time: '5 mins ago' },
  { amount: 75000, time: '8 mins ago' },
  { amount: 50000, time: '12 mins ago' },
];

export function UrgencyBanner({ urgency }: UrgencyBannerProps) {
  const [currentDonation, setCurrentDonation] = useState(recentDonations[0]);
  const [isVisible, setIsVisible] = useState(true);

  // Cycle through recent donations
  useEffect(() => {
    if (!isVisible) return;

    const interval = setInterval(() => {
      const randomIndex = Math.floor(Math.random() * recentDonations.length);
      setCurrentDonation(recentDonations[randomIndex]);
    }, 8000);

    return () => clearInterval(interval);
  }, [isVisible]);

  const getUrgencyConfig = () => {
    switch (urgency.type) {
      case 'families-waiting':
        return {
          icon: <Users className="h-5 w-5" />,
          bgColor: 'bg-orange-500/10',
          borderColor: 'border-orange-500/30',
          textColor: 'text-orange-600',
          title: 'Families Waiting for Help',
        };
      case 'deadline':
        return {
          icon: <Clock className="h-5 w-5" />,
          bgColor: 'bg-red-500/10',
          borderColor: 'border-red-500/30',
          textColor: 'text-red-600',
          title: 'Deadline Approaching',
        };
      case 'limited-spots':
        return {
          icon: <AlertTriangle className="h-5 w-5" />,
          bgColor: 'bg-amber-500/10',
          borderColor: 'border-amber-500/30',
          textColor: 'text-amber-600',
          title: 'Limited Impact Spots',
        };
      default:
        return {
          icon: <Flame className="h-5 w-5" />,
          bgColor: 'bg-primary/10',
          borderColor: 'border-primary/30',
          textColor: 'text-primary',
          title: 'Act Now',
        };
    }
  };

  const config = getUrgencyConfig();

  return (
    <div className="space-y-4">
      {/* Main Urgency Banner */}
      <div className={`flex items-start gap-3 p-4 rounded-xl border ${config.bgColor} ${config.borderColor}`}>
        <div className={`${config.textColor} flex-shrink-0 mt-0.5`}>
          {config.icon}
        </div>
        <div className="flex-1 min-w-0">
          <h4 className={`font-semibold ${config.textColor} flex items-center gap-2`}>
            {config.title}
            {urgency.count !== undefined && (
              <span className="text-2xl font-bold">{urgency.count}</span>
            )}
          </h4>
          <p className="text-sm text-foreground mt-1">
            {urgency.message}
          </p>
        </div>
      </div>

      {/* Live Donation Feed */}
      <div className="bg-card border border-border rounded-xl p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="relative">
              <span className="flex h-3 w-3">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
              </span>
            </div>
            <span className="text-sm font-medium text-foreground">Live donations</span>
          </div>

          <div className={`transition-all duration-500 ${isVisible ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-4'}`}>
            <p className="text-sm">
              <span className="font-semibold text-primary">
                {currentDonation.amount.toLocaleString('id-ID')} IDRX
              </span>
              <span className="text-muted-foreground"> {currentDonation.time}</span>
            </p>
          </div>
        </div>
      </div>

      {/* Matching Banner (Optional - can be enabled per campaign) */}
      <div className="hidden sm:flex items-center gap-3 p-3 rounded-lg bg-primary/10 border border-primary/20">
        <Flame className="h-5 w-5 text-primary flex-shrink-0" />
        <div className="flex-1">
          <p className="text-sm font-medium text-foreground">
            Your donation has immediate impact
          </p>
          <p className="text-xs text-muted-foreground">
            Funds go directly to beneficiaries — transparently on-chain
          </p>
        </div>
      </div>
    </div>
  );
}
