"use client";

import Link from "next/link";
import { Menu, Search } from "lucide-react";
import { useSearch } from "@/components/shared/SearchContext";
import { SearchDropdown } from "@/components/shared/SearchDropdown";
import { ConnectWalletButton } from "@/components/wallet/connect-wallet-button";
import { useLanguage } from "@/components/providers/language-provider";

export function Header() {
  const { searchQuery, setSearchQuery, isSearchOpen, setIsSearchOpen } =
    useSearch();
  const { language, setLanguage, t } = useLanguage();

  const handleEnter = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      setIsSearchOpen(false);
      window.location.href = `/campaigns?search=${encodeURIComponent(
        searchQuery
      )}`;
    }
  };

  return (
    <header className="sticky top-0 z-50 w-full border-b border-primary/10 bg-[#F9F6F0]/95 backdrop-blur-lg shadow-sm">
      {/* Height: 80px per guidelines */}
      <div className="container mx-auto flex h-20 items-center justify-between px-4 sm:px-6 lg:px-8">

        {/* LEFT */}
        <div className="flex items-center gap-8 lg:gap-10">
          <Link href="/" className="flex items-center gap-1.5">
            {/* Logo: Serif font, 24px, medium weight per guidelines */}
            <span className="font-serif text-2xl font-medium text-primary">Tawf</span>
            <span className="w-2 h-2 rounded-full bg-secondary"></span>
          </Link>

          {/* Nav links: Uppercase, wide tracking (0.2em), 14px per guidelines */}
          <nav className="hidden md:flex items-center gap-6 lg:gap-8 text-xs font-medium uppercase tracking-wide-label">
            <Link href="/campaigns" className="relative text-foreground hover:text-primary transition-colors after:content-[''] after:absolute after:-bottom-1 after:left-0 after:w-0 after:h-0.5 after:bg-primary after:transition-all hover:after:w-full">{t("header.campaigns")}</Link>
            <Link href="/governance" className="relative text-foreground hover:text-primary transition-colors after:content-[''] after:absolute after:-bottom-1 after:left-0 after:w-0 after:h-0.5 after:bg-primary after:transition-all hover:after:w-full">{t("header.governance")}</Link>
            <Link href="/explorer" className="relative text-foreground hover:text-primary transition-colors after:content-[''] after:absolute after:-bottom-1 after:left-0 after:w-0 after:h-0.5 after:bg-primary after:transition-all hover:after:w-full">{t("header.explorer")}</Link>
          </nav>
        </div>

        {/* RIGHT */}
        <div className="flex items-center gap-4">

          {/* SEARCH BAR */}
          <div className="relative hidden lg:block w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />

            <input
              type="search"
              placeholder={t("header.search")}
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setIsSearchOpen(true);
              }}
              onKeyDown={handleEnter}
              className="w-full pl-10 pr-4 h-10 bg-white/70 border border-primary/20 rounded-full outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary/30 transition-all text-sm"
            />

            {/* DROPDOWN */}
            {isSearchOpen && searchQuery && <SearchDropdown />}
          </div>

          {/* Language Toggle */}
          <div className="hidden sm:flex items-center gap-1 border border-primary/10 rounded-full p-1 bg-white/50">
            <button
              onClick={() => setLanguage("id")}
              className={`px-4 py-2 rounded-full text-xs font-medium uppercase tracking-wide-label transition-all ${
                language === "id"
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "text-foreground/60 hover:text-foreground hover:bg-white/50"
              }`}
            >
              ID
            </button>
            <button
              onClick={() => setLanguage("en")}
              className={`px-4 py-2 rounded-full text-xs font-medium uppercase tracking-wide-label transition-all ${
                language === "en"
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "text-foreground/60 hover:text-foreground hover:bg-white/50"
              }`}
            >
              EN
            </button>
          </div>

          <Link href="/organizer" className="hidden sm:flex items-center gap-2 border border-primary/20 h-10 px-6 rounded-full hover:bg-primary hover:text-primary-foreground transition-all text-xs font-medium uppercase tracking-wide-label">
            {t("header.start_campaign")}
          </Link>

          <ConnectWalletButton />

          <button className="md:hidden size-10 flex items-center justify-center rounded-full hover:bg-accent transition-colors">
            <Menu className="w-5 h-5" />
          </button>
        </div>
      </div>
    </header>
  );
}
