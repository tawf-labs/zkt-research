"use client";

import { useState } from "react";
import Image from "next/image";
import { MapPin, Calendar, ChevronDown, ChevronUp } from "lucide-react";

interface Beneficiary {
  name: string;
  age: number;
  photo: string;
  story: string;
  location: string;
  received: string[];
  impactDate: string;
}

interface BeneficiaryStoriesProps {
  beneficiaries: Beneficiary[];
}

export function BeneficiaryStories({ beneficiaries }: BeneficiaryStoriesProps) {
  const [expandedIndex, setExpandedIndex] = useState<number | null>(0);
  const [showAll, setShowAll] = useState(false);

  const displayStories = showAll ? beneficiaries : beneficiaries.slice(0, 3);

  if (!beneficiaries || beneficiaries.length === 0) {
    return null;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Meet the People You're Helping</h2>
          <p className="text-muted-foreground mt-1">
            Real stories from real beneficiaries whose lives have been changed
          </p>
        </div>
      </div>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
        {displayStories.map((beneficiary, index) => (
          <div
            key={index}
            className={`
              bg-card border rounded-xl overflow-hidden transition-all duration-300
              ${expandedIndex === index
                ? 'border-primary shadow-md shadow-primary/10'
                : 'border-border hover:border-primary/50'
              }
            `}
          >
            {/* Photo */}
            <div className="relative aspect-square bg-secondary/20">
              <Image
                src={beneficiary.photo}
                alt={beneficiary.name}
                fill
                className="object-cover"
                sizes="(max-width: 768px) 100vw, 33vw"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

              {/* Name overlay */}
              <div className="absolute bottom-4 left-4 right-4">
                <h3 className="text-xl font-bold text-white">{beneficiary.name}</h3>
                <p className="text-white/90 text-sm">Age {beneficiary.age}</p>
              </div>
            </div>

            {/* Content */}
            <div className="p-4 space-y-3">
              {/* Story */}
              <div className="relative">
                <button
                  onClick={() => setExpandedIndex(expandedIndex === index ? null : index)}
                  className="w-full text-left"
                >
                  <p className={`
                    text-sm leading-relaxed
                    ${expandedIndex === index ? '' : 'line-clamp-3'}
                  `}>
                    "{beneficiary.story}"
                  </p>
                </button>
              </div>

              {/* What They Received */}
              {expandedIndex === index && (
                <div className="pt-2 border-t border-border space-y-2 animate-in fade-in slide-in-from-top-2">
                  <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">
                    Received
                  </p>
                  <div className="flex flex-wrap gap-1.5">
                    {beneficiary.received.map((item, i) => (
                      <span
                        key={i}
                        className="inline-flex items-center px-2 py-1 rounded-full bg-primary/10 text-primary text-xs font-medium"
                      >
                        {item}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Location & Date */}
              <div className="flex items-center justify-between text-xs text-muted-foreground pt-2">
                <div className="flex items-center gap-1">
                  <MapPin className="h-3 w-3" />
                  <span>{beneficiary.location}</span>
                </div>
                <div className="flex items-center gap-1">
                  <Calendar className="h-3 w-3" />
                  <span>{beneficiary.impactDate}</span>
                </div>
              </div>

              {/* Expand Button */}
              <button
                onClick={() => setExpandedIndex(expandedIndex === index ? null : index)}
                className="w-full flex items-center justify-center gap-1 py-2 text-sm font-medium text-primary hover:text-primary/80 transition-colors"
              >
                {expandedIndex === index ? (
                  <>
                    <ChevronUp className="h-4 w-4" />
                    Show less
                  </>
                ) : (
                  <>
                    <ChevronDown className="h-4 w-4" />
                    Read full story
                  </>
                )}
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* View All Button */}
      {beneficiaries.length > 3 && (
        <div className="text-center">
          <button
            onClick={() => setShowAll(!showAll)}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full border border-primary/30 bg-primary/5 hover:bg-primary/10 hover:border-primary/50 transition-all font-medium text-primary"
          >
            {showAll ? (
              <>Show less</>
            ) : (
              <>View all {beneficiaries.length} stories</>
            )}
          </button>
        </div>
      )}
    </div>
  );
}
