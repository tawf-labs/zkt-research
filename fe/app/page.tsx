import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Heart, Building2, Scale } from "lucide-react"

import { Hero } from "@/components/landing/hero"
import { HowItWorks } from "@/components/landing/how-it-works"
import { FeaturedCampaigns } from "@/components/landing/featured-campaigns"
import { Trusted } from "@/components/landing/badge"


export default function HomePage() {
  return (
    <main className="min-h-dvh bg-background text-foreground">
      <Hero />
      {/* <Trusted /> */}

      {/* Role-based entry section - updated spacing per guidelines */}
      <section className="py-16 md:py-24 px-4 sm:px-6 bg-gradient-to-b from-secondary/5 to-transparent">
        <div className="max-w-6xl mx-auto">
          {/* Updated H2 size per guidelines: 40px/36px */}
          <h2 className="font-serif text-[36px] md:text-[40px] font-bold text-center mb-4 text-foreground">
            Pilih Peran Anda
          </h2>
          <p className="text-center text-muted-foreground mb-12 max-w-xl mx-auto">
            Choose your role and start making a difference today
          </p>
          <div className="grid md:grid-cols-3 gap-6">
            {/* Donor Card */}
            <Card className="hover:shadow-lg transition-shadow border-primary/10 rounded-2xl group">
              <CardHeader className="p-6 pb-4">
                <Heart className="h-8 w-8 text-primary mb-3 group-hover:scale-110 transition-transform" />
                <CardTitle className="font-serif">Donatur</CardTitle>
                <CardDescription>
                  Dukung donasi, terima NFT bukti, dan partisipasi dalam tata kelola
                </CardDescription>
              </CardHeader>
              <CardContent className="p-6 pt-0">
                <Link href="/campaigns">
                  <Button className="w-full rounded-full uppercase tracking-wide-label">Mulai Berdonasi</Button>
                </Link>
              </CardContent>
            </Card>

            {/* Organization Card */}
            <Card className="hover:shadow-lg transition-shadow border-primary/10 rounded-2xl group">
              <CardHeader className="p-6 pb-4">
                <Building2 className="h-8 w-8 text-secondary mb-3 group-hover:scale-110 transition-transform" />
                <CardTitle className="font-serif">Organisasi</CardTitle>
                <CardDescription>
                  Buat kampanye Zakat, kumpulkan dana, dan verifikasi oleh Dewan Syariah
                </CardDescription>
              </CardHeader>
              <CardContent className="p-6 pt-0">
                <Link href="/organizer">
                  <Button className="w-full rounded-full uppercase tracking-wide-label" variant="outline">
                    Mulai Organisasi
                  </Button>
                </Link>
              </CardContent>
            </Card>

            {/* Governance Card */}
            <Card className="hover:shadow-lg transition-shadow border-primary/10 rounded-2xl group">
              <CardHeader className="p-6 pb-4">
                <Scale className="h-8 w-8 text-primary mb-3 group-hover:scale-110 transition-transform" />
                <CardTitle className="font-serif">Governance</CardTitle>
                <CardDescription>
                  Partisipasi dalam Community DAO dan Dewan Syariah untuk verifikasi proposal
                </CardDescription>
              </CardHeader>
              <CardContent className="p-6 pt-0">
                <Link href="/governance">
                  <Button className="w-full rounded-full uppercase tracking-wide-label" variant="secondary">
                    Governance
                  </Button>
                </Link>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      <FeaturedCampaigns />
      <HowItWorks />
      <section id="campaigns" className="py-12 lg:py-16">
        <div className="container mx-auto px-6">
          {/* <div className="mb-6 flex items-center justify-between">
            <h2 className="text-2xl font-semibold tracking-tight text-pretty">Featured Campaigns</h2>
            <Button asChild variant="default" className="bg-primary text-primary-foreground hover:opacity-90">
              <Link href="#campaigns">{"Explore more"}</Link>
            </Button>
          </div>
        */}
        </div>
      </section>
    </main>
  )
}
