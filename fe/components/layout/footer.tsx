import { Twitter, Linkedin, Github, Instagram } from "lucide-react";
import Link from "next/link"

export function Footer() {
  return (
    // Padding: 64px vertical per guidelines
    <footer className="bg-[#1A1A1A] text-white/80 pt-16 pb-8">
      <div className="container px-4 sm:px-6 mx-auto">

        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-8 md:gap-12 mb-12">

          {/* Logo + description */}
          <div className="col-span-2 lg:col-span-2 space-y-6">
             <Link href="/" className="flex items-center space-x-2">
            <span className="font-serif text-2xl font-medium text-white">
              Tawf
            </span>
          </Link>

            <p className="text-white/80 max-w-sm leading-relaxed">
              The world's first fully traceable Zakat and donation platform. Empowering transparent giving through blockchain technology.
            </p>

            {/* Social Icons - Hover to tawf-gold per guidelines */}
            <div className="flex gap-4">
              <a href="#" className="text-white/70 hover:text-tawf-gold transition-colors">
                <Twitter className="h-5 w-5" />
              </a>

              <a href="#" className="text-white/70 hover:text-tawf-gold transition-colors">
                <Linkedin className="h-5 w-5" />
              </a>

              <a href="#" className="text-white/70 hover:text-tawf-gold transition-colors">
                <Github className="h-5 w-5" />
              </a>

              <a href="#" className="text-white/70 hover:text-tawf-gold transition-colors">
                <Instagram className="h-5 w-5" />
              </a>
            </div>
          </div>

          {/* Platform Column */}
          <div className="space-y-4">
            <h3 className="font-serif font-bold text-lg text-white">Platform</h3>
            <ul className="space-y-2">
              <li><a href="/campaigns" className="text-white/70 hover:text-tawf-gold transition-colors">Explore Campaigns</a></li>
              <li><a href="/zakat" className="text-white/70 hover:text-tawf-gold transition-colors">Zakat</a></li>
              <li><a href="/governance" className="text-white/70 hover:text-tawf-gold transition-colors">DAO Governance</a></li>
              <li><a href="/impact" className="text-white/70 hover:text-tawf-gold transition-colors">Impact Reports</a></li>
            </ul>
          </div>

          {/* For Users Column */}
          <div className="space-y-4">
            <h3 className="font-serif font-bold text-lg text-white">For Users</h3>
            <ul className="space-y-2">
              <li><a href="/dashboard/donor" className="text-white/70 hover:text-tawf-gold transition-colors">Donor Dashboard</a></li>
              <li><a href="/my-donations" className="text-white/70 hover:text-tawf-gold transition-colors">My Donations</a></li>
            </ul>
          </div>

          {/* For Organizations Column */}
          <div className="space-y-4">
            <h3 className="font-serif font-bold text-lg text-white">For Organizations</h3>
            <ul className="space-y-2">
              <li><a href="/partners" className="text-white/70 hover:text-tawf-gold transition-colors">Become a Partner</a></li>
              <li><a href="/dashboard/organization" className="text-white/70 hover:text-tawf-gold transition-colors">Organization Dashboard</a></li>
              <li><a href="/verification" className="text-white/70 hover:text-tawf-gold transition-colors">Verification Process</a></li>
              <li><a href="/resources" className="text-white/70 hover:text-tawf-gold transition-colors">Resources</a></li>
            </ul>
          </div>

          {/* Legal Column */}
          <div className="space-y-4">
            <h3 className="font-serif font-bold text-lg text-white">Legal</h3>
            <ul className="space-y-2">
              <li><a href="/privacy" className="text-white/70 hover:text-tawf-gold transition-colors">Privacy Policy</a></li>
              <li><a href="/terms" className="text-white/70 hover:text-tawf-gold transition-colors">Terms of Service</a></li>
              <li><a href="/compliance" className="text-white/70 hover:text-tawf-gold transition-colors">Sharia Compliance</a></li>
              <li><a href="/audit" className="text-white/70 hover:text-tawf-gold transition-colors">Audit Logs</a></li>
            </ul>
          </div>

        </div>

        {/* Bottom Section */}
        <div className="pt-8 border-t border-white/10 flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-sm text-white/70">© 2026 Tawf Foundation. All rights reserved.</p>

          <div className="flex gap-6 text-sm text-white/70">
            <span>Powered by Xellar</span>
            <span>Audited by Baznas</span>
          </div>
        </div>

      </div>
    </footer>
  );
}
