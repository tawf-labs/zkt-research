"use client";

import { useState } from 'react';
import { Search, Filter, SlidersHorizontal, Loader2 } from 'lucide-react';
import { useCampaigns } from '@/hooks/useCampaigns';
import { CampaignCard } from '@/components/shared/campaign-card';
import { useSearch } from "@/components/shared/SearchContext";
import { Skeleton } from '@/components/ui/skeleton';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useLanguage } from "@/components/providers/language-provider";

export default function ExploreCampaigns() {
  const { t } = useLanguage()
  const { searchQuery, setSearchQuery } = useSearch();
  const { campaigns, isLoading, error, refetch } = useCampaigns();

  // Filter states
  const [selectedCategories, setSelectedCategories] = useState<string[]>([])
  const [selectedLocations, setSelectedLocations] = useState<string[]>([])
  const [selectedOrgs, setSelectedOrgs] = useState<string[]>([])

  // Sort state
  type SortOption = 'default' | 'raised' | 'endingSoon' | 'alphabetical' | 'mostDonors';
  const [sortBy, setSortBy] = useState<SortOption>('default');

  // Filter campaigns based on search query AND selected filters
  const filteredCampaigns = campaigns.filter((c) => {
    // Search query filter
    const matchesSearch = !searchQuery || (
      c.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.organizationName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.category.toLowerCase().includes(searchQuery.toLowerCase())
    );

    // Category filter
    const matchesCategory = selectedCategories.length === 0 || selectedCategories.includes(c.category);

    // Location filter
    const matchesLocation = selectedLocations.length === 0 || selectedLocations.includes(c.location);

    // Organization filter
    const matchesOrg = selectedOrgs.length === 0 || selectedOrgs.includes(c.organizationName);

    return matchesSearch && matchesCategory && matchesLocation && matchesOrg;
  });

  // Sort filtered campaigns
  const sortedCampaigns = [...filteredCampaigns].sort((a, b) => {
    switch (sortBy) {
      case 'raised':
        return b.raised - a.raised; // Most raised first
      case 'endingSoon':
        return a.daysLeft - b.daysLeft; // Fewest days first
      case 'alphabetical':
        return a.title.localeCompare(b.title);
      case 'mostDonors':
        return b.donors - a.donors; // Most donors first
      default:
        return 0; // Default order
    }
  });

  // Extract unique categories, locations, and organizations from real data
  const categories = [...new Set(campaigns.map(c => c.category))];
  const locations = [...new Set(campaigns.map(c => c.location))];
  const organizations = [...new Set(campaigns.map(c => c.organizationName))];

  return (
    <main className="flex-1 py-8 lg:py-12 bg-background">
      <div className="container px-4 mx-auto">

        {/* Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t("campaigns.explore")}</h1>
            <p className="text-muted-foreground">{t("campaigns.findAndSupport")} ({sortedCampaigns.length} {t("campaigns.campaignCount")})</p>
          </div>

          {/* Search and Filter */}
          <div className="flex items-center gap-2 w-full md:w-auto">
            <div className="relative flex-1 md:w-64">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                type="search"
                placeholder={t("campaigns.search")}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
            </div>

            <Button
              onClick={() => refetch()}
              disabled={isLoading}
              variant="outline"
              size="icon"
              className="h-9 w-9 lg:hidden"
            >
              <Loader2 className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
            </Button>

            <Select value={sortBy} onValueChange={(v) => setSortBy(v as SortOption)}>
              <SelectTrigger className="w-[180px]">
                <SlidersHorizontal className="h-4 w-4 mr-2" />
                <SelectValue placeholder={t("campaigns.sort")} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="default">{t("campaigns.sortDefault")}</SelectItem>
                <SelectItem value="raised">{t("campaigns.sortRaised")}</SelectItem>
                <SelectItem value="endingSoon">{t("campaigns.sortEndingSoon")}</SelectItem>
                <SelectItem value="alphabetical">{t("campaigns.sortAlpha")}</SelectItem>
                <SelectItem value="mostDonors">{t("campaigns.sortDonors")}</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">

          {/* Sidebar Filters */}
          <aside className="hidden lg:block space-y-6">
            {/* Categories */}
            <div>
              <h3 className="font-semibold mb-4">{t("campaigns.categories")}</h3>
              <div className="space-y-3">
                {categories.length > 0 ? (
                  categories.map((cat) => (
                    <div key={cat} className="flex items-center space-x-2">
                      <Checkbox
                        id={`cat-${cat}`}
                        checked={selectedCategories.includes(cat)}
                        onCheckedChange={(checked) => {
                          if (checked) {
                            setSelectedCategories([...selectedCategories, cat])
                          } else {
                            setSelectedCategories(selectedCategories.filter(c => c !== cat))
                          }
                        }}
                      />
                      <Label htmlFor={`cat-${cat}`} className="text-sm font-medium cursor-pointer">
                        {cat}
                      </Label>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-muted-foreground">{t("campaigns.noCategories")}</p>
                )}
              </div>
            </div>

            <div className="h-px w-full bg-border" />

            {/* Locations */}
            <div>
              <h3 className="font-semibold mb-4">{t("campaigns.location")}</h3>
              <div className="space-y-3">
                {locations.length > 0 ? (
                  locations.map((loc) => (
                    <div key={loc} className="flex items-center space-x-2">
                      <Checkbox
                        id={`loc-${loc}`}
                        checked={selectedLocations.includes(loc)}
                        onCheckedChange={(checked) => {
                          if (checked) {
                            setSelectedLocations([...selectedLocations, loc])
                          } else {
                            setSelectedLocations(selectedLocations.filter(l => l !== loc))
                          }
                        }}
                      />
                      <Label htmlFor={`loc-${loc}`} className="text-sm font-medium cursor-pointer">
                        {loc}
                      </Label>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-muted-foreground">{t("campaigns.noLocations")}</p>
                )}
              </div>
            </div>

            <div className="h-px w-full bg-border" />

            {/* Organizations */}
            <div>
              <h3 className="font-semibold mb-4">{t("campaigns.organization")}</h3>
              <div className="space-y-3">
                {organizations.length > 0 ? (
                  organizations.map((org) => (
                    <div key={org} className="flex items-center space-x-2">
                      <Checkbox
                        id={`org-${org}`}
                        checked={selectedOrgs.includes(org)}
                        onCheckedChange={(checked) => {
                          if (checked) {
                            setSelectedOrgs([...selectedOrgs, org])
                          } else {
                            setSelectedOrgs(selectedOrgs.filter(o => o !== org))
                          }
                        }}
                      />
                      <Label htmlFor={`org-${org}`} className="text-sm font-medium cursor-pointer">
                        {org}
                      </Label>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-muted-foreground">{t("campaigns.noOrganizations")}</p>
                )}
              </div>
            </div>

            {/* Clear Filters Button - only show when filters are applied */}
            {(selectedCategories.length > 0 || selectedLocations.length > 0 || selectedOrgs.length > 0) && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setSelectedCategories([]);
                  setSelectedLocations([]);
                  setSelectedOrgs([]);
                }}
                className="w-full"
              >
                {t("campaigns.clearFilters")}
              </Button>
            )}
          </aside>

          {/* Campaign Grid */}
          <div className="lg:col-span-3">
            {/* Loading State */}
            {isLoading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {[...Array(6)].map((_, i) => (
                  <div key={i} className="space-y-4">
                    <Skeleton className="h-48 w-full rounded-lg" />
                    <Skeleton className="h-6 w-3/4" />
                    <Skeleton className="h-4 w-1/2" />
                    <Skeleton className="h-4 w-full" />
                  </div>
                ))}
              </div>
            ) : error ? (
              <div className="flex flex-col items-center justify-center py-12">
                <p className="text-red-500 font-semibold mb-4">{t("campaigns.error")}</p>
                <p className="text-muted-foreground mb-4">{error.message}</p>
                <Button onClick={() => refetch()}>
                  {t("campaigns.retry")}
                </Button>
              </div>
            ) : sortedCampaigns.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12">
                <p className="text-muted-foreground">{t("campaigns.noResults")}</p>
                {searchQuery && (
                  <Button
                    onClick={() => setSearchQuery('')}
                    variant="outline"
                    className="mt-4"
                  >
                    {t("campaigns.clearSearch")}
                  </Button>
                )}
              </div>
            ) : (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {sortedCampaigns.map((campaign, index) => (
                    <CampaignCard
                      key={campaign.id}
                      campaign={campaign}
                      priority={index < 3}  // Priority for first 3 above-the-fold cards
                      onDonationSuccess={() => {
                        setTimeout(() => refetch(), 1000); // Delay to ensure Supabase is updated
                      }}
                    />
                  ))}
                </div>

                {/* Load More */}
                <div className="mt-12 flex justify-center">
                  <Button variant="outline" size="default" className="w-full sm:w-auto">
                    {t("campaigns.loadMore")}
                  </Button>
                </div>
              </>
            )}
          </div>

        </div>
      </div>
    </main>
  );
}
