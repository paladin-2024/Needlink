import { useEffect, useState, useRef } from 'react'
import { Link } from 'react-router-dom'
import {
  Heart, Package, CheckCircle2, Users, ArrowRight, Smartphone,
  MapPin, Shield, Star, ChevronDown, BarChart3, ClipboardList,
  Zap, BadgeCheck, TrendingUp, Menu, X, Globe,
} from 'lucide-react'
import { z } from 'zod'
import { supabase } from '../lib/supabase'
import { NeedSchema, PledgeQuantitySchema } from '../lib/schemas'
import NeedLinkLogo from '../components/NeedLinkLogo'

/* ── Hooks ────────────────────────────────────────────────── */

function useAnimatedCount(target: number, active: boolean, duration = 1800) {
  const [count, setCount] = useState(0)
  const raf = useRef<number>(0)
  useEffect(() => {
    if (!active || !target) return
    const t0 = performance.now()
    const run = (now: number) => {
      const p = Math.min((now - t0) / duration, 1)
      setCount(Math.round((1 - Math.pow(1 - p, 3)) * target))
      if (p < 1) raf.current = requestAnimationFrame(run)
    }
    raf.current = requestAnimationFrame(run)
    return () => cancelAnimationError(raf.current)
  }, [target, active, duration])
  return count
}

function cancelAnimationError(id: number) {
  cancelAnimationFrame(id)
}

function useInView(threshold = 0.15) {
  const ref = useRef<HTMLDivElement>(null)
  const [inView, setInView] = useState(false)
  useEffect(() => {
    const el = ref.current; if (!el) return
    const obs = new IntersectionObserver(
      ([e]) => { if (e.isIntersecting) { setInView(true); obs.disconnect() } },
      { threshold }
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [threshold])
  return { ref, inView }
}

function useScrollY() {
  const [y, setY] = useState(0)
  useEffect(() => {
    const h = () => setY(window.scrollY)
    window.addEventListener('scroll', h, { passive: true })
    return () => window.removeEventListener('scroll', h)
  }, [])
  return y
}

function useScrollProgress() {
  const [pct, setPct] = useState(0)
  useEffect(() => {
    const h = () => {
      const el = document.documentElement
      setPct((window.scrollY / Math.max(el.scrollHeight - el.clientHeight, 1)) * 100)
    }
    window.addEventListener('scroll', h, { passive: true })
    return () => window.removeEventListener('scroll', h)
  }, [])
  return pct
}

/* ── Reveal ───────────────────────────────────────────────── */

function Reveal({
  children, delay = 0, className = '', style: outerStyle,
}: {
  children: React.ReactNode
  delay?: number
  className?: string
  style?: React.CSSProperties
}) {
  const { ref, inView } = useInView(0.1)
  return (
    <div ref={ref} className={className} style={{
      ...outerStyle,
      opacity: inView ? 1 : 0,
      transform: inView ? 'none' : 'translateY(24px)',
      transition: `opacity 0.62s ease ${delay}s, transform 0.62s ease ${delay}s`,
    }}>
      {children}
    </div>
  )
}

/* ── FAQ ──────────────────────────────────────────────────── */

function FaqItem({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false)
  return (
    <div className="border-b border-[#E0EEF6] last:border-0">
      <button
        onClick={() => setOpen(o => !o)}
        aria-expanded={open}
        className="w-full flex items-center justify-between gap-4 py-5 text-left cursor-pointer group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#0891B2] rounded-lg"
      >
        <span className="font-mono font-semibold text-[#164E63] text-sm leading-snug group-hover:text-[#0891B2] transition-colors">{q}</span>
        <ChevronDown size={18} className={`text-[#94A3B8] shrink-0 transition-transform duration-200 ${open ? 'rotate-180' : ''}`} />
      </button>
      <div style={{ maxHeight: open ? 220 : 0, overflow: 'hidden', transition: 'max-height 0.32s cubic-bezier(0.4,0,0.2,1)' }}>
        <p className="text-sm text-[#64748B] leading-relaxed pb-5 font-light">{a}</p>
      </div>
    </div>
  )
}

/* ── Mini Need Card ───────────────────────────────────────── */

type Need = z.infer<typeof NeedSchema>

const catStyles: Record<string, string> = {
  food: 'bg-orange-100 text-orange-700',
  clothing: 'bg-purple-100 text-purple-700',
  medicine: 'bg-red-100 text-red-700',
  supplies: 'bg-blue-100 text-blue-700',
}

function MiniNeedCard({ need }: { need: Need }) {
  const pct = Math.min(100, Math.round((need.quantity_pledged / need.quantity_needed) * 100))
  return (
    <article className="bg-white border border-[#A5F3FC] rounded-2xl p-4 w-[260px] shrink-0 shadow-sm hover:shadow-md hover:border-[#0891B2] transition-all duration-200 cursor-default">
      <div className="flex items-center gap-2 mb-2 flex-wrap">
        <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full capitalize ${catStyles[need.category] ?? 'bg-slate-100 text-slate-700'}`}>{need.category}</span>
        {need.urgency === 'urgent' && (
          <span className="text-[11px] font-semibold px-2 py-0.5 rounded bg-red-500 text-white flex items-center gap-1">
            <Zap size={9} aria-hidden="true" />Urgent
          </span>
        )}
      </div>
      <p className="font-mono font-semibold text-[#164E63] text-sm mb-1 truncate">{need.item_name}</p>
      {need.ngo && (
        <p className="text-xs text-[#64748B] mb-3 flex items-center gap-1 truncate">
          <MapPin size={10} aria-hidden="true" />{need.ngo.name}
        </p>
      )}
      <div className="space-y-1">
        <div className="flex justify-between text-[11px] text-[#94A3B8]">
          <span>{need.quantity_pledged} / {need.quantity_needed} units</span>
          <span>{pct}%</span>
        </div>
        <div className="h-1.5 bg-[#E8F1F6] rounded-full overflow-hidden">
          <div className="h-full rounded-full" style={{ width: `${pct}%`, background: pct >= 100 ? '#16A34A' : 'linear-gradient(90deg,#0891B2,#22D3EE)', transition: 'width 0.5s ease' }} />
        </div>
      </div>
    </article>
  )
}

/* ── Phone Mockup ─────────────────────────────────────────── */

function PhoneMockup({ screen }: { screen: 'browse' | 'pledges' }) {
  return (
    <div className="phone-frame" aria-hidden="true">
      <div className="phone-status">
        <span>9:41</span><span style={{ letterSpacing: 2 }}>▌■●●●</span>
      </div>
      <div className="phone-header">
        <Heart size={13} color="#EA580C" fill="#EA580C" />
        <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 11, color: 'white' }}>
          {screen === 'browse' ? 'NeedLink' : 'My Pledges'}
        </span>
      </div>
      <div className="phone-body">
        {screen === 'browse' ? (
          <>
            <p style={{ fontSize: 9, color: 'rgba(255,255,255,0.38)', fontFamily: 'var(--font-mono)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 8 }}>Open Needs · 23</p>
            {[
              { label: 'School Meals', sub: 'Namirembe NGO', pct: 72 },
              { label: 'Blankets (×50)', sub: 'Reach Uganda', pct: 35 },
              { label: 'Paracetamol', sub: 'Health First', pct: 90 },
            ].map(c => (
              <div key={c.label} style={{ background: 'rgba(255,255,255,0.06)', borderRadius: 10, padding: '9px 10px', border: '1px solid rgba(165,243,252,0.1)', marginBottom: 7 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.85)', fontWeight: 600 }}>{c.label}</span>
                  <span style={{ fontSize: 9, color: 'rgba(255,255,255,0.38)', fontFamily: 'var(--font-mono)' }}>{c.pct}%</span>
                </div>
                <div style={{ fontSize: 9, color: 'rgba(255,255,255,0.32)', marginBottom: 5 }}>{c.sub}</div>
                <div style={{ height: 3, background: 'rgba(255,255,255,0.08)', borderRadius: 2, overflow: 'hidden' }}>
                  <div style={{ height: '100%', width: `${c.pct}%`, background: 'linear-gradient(90deg,#0891B2,#22D3EE)', borderRadius: 2 }} />
                </div>
              </div>
            ))}
          </>
        ) : (
          <>
            <p style={{ fontSize: 9, color: 'rgba(255,255,255,0.38)', fontFamily: 'var(--font-mono)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 8 }}>My Pledges · 3</p>
            {[
              { label: 'School Meals', status: 'Confirmed', color: '#22C55E' },
              { label: 'Blankets ×12', status: 'Pending', color: '#F59E0B' },
              { label: 'Paracetamol', status: 'In transit', color: '#22D3EE' },
            ].map(p => (
              <div key={p.label} style={{ background: 'rgba(255,255,255,0.06)', borderRadius: 10, padding: '9px 10px', border: '1px solid rgba(165,243,252,0.1)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 7 }}>
                <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.8)', fontWeight: 600 }}>{p.label}</span>
                <span style={{ fontSize: 9, color: p.color, fontFamily: 'var(--font-mono)', fontWeight: 700 }}>{p.status}</span>
              </div>
            ))}
            <div style={{ marginTop: 10, textAlign: 'center' }}>
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: '#EA580C', borderRadius: 8, padding: '6px 12px' }}>
                <span style={{ color: 'white', fontSize: 10, fontFamily: 'var(--font-mono)', fontWeight: 700 }}>+ New Pledge</span>
              </div>
            </div>
          </>
        )}
      </div>
      <div className="phone-nav">
        {([Package, ClipboardList, BarChart3] as const).map((Icon, i) => {
          const active = screen === 'browse' ? i === 0 : i === 1
          return (
            <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
              <Icon size={15} color={active ? '#22D3EE' : 'rgba(255,255,255,0.28)'} />
              <div style={{ height: 2, width: 14, borderRadius: 1, background: active ? '#22D3EE' : 'transparent' }} />
            </div>
          )
        })}
      </div>
    </div>
  )
}

/* ── OS detection ─────────────────────────────────────────── */
const isIOS = typeof navigator !== 'undefined' && /iPhone|iPad|iPod/i.test(navigator.userAgent)
const isAndroid = typeof navigator !== 'undefined' && /Android/i.test(navigator.userAgent)

/* ── Data ─────────────────────────────────────────────────── */

interface Stats { items: number; ngos: number; donors: number; deliveries: number }

const FAQS = [
  { q: 'What kinds of items can be donated?', a: 'NeedLink handles in-kind (physical item) donations only — no cash. Categories include food staples, clothing and bedding, medicine and hygiene products, and general supplies like school materials, furniture, and tools.' },
  { q: 'How do I know my donation reaches the NGO?', a: 'Every pledge is tracked end-to-end. You set a delivery date, the NGO confirms receipt, and you receive a notification. Your pledge history shows the real-time status of every item you have ever donated.' },
  { q: 'Can I donate money instead of items?', a: 'No — NeedLink is intentionally cash-free. This eliminates misuse risk and ensures every donation is a specific, trackable physical item that the NGO has explicitly requested and needs.' },
  { q: 'Is NeedLink free to use?', a: 'Yes — completely free for both donors and NGOs. NeedLink is a public-good platform with no fees, subscriptions, or commissions of any kind.' },
  { q: 'How do NGOs get verified?', a: 'NGOs register with their official registration number and contact details. The platform team reviews each application before granting full access. Verified NGOs display a blue verification badge on their profile and all their posted needs.' },
]

/* ── Landing ──────────────────────────────────────────────── */

export default function Landing() {
  const scrollY = useScrollY()
  const scrollPct = useScrollProgress()
  const [mobileOpen, setMobileOpen] = useState(false)
  const [stats, setStats] = useState<Stats>({ items: 0, ngos: 0, donors: 0, deliveries: 0 })
  const [openNeeds, setOpenNeeds] = useState<Need[]>([])
  const statsSection = useInView(0.3)
  const featuresSection = useInView(0.15)

  const cItems = useAnimatedCount(stats.items, statsSection.inView, 2000)
  const cNgos = useAnimatedCount(stats.ngos, statsSection.inView, 1500)
  const cDonors = useAnimatedCount(stats.donors, statsSection.inView, 1800)
  const cDel = useAnimatedCount(stats.deliveries, statsSection.inView, 1600)

  useEffect(() => {
    Promise.all([
      supabase.from('pledges').select('quantity').eq('status', 'confirmed'),
      supabase.from('ngos').select('id', { count: 'exact', head: true }),
      supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'donor'),
      supabase.from('pledges').select('id', { count: 'exact', head: true }).eq('status', 'confirmed'),
      supabase.from('donation_needs')
        .select('id,item_name,category,quantity_needed,quantity_pledged,urgency,ngo:ngos(name,location)')
        .eq('status', 'open').limit(14),
    ]).then(([p, n, d, del, needs]) => {
      const pledges = z.array(PledgeQuantitySchema).safeParse(p.data ?? [])
      const items = pledges.success
        ? pledges.data.reduce((a, x) => a + (x.quantity ?? 0), 0)
        : 0
      setStats({ items, ngos: n.count ?? 0, donors: d.count ?? 0, deliveries: del.count ?? 0 })

      const parsed = z.array(NeedSchema).safeParse(needs.data ?? [])
      setOpenNeeds(parsed.success ? parsed.data : [])
    })
  }, [])

  return (
    <>
      <style>{`
        html { scroll-behavior: smooth; }

        /* Skip link */
        .nl-skip { position:absolute; left:-9999px; top:4px; z-index:9999; padding:12px 20px; background:#0891B2; color:#fff; font-weight:600; border-radius:0 0 8px 0; font-size:14px; text-decoration:none; }
        .nl-skip:focus { left:4px; }

        /* Scroll progress bar */
        .nl-progress { position:fixed; top:0; left:0; height:2px; z-index:9998; pointer-events:none;
          background:linear-gradient(90deg,#0891B2,#22D3EE,#EA580C); transition:width 0.15s linear; }

        /* Dot grid */
        .nl-dotgrid { position:fixed; inset:0; pointer-events:none; z-index:0;
          background-image:radial-gradient(circle,rgba(34,211,238,0.055) 1px,transparent 1px);
          background-size:28px 28px; }

        /* Hero line entrance */
        @keyframes nl-up { from { opacity:0; transform:translateY(28px); } to { opacity:1; transform:translateY(0); } }
        .hl1 { animation:nl-up 0.72s cubic-bezier(0.16,1,0.3,1) 0.08s both; }
        .hl2 { animation:nl-up 0.72s cubic-bezier(0.16,1,0.3,1) 0.22s both; }
        .hl3 { animation:nl-up 0.72s cubic-bezier(0.16,1,0.3,1) 0.36s both; }
        .hl4 { animation:nl-up 0.65s cubic-bezier(0.16,1,0.3,1) 0.52s both; }
        .hl5 { animation:nl-up 0.6s cubic-bezier(0.16,1,0.3,1) 0.65s both; }
        .hl6 { animation:nl-up 0.55s cubic-bezier(0.16,1,0.3,1) 0.78s both; }

        /* Phone glow */
        @keyframes nl-glow {
          0%,100% { box-shadow:0 0 55px 15px rgba(8,145,178,0.16),0 40px 80px rgba(0,0,0,0.55),0 0 0 1px rgba(34,211,238,0.14),inset 0 0 0 1px rgba(255,255,255,0.04); }
          50%      { box-shadow:0 0 80px 28px rgba(8,145,178,0.26),0 40px 80px rgba(0,0,0,0.55),0 0 0 1px rgba(34,211,238,0.24),inset 0 0 0 1px rgba(255,255,255,0.06); }
        }
        .phone-frame { width:232px; height:460px; border-radius:34px; background:#0C3344;
          border:7px solid rgba(34,211,238,0.32); position:relative; overflow:hidden;
          animation:nl-glow 4.5s ease-in-out infinite; display:flex; flex-direction:column; }
        .phone-status { height:26px; background:#071D2C; display:flex; align-items:center; justify-content:space-between; padding:0 14px; font-size:9px; color:rgba(255,255,255,0.55); font-family:var(--font-mono); flex-shrink:0; }
        .phone-header { height:40px; background:#164E63; display:flex; align-items:center; padding:0 12px; gap:7px; flex-shrink:0; border-bottom:1px solid rgba(34,211,238,0.12); }
        .phone-body { flex:1; overflow:hidden; padding:10px 10px 6px; display:flex; flex-direction:column; }
        .phone-nav { height:50px; background:#071D2C; display:flex; align-items:center; justify-content:space-around; border-top:1px solid rgba(34,211,238,0.1); flex-shrink:0; }

        /* Pulse dot */
        @keyframes nl-pulse { 0%,100%{opacity:1;transform:scale(1)} 50%{opacity:0.35;transform:scale(0.75)} }
        .nl-dot { animation:nl-pulse 2s ease-in-out infinite; }

        /* Float for notification badges */
        @keyframes nl-f1 { 0%,100%{transform:translateY(0) rotate(-3deg)} 50%{transform:translateY(-9px) rotate(-3deg)} }
        @keyframes nl-f2 { 0%,100%{transform:translateY(0) rotate(2.5deg)} 50%{transform:translateY(-7px) rotate(2.5deg)} }
        .nl-float1 { animation:nl-f1 4.2s ease-in-out infinite; }
        .nl-float2 { animation:nl-f2 3.6s ease-in-out 0.5s infinite; }

        /* Ticker */
        .ticker-wrap { overflow:hidden; }
        .ticker-track { display:flex; width:max-content; animation:nl-ticker 44s linear infinite; }
        .ticker-wrap:hover .ticker-track { animation-play-state:paused; }
        @keyframes nl-ticker { from{transform:translateX(0)} to{transform:translateX(-50%)} }

        /* Feature hover */
        .feat-card { transition:transform 0.28s cubic-bezier(0.16,1,0.3,1), box-shadow 0.28s ease; }
        .feat-card:hover { transform:translateY(-5px); box-shadow:0 24px 56px rgba(22,78,99,0.1); }

        /* Bento grid */
        .bento { display:grid; grid-template-columns:repeat(6,1fr); gap:12px; }
        @media (max-width:1024px) {
          .bento { grid-template-columns:repeat(2,1fr); }
          .bn-4 { grid-column:span 2 !important; }
          .bn-2 { grid-column:span 1 !important; }
        }
        @media (max-width:640px) {
          .bento { grid-template-columns:1fr; }
          .bn-4,.bn-2 { grid-column:span 1 !important; }
        }

        /* Bento animated progress bars */
        @keyframes bp1 { from{width:0} to{width:72%} }
        @keyframes bp2 { from{width:0} to{width:38%} }
        @keyframes bp3 { from{width:0} to{width:91%} }
        .bp1 { animation:bp1 1.6s cubic-bezier(0.16,1,0.3,1) 0.2s both; animation-play-state:var(--bp,paused); }
        .bp2 { animation:bp2 1.6s cubic-bezier(0.16,1,0.3,1) 0.4s both; animation-play-state:var(--bp,paused); }
        .bp3 { animation:bp3 1.6s cubic-bezier(0.16,1,0.3,1) 0.6s both; animation-play-state:var(--bp,paused); }

        /* Download buttons */
        .dl-btn { display:flex; align-items:center; gap:12px; padding:13px 20px; border-radius:14px; text-decoration:none; min-width:170px; cursor:pointer; transition:transform 0.22s ease, box-shadow 0.22s ease; }
        .dl-btn:hover { transform:translateY(-3px); box-shadow:0 14px 36px rgba(0,0,0,0.32); }
        .dl-btn:focus-visible { outline:3px solid #22D3EE; outline-offset:3px; }
        .dl-solid { background:white; }
        .dl-outline { background:rgba(255,255,255,0.08); border:1px solid rgba(255,255,255,0.22); }

        /* Live needs scroll */
        .needs-scroll { overflow-x:auto; scrollbar-width:none; -webkit-overflow-scrolling:touch; }
        .needs-scroll::-webkit-scrollbar { display:none; }

        /* Pull quote rule */
        .pq-rule { display:block; width:48px; height:2px; background:#EA580C; margin:0 auto 24px; }

        @media (prefers-reduced-motion:reduce) {
          .nl-dot,.nl-float1,.nl-float2,.phone-frame,.ticker-track { animation:none !important; }
          .hl1,.hl2,.hl3,.hl4,.hl5,.hl6 { animation:none !important; opacity:1 !important; transform:none !important; }
          * { transition-duration:0.01ms !important; }
        }
      `}</style>

      {/* Scroll progress */}
      <div className="nl-progress" style={{ width: `${scrollPct}%` }} aria-hidden="true" />

      {/* Dot grid */}
      <div className="nl-dotgrid" aria-hidden="true" />

      <a href="#main-content" className="nl-skip">Skip to main content</a>

      {/* ── NAV ─────────────────────────────────────────────── */}
      <nav
        role="navigation"
        aria-label="Main navigation"
        className="fixed top-0 left-0 right-0 z-50 transition-all duration-300"
        style={{
          background: scrollY > 60 ? 'rgba(22,78,99,0.96)' : 'transparent',
          backdropFilter: scrollY > 60 ? 'blur(20px)' : 'none',
          borderBottom: scrollY > 60 ? '1px solid rgba(255,255,255,0.06)' : 'none',
        }}
      >
        <div className="max-w-[1120px] mx-auto px-6 flex items-center justify-between h-[60px]">
          <Link to="/" aria-label="NeedLink — go to homepage" className="flex items-center gap-2.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#22D3EE] rounded-lg p-1">
            <NeedLinkLogo size={32} />
            <span className="font-mono font-bold text-lg text-white tracking-tight">NeedLink</span>
          </Link>

          <div className="hidden md:flex items-center gap-1">
            {[{ href: '#how-it-works', l: 'How it works' }, { href: '#features', l: 'Features' }, { href: '#download', l: 'Download' }].map(({ href, l }) => (
              <a key={href} href={href} className="text-[13px] text-white/55 hover:text-white px-3 py-2 rounded-lg hover:bg-white/8 transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#22D3EE]">{l}</a>
            ))}
          </div>

          <div className="hidden md:flex items-center gap-3">
            <Link to="/login" className="text-[13px] text-white/55 hover:text-white transition-colors px-3 py-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#22D3EE] rounded-lg">Sign in</Link>
            <Link to="/register" className="font-mono text-[13px] font-semibold text-[#164E63] bg-[#22D3EE] hover:bg-white px-4 py-2 rounded-lg transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white">Get started</Link>
          </div>

          <button
            className="md:hidden p-2 text-white rounded-lg hover:bg-white/10 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#22D3EE]"
            onClick={() => setMobileOpen(o => !o)}
            aria-expanded={mobileOpen}
            aria-label={mobileOpen ? 'Close menu' : 'Open menu'}
          >
            {mobileOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>

        {mobileOpen && (
          <div className="md:hidden bg-[#164E63] border-t border-white/10 px-6 py-4">
            <div className="flex flex-col gap-1 mb-4">
              {[{ href: '#how-it-works', l: 'How it works' }, { href: '#features', l: 'Features' }, { href: '#download', l: 'Download' }].map(({ href, l }) => (
                <a key={href} href={href} onClick={() => setMobileOpen(false)} className="text-white/65 hover:text-white py-3 px-2 text-sm border-b border-white/8 last:border-0 transition-colors">{l}</a>
              ))}
            </div>
            <div className="flex gap-3">
              <Link to="/login" onClick={() => setMobileOpen(false)} className="flex-1 text-center py-3 text-sm text-white border border-white/18 rounded-xl hover:bg-white/8 transition-colors">Sign in</Link>
              <Link to="/register" onClick={() => setMobileOpen(false)} className="flex-1 text-center py-3 text-sm font-semibold font-mono text-[#164E63] bg-[#22D3EE] rounded-xl hover:bg-white transition-colors">Get started</Link>
            </div>
          </div>
        )}
      </nav>

      <main id="main-content">

        {/* ── HERO ────────────────────────────────────────────── */}
        <section
          className="relative overflow-hidden flex items-center min-h-dvh pt-[60px]"
          style={{ background: 'linear-gradient(150deg,#164E63 0%,#0C3344 55%,#071D2C 100%)' }}
        >
          {/* Radial glows */}
          <div aria-hidden className="absolute -top-56 -right-40 w-[640px] h-[640px] rounded-full pointer-events-none" style={{ background: 'radial-gradient(circle,rgba(8,145,178,0.16) 0%,transparent 68%)' }} />
          <div aria-hidden className="absolute -bottom-32 -left-24 w-[440px] h-[440px] rounded-full pointer-events-none" style={{ background: 'radial-gradient(circle,rgba(234,88,12,0.10) 0%,transparent 68%)' }} />

          <div className="max-w-[1120px] mx-auto px-6 py-20 w-full relative z-10">
            <div className="flex flex-col lg:flex-row items-start lg:items-center gap-12 lg:gap-8">

              {/* Headlines */}
              <div className="flex-1 min-w-0">
                <div className="hl1 inline-flex items-center gap-2 mb-8 px-4 py-2 rounded-full" style={{ background: 'rgba(8,145,178,0.14)', border: '1px solid rgba(34,211,238,0.2)' }}>
                  <span className="nl-dot w-1.5 h-1.5 rounded-full bg-[#22D3EE] inline-block shrink-0" />
                  <span className="font-mono text-[11px] text-[#22D3EE] tracking-[0.1em] uppercase">Live · Kampala, Uganda</span>
                </div>

                <h1
                  className="font-mono font-bold text-white leading-[0.94] tracking-[-0.04em] mb-8"
                  style={{ fontSize: 'clamp(3.2rem,9vw,8rem)' }}
                >
                  <span className="block hl2">When NGOs</span>
                  <span className="block hl3 text-[#22D3EE]">need things,</span>
                  <span className="block hl4" style={{ color: 'rgba(255,255,255,0.24)', fontWeight: 300 }}>not money.</span>
                </h1>

                <p className="hl5 text-white/45 leading-[1.85] mb-10 font-light" style={{ fontSize: 'clamp(0.95rem,1.5vw,1.1rem)', maxWidth: 460 }}>
                  NeedLink connects Ugandan NGOs with donors who give physical items: food, clothing, medicine, school supplies. Precise, traceable, completely free.
                </p>

                <div className="hl5 flex flex-wrap gap-3 mb-10">
                  <Link
                    to="/register"
                    className="inline-flex items-center gap-2 px-7 font-semibold text-white bg-[#EA580C] hover:bg-[#C2410C] rounded-xl transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#EA580C] focus-visible:ring-offset-2 focus-visible:ring-offset-[#164E63]"
                    style={{ fontSize: 15, height: 50 }}
                  >
                    Start donating <ArrowRight size={16} />
                  </Link>
                  <a
                    href="#download"
                    className="inline-flex items-center gap-2 px-7 font-medium text-white rounded-xl transition-all duration-200 hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/40"
                    style={{ fontSize: 15, height: 50, background: 'rgba(255,255,255,0.07)', border: '1px solid rgba(255,255,255,0.14)' }}
                  >
                    <Smartphone size={16} /> Get the app
                  </a>
                </div>

                <div className="hl6 flex flex-wrap gap-6">
                  {[
                    { icon: <Shield size={12} />, label: 'Verified NGOs only' },
                    { icon: <Globe size={12} />, label: 'Uganda-wide' },
                    { icon: <BadgeCheck size={12} />, label: 'Free forever' },
                  ].map(t => (
                    <div key={t.label} className="flex items-center gap-1.5 text-white/32 text-xs font-light">
                      <span className="text-[#22D3EE]/55">{t.icon}</span> {t.label}
                    </div>
                  ))}
                </div>
              </div>

              {/* Phone */}
              <div className="hidden lg:flex items-center justify-center relative shrink-0">
                <div className="absolute -left-14 top-6 z-10 bg-white rounded-2xl shadow-2xl px-3.5 py-2.5 flex items-center gap-2.5 nl-float1">
                  <CheckCircle2 size={15} className="text-green-500 shrink-0" />
                  <span className="text-[11px] font-semibold text-[#164E63] whitespace-nowrap">Delivery confirmed</span>
                </div>
                <div className="absolute -right-12 bottom-10 z-10 bg-white rounded-2xl shadow-2xl px-3.5 py-2.5 flex items-center gap-2.5 nl-float2">
                  <Zap size={13} className="text-[#EA580C] shrink-0" />
                  <span className="text-[11px] font-semibold text-[#164E63] whitespace-nowrap">Need fully matched!</span>
                </div>
                <PhoneMockup screen="browse" />
              </div>
            </div>
          </div>
        </section>

        {/* ── STATS STRIP ─────────────────────────────────────── */}
        <section
          ref={statsSection.ref}
          aria-label="Platform statistics"
          style={{ background: '#071D2C', borderTop: '1px solid rgba(34,211,238,0.07)' }}
        >
          <div className="max-w-[1120px] mx-auto px-6 py-12">
            <div className="flex items-center gap-2.5 mb-8">
              <span className="nl-dot w-1.5 h-1.5 rounded-full bg-[#22D3EE] shrink-0" />
              <span className="font-mono text-[10px] text-[#22D3EE]/45 tracking-[0.16em] uppercase">Live platform data</span>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4">
              {[
                { val: cItems, suffix: '+', label: 'Items donated' },
                { val: cNgos,  suffix: '',  label: 'NGOs registered' },
                { val: cDonors, suffix: '', label: 'Active donors' },
                { val: cDel,   suffix: '',  label: 'Deliveries confirmed' },
              ].map((s, i) => (
                <div key={i} className="relative pr-8 pb-6 md:pb-0">
                  {i > 0 && (
                    <div
                      className="hidden md:block absolute left-0 top-0 bottom-0 w-px"
                      style={{ background: 'rgba(34,211,238,0.07)' }}
                      aria-hidden="true"
                    />
                  )}
                  <div
                    className="font-mono font-bold text-white leading-none mb-2 tabular-nums"
                    style={{ fontSize: 'clamp(2.4rem,4.5vw,3.8rem)' }}
                  >
                    {s.val.toLocaleString()}{s.suffix}
                  </div>
                  <div className="text-xs font-light" style={{ color: 'rgba(255,255,255,0.32)' }}>{s.label}</div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── TICKER ──────────────────────────────────────────── */}
        {openNeeds.length > 0 && (
          <div
            className="bg-[#EA580C] ticker-wrap"
            aria-label="Live open donation needs"
            aria-live="off"
            style={{ borderTop: '2px solid rgba(0,0,0,0.08)' }}
          >
            <div className="ticker-track py-3">
              {[...openNeeds, ...openNeeds].map((n, i) => (
                <span key={i} className="inline-flex items-center gap-2.5 px-8 font-mono text-[11px] text-white whitespace-nowrap">
                  <span className="nl-dot w-1.5 h-1.5 rounded-full bg-white/55 shrink-0" />
                  <span className="font-semibold">{n.item_name}</span>
                  {n.ngo?.name && <span className="opacity-55 font-normal">— {n.ngo.name}</span>}
                  <span className="opacity-22 mx-2" aria-hidden="true">◆</span>
                </span>
              ))}
            </div>
          </div>
        )}

        {/* ── PROBLEM ─────────────────────────────────────────── */}
        <section className="py-24 px-6 bg-white">
          <div className="max-w-[1120px] mx-auto">
            <Reveal className="mb-14">
              <p className="font-mono text-[11px] tracking-[0.12em] text-[#0891B2] uppercase mb-4">The problem</p>
              <h2
                className="font-mono font-bold text-[#164E63] tracking-tight leading-tight"
                style={{ fontSize: 'clamp(1.8rem,4vw,3.2rem)', maxWidth: 640 }}
              >
                Donations break down without coordination.
              </h2>
            </Reveal>

            <div>
              {[
                { n: '01', title: 'Wrong items', desc: 'NGOs receive whatever donors feel like giving: often duplicates, wrong sizes, or items they cannot use. The need goes unmet while storage fills with things no one asked for.' },
                { n: '02', title: 'No tracking', desc: 'Once a donation leaves your hands, it disappears. No confirmation, no receipt, no accountability. You never know if your generosity made any difference at all.' },
                { n: '03', title: 'No coordination', desc: 'Multiple donors bring the same item while other critical needs go unfilled for weeks. Without a shared view, everyone guesses — and the gaps stay open.' },
              ].map((p, i) => (
                <Reveal key={p.n} delay={i * 0.1}>
                  <div
                    className="grid items-start py-10 border-b border-[#F0F6FA] last:border-0"
                    style={{ gridTemplateColumns: 'clamp(72px,10vw,112px) 1fr', gap: 'clamp(20px,4vw,48px)' }}
                  >
                    <div
                      className="font-mono font-bold text-[#F0F6FA] select-none leading-none pt-1"
                      style={{ fontSize: 'clamp(3.5rem,7vw,5.5rem)' }}
                      aria-hidden="true"
                    >
                      {p.n}
                    </div>
                    <div>
                      <h3 className="font-mono font-bold text-[#164E63] mb-3" style={{ fontSize: 'clamp(1.1rem,2vw,1.5rem)' }}>{p.title}</h3>
                      <p className="text-[#64748B] font-light leading-[1.85] text-sm" style={{ maxWidth: 560 }}>{p.desc}</p>
                    </div>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        {/* ── HOW IT WORKS ────────────────────────────────────── */}
        <section id="how-it-works" className="py-24 px-6" style={{ background: '#FAFCFE' }}>
          <div className="max-w-[1120px] mx-auto">
            <Reveal className="mb-14">
              <p className="font-mono text-[11px] tracking-[0.12em] text-[#0891B2] uppercase mb-4">Simple by design</p>
              <h2 className="font-mono font-bold text-[#164E63] tracking-tight" style={{ fontSize: 'clamp(1.8rem,4vw,3rem)' }}>Three steps. Real impact.</h2>
            </Reveal>

            <div className="relative">
              <div
                aria-hidden
                className="hidden md:block absolute top-[22px] h-px"
                style={{ left: 'calc(16.6% + 28px)', right: 'calc(16.6% + 28px)', background: 'linear-gradient(90deg,transparent,rgba(8,145,178,0.25),transparent)' }}
              />
              <div className="grid md:grid-cols-3 gap-10">
                {[
                  { n: '01', icon: <Users size={20} className="text-[#EA580C]" />, bg: 'bg-orange-50', title: 'NGO posts a need', desc: 'A registered NGO specifies exactly what they need: item, quantity, deadline, urgency. Visible to donors in real time.' },
                  { n: '02', icon: <Package size={20} className="text-[#0891B2]" />, bg: 'bg-sky-50', title: 'Donor pledges items', desc: 'Browse open needs, choose what to give, and pledge a specific quantity with a delivery date. The NGO sees who is bringing what.' },
                  { n: '03', icon: <CheckCircle2 size={20} className="text-green-600" />, bg: 'bg-green-50', title: 'Delivery confirmed', desc: 'When items arrive the NGO confirms delivery. You get notified. Every pledge tracked from submission to confirmation.' },
                ].map((s, i) => (
                  <Reveal key={s.n} delay={i * 0.12}>
                    <div className={`w-11 h-11 rounded-xl ${s.bg} flex items-center justify-center mb-5`}>{s.icon}</div>
                    <p className="font-mono text-[10px] tracking-[0.1em] text-[#94A3B8] uppercase mb-2">Step {s.n}</p>
                    <h3 className="font-mono font-bold text-[#164E63] mb-3 text-base">{s.title}</h3>
                    <p className="text-sm text-[#64748B] font-light leading-[1.85]">{s.desc}</p>
                  </Reveal>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ── FEATURES BENTO ──────────────────────────────────── */}
        <section
          id="features"
          ref={featuresSection.ref}
          className="py-24 px-6 bg-white"
          style={{ '--bp': featuresSection.inView ? 'running' : 'paused' } as React.CSSProperties}
        >
          <div className="max-w-[1120px] mx-auto">
            <Reveal className="mb-14">
              <p className="font-mono text-[11px] tracking-[0.12em] text-[#0891B2] uppercase mb-4">Platform features</p>
              <h2 className="font-mono font-bold text-[#164E63] tracking-tight" style={{ fontSize: 'clamp(1.8rem,4vw,3rem)' }}>Built for real-world giving</h2>
            </Reveal>

            <div className="bento">

              {/* Featured: Real-time tracking — 4 cols */}
              <Reveal className="bn-4 feat-card" style={{ gridColumn: 'span 4' }}>
                <div
                  className="rounded-2xl p-7 h-full"
                  style={{ background: '#071D2C', minHeight: 260 }}
                >
                  <div className="flex items-start gap-3 mb-6">
                    <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ background: 'rgba(8,145,178,0.2)' }}>
                      <Zap size={18} className="text-[#22D3EE]" />
                    </div>
                    <div>
                      <p className="font-mono text-[10px] tracking-[0.1em] uppercase mb-1" style={{ color: 'rgba(34,211,238,0.45)' }}>Live</p>
                      <h3 className="font-mono font-bold text-white text-base">Real-time pledge tracking</h3>
                    </div>
                  </div>

                  <div className="space-y-4 mb-4">
                    {[
                      { label: 'School Meals ×200', pct: 72, cls: 'bp1' },
                      { label: 'Blankets ×50', pct: 38, cls: 'bp2' },
                      { label: 'Paracetamol ×300', pct: 91, cls: 'bp3' },
                    ].map(item => (
                      <div key={item.label}>
                        <div className="flex justify-between mb-1.5">
                          <span className="text-xs font-semibold" style={{ color: 'rgba(255,255,255,0.75)' }}>{item.label}</span>
                          <span className="font-mono text-[11px]" style={{ color: 'rgba(255,255,255,0.35)' }}>{item.pct}%</span>
                        </div>
                        <div className="h-2 rounded-full overflow-hidden" style={{ background: 'rgba(255,255,255,0.07)' }}>
                          <div
                            className={`h-full rounded-full ${item.cls}`}
                            style={{ background: item.pct >= 90 ? '#16A34A' : 'linear-gradient(90deg,#0891B2,#22D3EE)' }}
                          />
                        </div>
                      </div>
                    ))}
                  </div>

                  <p className="text-xs font-light" style={{ color: 'rgba(255,255,255,0.3)' }}>
                    Watch the progress bar fill as donors pledge. Both parties see live updates — no manual checking needed.
                  </p>
                </div>
              </Reveal>

              {/* Verified NGOs — 2 cols */}
              <Reveal delay={0.08} className="bn-2 feat-card" style={{ gridColumn: 'span 2' }}>
                <div className="rounded-2xl p-6 h-full" style={{ background: '#ECFEFF', minHeight: 260 }}>
                  <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-5" style={{ background: 'rgba(8,145,178,0.12)' }}>
                    <BadgeCheck size={18} className="text-[#0891B2]" />
                  </div>
                  <h3 className="font-mono font-bold text-[#164E63] mb-2 text-base">Verified NGO badges</h3>
                  <p className="text-sm text-[#64748B] font-light leading-[1.75] mb-5">Every NGO is reviewed by the platform team. Verified NGOs earn a blue badge visible on every need they post.</p>
                  <div className="inline-flex items-center gap-2 px-3 py-2 bg-white rounded-xl" style={{ border: '1px solid rgba(8,145,178,0.15)' }}>
                    <BadgeCheck size={14} className="text-[#0891B2]" />
                    <span className="font-mono text-xs font-semibold text-[#164E63]">Verified NGO</span>
                  </div>
                </div>
              </Reveal>

              {/* Delivery confirmation — 2 cols */}
              <Reveal delay={0.04} className="bn-2 feat-card" style={{ gridColumn: 'span 2' }}>
                <div className="rounded-2xl p-6 h-full" style={{ background: '#F0FDF4', border: '1px solid #DCFCE7' }}>
                  <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center mb-5">
                    <CheckCircle2 size={18} className="text-green-600" />
                  </div>
                  <h3 className="font-mono font-bold text-[#164E63] mb-2 text-base">Delivery confirmation</h3>
                  <p className="text-sm text-[#64748B] font-light leading-[1.75] mb-5">The NGO confirms when items arrive. You get a notification. Full closed-loop accountability from pledge to proof.</p>
                  <div className="space-y-2">
                    {[
                      { step: 'Pledge submitted', done: true },
                      { step: 'NGO matched', done: true },
                      { step: 'Delivered', done: true },
                      { step: 'Confirmed', done: false },
                    ].map(({ step, done }) => (
                      <div key={step} className="flex items-center gap-2">
                        <div className={`w-4.5 h-4.5 rounded-full flex items-center justify-center shrink-0 ${done ? 'bg-green-500' : 'bg-[#E8F1F6]'}`}
                          style={{ width: 18, height: 18 }}>
                          {done && <CheckCircle2 size={10} color="white" />}
                        </div>
                        <span className={`text-xs ${done ? 'text-[#164E63] font-medium' : 'text-[#94A3B8] font-light'}`}>{step}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </Reveal>

              {/* Impact reports — 2 cols */}
              <Reveal delay={0.1} className="bn-2 feat-card" style={{ gridColumn: 'span 2' }}>
                <div className="rounded-2xl p-6 h-full" style={{ border: '1px solid #E0EEF6', background: '#FAFBFF' }}>
                  <div className="w-10 h-10 rounded-xl bg-violet-50 flex items-center justify-center mb-5">
                    <TrendingUp size={18} className="text-violet-600" />
                  </div>
                  <h3 className="font-mono font-bold text-[#164E63] mb-2 text-base">Impact reports</h3>
                  <p className="text-sm text-[#64748B] font-light leading-[1.75] mb-4">NGOs access analytics on match rates, delivery timelines, and category breakdowns to plan better.</p>
                  <div className="flex items-end gap-1.5 h-10">
                    {[38, 55, 48, 72, 65, 88].map((h, i) => (
                      <div key={i} className="flex-1 rounded-t-sm" style={{ height: `${h}%`, background: i === 5 ? '#0891B2' : '#E0EEF6', transition: 'height 0.4s ease' }} />
                    ))}
                  </div>
                </div>
              </Reveal>

              {/* Mobile app — 2 cols */}
              <Reveal delay={0.14} className="bn-2 feat-card" style={{ gridColumn: 'span 2' }}>
                <div className="rounded-2xl p-6 h-full relative overflow-hidden" style={{ background: 'linear-gradient(135deg,#164E63 0%,#0C3344 100%)' }}>
                  <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-5" style={{ background: 'rgba(255,255,255,0.1)' }}>
                    <Smartphone size={18} color="white" />
                  </div>
                  <h3 className="font-mono font-bold text-white mb-2 text-base">Full mobile app</h3>
                  <p className="text-sm font-light leading-[1.75] mb-5" style={{ color: 'rgba(255,255,255,0.5)' }}>iOS and Android apps with the complete feature set. Browse, pledge, and track anywhere in Uganda.</p>
                  <div className="flex gap-2">
                    <span className="font-mono text-[10px] text-[#22D3EE] px-2 py-1 rounded-md" style={{ border: '1px solid rgba(34,211,238,0.28)' }}>iOS</span>
                    <span className="font-mono text-[10px] text-[#22D3EE] px-2 py-1 rounded-md" style={{ border: '1px solid rgba(34,211,238,0.28)' }}>Android</span>
                  </div>
                  <div aria-hidden className="absolute -right-4 -bottom-4 w-28 h-28 rounded-full" style={{ background: 'radial-gradient(circle,rgba(34,211,238,0.1) 0%,transparent 70%)' }} />
                </div>
              </Reveal>

            </div>
          </div>
        </section>

        {/* ── FOR NGOs / FOR DONORS ───────────────────────────── */}
        <section className="py-24 px-6 bg-[#164E63] relative overflow-hidden">
          <div aria-hidden className="absolute top-0 left-0 right-0 h-[2px]" style={{ background: 'linear-gradient(90deg,transparent,rgba(34,211,238,0.35),transparent)' }} />
          <div aria-hidden className="absolute inset-0 pointer-events-none" style={{ backgroundImage: 'radial-gradient(circle at 78% 50%,rgba(234,88,12,0.08) 0%,transparent 52%)' }} />

          <div className="max-w-[1120px] mx-auto relative z-10 grid lg:grid-cols-2 gap-16 lg:gap-20">

            <Reveal>
              <div>
                <div className="inline-flex items-center gap-2 mb-6 px-3 py-1.5 rounded-full" style={{ background: 'rgba(34,211,238,0.1)', border: '1px solid rgba(34,211,238,0.18)' }}>
                  <Users size={11} className="text-[#22D3EE]" aria-hidden="true" />
                  <span className="font-mono text-[11px] text-[#22D3EE] tracking-widest uppercase">For NGOs</span>
                </div>
                <h2 className="font-mono font-bold text-white tracking-tight leading-snug mb-4" style={{ fontSize: 'clamp(1.5rem,2.8vw,2.2rem)' }}>
                  Post what you need.<br />Get exactly that.
                </h2>
                <p className="text-white/45 font-light leading-[1.85] mb-7 text-sm">
                  No more accepting random donations. Specify exact items, quantities and deadlines. Donors pledge specific amounts. You always know what is coming and when.
                </p>
                <ul className="space-y-3.5 mb-8" aria-label="NGO features">
                  {['Real-time pledge tracking dashboard', 'NGO-side delivery confirmation system', 'Impact reports and analytics', 'Instant notifications on new pledges', 'Verified NGO badge on your profile'].map(f => (
                    <li key={f} className="flex items-center gap-3 text-sm text-white/65 font-light">
                      <CheckCircle2 size={14} className="text-[#22D3EE] shrink-0" aria-hidden="true" /> {f}
                    </li>
                  ))}
                </ul>
                <Link
                  to="/register"
                  className="inline-flex items-center gap-2 px-6 font-semibold text-white bg-[#EA580C] hover:bg-[#C2410C] rounded-xl transition-all duration-200 hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#EA580C] focus-visible:ring-offset-2 focus-visible:ring-offset-[#164E63]"
                  style={{ fontSize: 14, height: 44 }}
                >
                  Register your NGO <ArrowRight size={14} />
                </Link>
              </div>
            </Reveal>

            <Reveal delay={0.15}>
              <div className="lg:pl-12" style={{ borderLeft: '1px solid rgba(255,255,255,0.07)' }}>
                <div className="inline-flex items-center gap-2 mb-6 px-3 py-1.5 rounded-full" style={{ background: 'rgba(234,88,12,0.16)', border: '1px solid rgba(234,88,12,0.24)' }}>
                  <Heart size={11} className="text-[#EA580C]" aria-hidden="true" />
                  <span className="font-mono text-[11px] text-[#EA580C] tracking-widest uppercase">For Donors</span>
                </div>
                <h2 className="font-mono font-bold text-white tracking-tight leading-snug mb-4" style={{ fontSize: 'clamp(1.5rem,2.8vw,2.2rem)' }}>
                  Give what's needed.<br />See it land.
                </h2>
                <p className="text-white/45 font-light leading-[1.85] mb-7 text-sm">
                  Browse real needs from verified NGOs. Pledge specific items, set a delivery date, and track your pledge until the NGO confirms receipt.
                </p>
                <ul className="space-y-3.5 mb-8" aria-label="Donor features">
                  {['Browse open needs by category and urgency', 'Pledge specific item quantities', 'Track every pledge status in one view', 'Receive delivery confirmation notification', 'Full history of your donations'].map(f => (
                    <li key={f} className="flex items-center gap-3 text-sm text-white/65 font-light">
                      <CheckCircle2 size={14} className="text-[#EA580C] shrink-0" aria-hidden="true" /> {f}
                    </li>
                  ))}
                </ul>
                <Link
                  to="/register"
                  className="inline-flex items-center gap-2 px-6 font-medium text-white rounded-xl transition-all duration-200 hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/40"
                  style={{ fontSize: 14, height: 44, background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.14)' }}
                >
                  Start donating <ArrowRight size={14} />
                </Link>
              </div>
            </Reveal>
          </div>
        </section>

        {/* ── LIVE NEEDS ──────────────────────────────────────── */}
        {openNeeds.length > 0 && (
          <section className="py-20 bg-white" aria-label="Live open donation needs">
            <div className="max-w-[1120px] mx-auto px-6 mb-8">
              <Reveal className="flex items-end justify-between gap-4 flex-wrap">
                <div>
                  <p className="font-mono text-[11px] tracking-[0.12em] text-[#0891B2] uppercase mb-2">Live platform data</p>
                  <h2 className="font-mono font-bold text-[#164E63] tracking-tight" style={{ fontSize: 'clamp(1.5rem,3vw,2.2rem)' }}>Open needs right now</h2>
                </div>
                <Link
                  to="/register"
                  className="text-sm font-semibold text-[#0891B2] hover:text-[#164E63] transition-colors flex items-center gap-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#0891B2] rounded px-1"
                >
                  Browse all <ArrowRight size={14} />
                </Link>
              </Reveal>
            </div>
            <div className="px-6 needs-scroll flex gap-4 pb-4">
              {openNeeds.map(n => <MiniNeedCard key={n.id} need={n} />)}
            </div>
          </section>
        )}

        {/* ── TESTIMONIALS ────────────────────────────────────── */}
        <section className="py-24 px-6" style={{ background: '#FAFCFE' }}>
          <div className="max-w-[1120px] mx-auto">
            <Reveal className="text-center mb-14">
              <p className="font-mono text-[11px] tracking-[0.12em] text-[#0891B2] uppercase mb-4">From the community</p>
              <h2 className="font-mono font-bold text-[#164E63] tracking-tight" style={{ fontSize: 'clamp(1.8rem,4vw,3rem)' }}>Real people. Real impact.</h2>
            </Reveal>

            {/* Featured pull-quote */}
            <Reveal className="mb-12">
              <figure className="max-w-[800px] mx-auto text-center px-4">
                <span className="pq-rule" aria-hidden="true" />
                <blockquote
                  className="font-mono font-semibold text-[#164E63] tracking-tight leading-snug mb-7"
                  style={{ fontSize: 'clamp(1.15rem,2.4vw,1.65rem)' }}
                >
                  "NeedLink ended the guessing game. We posted a need for 200 school uniforms and had them fully pledged within 4 days — from 8 different donors across Kampala."
                </blockquote>
                <figcaption className="flex items-center justify-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-[#164E63] flex items-center justify-center font-mono font-bold text-white text-sm shrink-0" aria-hidden="true">S</div>
                  <div className="text-left">
                    <p className="font-semibold text-[#164E63] text-sm">Sarah K.</p>
                    <p className="text-xs text-[#64748B] font-light">Program Director, Kampala NGO</p>
                  </div>
                </figcaption>
              </figure>
            </Reveal>

            {/* Secondary quotes */}
            <div className="grid md:grid-cols-2 gap-5">
              {[
                { quote: '"I finally know my donation matters. I pledged blankets, watched the progress bar fill in real time, and received a confirmation the day they arrived at the shelter."', name: 'James M.', role: 'Donor, Entebbe', initial: 'J' },
                { quote: '"The dashboard shows pending pledges, delivery dates, and quantities — everything in one place. We matched 14 needs in our first 3 months on NeedLink."', name: 'Grace O.', role: 'NGO Administrator, Jinja', initial: 'G' },
              ].map((t, i) => (
                <Reveal key={t.name} delay={i * 0.1}>
                  <figure className="bg-white rounded-2xl p-6 h-full" style={{ border: '1px solid #E0EEF6' }}>
                    <div className="flex gap-0.5 mb-4" aria-label="5 out of 5 stars">
                      {[...Array(5)].map((_, j) => <Star key={j} size={13} className="text-[#EA580C] fill-[#EA580C]" aria-hidden="true" />)}
                    </div>
                    <blockquote className="text-[#164E63] text-sm leading-relaxed font-light mb-5 italic">{t.quote}</blockquote>
                    <figcaption className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-[#164E63] flex items-center justify-center font-mono font-bold text-white text-xs shrink-0" aria-hidden="true">{t.initial}</div>
                      <div>
                        <p className="font-semibold text-[#164E63] text-sm">{t.name}</p>
                        <p className="text-xs text-[#64748B] font-light">{t.role}</p>
                      </div>
                    </figcaption>
                  </figure>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        {/* ── DOWNLOAD ────────────────────────────────────────── */}
        <section
          id="download"
          className="py-24 px-6 relative overflow-hidden"
          style={{ background: 'linear-gradient(140deg,#0C3344 0%,#164E63 60%,#0C3344 100%)' }}
        >
          <div aria-hidden className="absolute inset-0 pointer-events-none" style={{ backgroundImage: 'radial-gradient(ellipse at 50% 110%,rgba(234,88,12,0.16) 0%,transparent 58%)' }} />
          <div aria-hidden className="absolute inset-0 pointer-events-none" style={{ backgroundImage: 'linear-gradient(rgba(255,255,255,0.012) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,0.012) 1px,transparent 1px)', backgroundSize: '56px 56px' }} />

          <div className="max-w-[1120px] mx-auto relative z-10 flex flex-col lg:flex-row items-center gap-16">
            <Reveal className="flex-1 text-center lg:text-left">
              <div className="w-14 h-14 rounded-2xl bg-[#EA580C] flex items-center justify-center mb-6 mx-auto lg:mx-0">
                <Smartphone size={24} color="white" aria-hidden="true" />
              </div>
              <h2 className="font-mono font-bold text-white tracking-tight mb-4 leading-snug" style={{ fontSize: 'clamp(1.8rem,3.5vw,2.8rem)' }}>
                NeedLink in your pocket
              </h2>
              <p className="text-white/45 font-light leading-[1.85] mb-8" style={{ fontSize: 15, maxWidth: 400 }}>
                Browse open needs, pledge items, and confirm deliveries from anywhere in Uganda. Always free.
              </p>

              <div className="flex gap-3 justify-center lg:justify-start flex-wrap mb-8">
                <a href="#" aria-label="Download NeedLink on the App Store" className={`dl-btn ${isIOS ? 'dl-solid' : 'dl-outline'}`}>
                  <svg width="20" height="24" viewBox="0 0 24 28" fill={isIOS ? '#164E63' : 'white'} aria-hidden="true">
                    <path d="M18.71 19.5C17.88 21.07 17 22.6 15.27 22.63C13.57 22.66 13 21.63 11.07 21.63C9.12 21.63 8.51 22.6 6.9 22.66C5.22 22.72 4.21 21.04 3.37 19.5C1.65 16.25 0.34 10.28 2.11 6.3C2.96 4.33 4.95 3.07 7.11 3.04C8.75 3.01 10.28 4.12 11.28 4.12C12.25 4.12 14.1 2.78 16.08 2.97C16.88 3 19.19 3.3 20.64 5.5C20.5 5.59 17.85 7.2 17.88 10.54C17.92 14.53 21.27 15.83 21.31 15.85C21.27 15.96 20.79 17.58 19.68 19.5H18.71ZM13 1.57C13.82 0.64 15.13 0 16.25 0C16.39 1.31 15.88 2.64 15.07 3.57C14.27 4.5 13.03 5.17 11.77 5.07C11.6 3.78 12.24 2.49 13 1.57Z" />
                  </svg>
                  <div>
                    <div className="text-[10px] leading-tight mb-0.5" style={{ opacity: 0.52, color: isIOS ? '#164E63' : 'white' }}>Download on the</div>
                    <div className="font-mono font-bold text-base leading-tight" style={{ color: isIOS ? '#164E63' : 'white' }}>App Store</div>
                  </div>
                </a>
                <a href="#" aria-label="Get NeedLink on Google Play" className={`dl-btn ${isAndroid ? 'dl-solid' : 'dl-outline'}`}>
                  <svg width="20" height="22" viewBox="0 0 22 24" fill="none" aria-hidden="true">
                    <path d="M0.432 0.4C0.16 0.7 0 1.16 0 1.76V22.24C0 22.84 0.16 23.3 0.432 23.6L0.52 23.68L11.64 12.56V12.44L0.52 1.32L0.432 0.4Z" fill={isAndroid ? '#00C4FF' : 'rgba(255,255,255,0.82)'} />
                    <path d="M15.44 16.36L11.64 12.56V12.44L15.44 8.64L15.56 8.72L20.12 11.36C21.44 12.12 21.44 13.36 20.12 14.12L15.56 16.28L15.44 16.36Z" fill={isAndroid ? '#FFD500' : 'rgba(255,255,255,0.62)'} />
                    <path d="M15.56 16.28L11.64 12.36L0.432 23.6C0.88 24.08 1.64 24.12 2.52 23.64L15.56 16.28Z" fill={isAndroid ? '#FF3D00' : 'rgba(255,255,255,0.72)'} />
                    <path d="M15.56 8.72L2.52 1.36C1.64 0.88 0.88 0.92 0.432 1.4L11.64 12.36L15.56 8.72Z" fill={isAndroid ? '#00E676' : 'rgba(255,255,255,0.72)'} />
                  </svg>
                  <div>
                    <div className="text-[10px] leading-tight mb-0.5" style={{ opacity: 0.52, color: isAndroid ? '#164E63' : 'white' }}>Get it on</div>
                    <div className="font-mono font-bold text-base leading-tight" style={{ color: isAndroid ? '#164E63' : 'white' }}>Google Play</div>
                  </div>
                </a>
              </div>

              <p className="font-mono text-[11px]" style={{ color: 'rgba(255,255,255,0.22)' }}>
                Prefer the browser?{' '}
                <Link to="/register" className="text-[#22D3EE] hover:text-white transition-colors focus-visible:outline-none focus-visible:underline">Use the web app →</Link>
              </p>
            </Reveal>

            <div className="hidden lg:block shrink-0" style={{ transform: 'rotate(2deg)' }}>
              <PhoneMockup screen="pledges" />
            </div>
          </div>
        </section>

        {/* ── FAQ ─────────────────────────────────────────────── */}
        <section className="py-24 px-6 bg-white">
          <div className="max-w-[700px] mx-auto">
            <Reveal className="mb-12">
              <p className="font-mono text-[11px] tracking-[0.12em] text-[#0891B2] uppercase mb-4">Got questions?</p>
              <h2 className="font-mono font-bold text-[#164E63] tracking-tight" style={{ fontSize: 'clamp(1.8rem,4vw,2.8rem)' }}>Frequently asked</h2>
            </Reveal>
            <div
              className="rounded-2xl px-6"
              style={{ background: '#FAFCFE', border: '1px solid #E0EEF6' }}
              role="list"
              aria-label="Frequently asked questions"
            >
              {FAQS.map(f => <FaqItem key={f.q} q={f.q} a={f.a} />)}
            </div>
          </div>
        </section>

        {/* ── FINAL CTA ───────────────────────────────────────── */}
        <section className="py-24 px-6 bg-[#EA580C] relative overflow-hidden">
          <div aria-hidden className="absolute inset-0 pointer-events-none" style={{ backgroundImage: 'radial-gradient(circle at 10% 50%,rgba(255,255,255,0.07) 0%,transparent 46%),radial-gradient(circle at 90% 50%,rgba(0,0,0,0.1) 0%,transparent 46%)' }} />
          <div className="max-w-[720px] mx-auto text-center relative z-10">
            <Reveal>
              <h2
                className="font-mono font-bold text-white tracking-tight leading-snug mb-5"
                style={{ fontSize: 'clamp(2rem,4.5vw,3.5rem)' }}
              >
                Start making an impact today.
              </h2>
              <p className="text-white/62 font-light mb-10 leading-[1.85]" style={{ fontSize: 16 }}>
                Whether you have things to give or needs to post: NeedLink makes giving direct, traceable, and meaningful.
              </p>
              <div className="flex gap-4 justify-center flex-wrap">
                <Link
                  to="/register"
                  className="inline-flex items-center gap-2 px-8 font-semibold text-[#EA580C] bg-white hover:bg-[#FEFCF8] rounded-xl transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-[#EA580C]"
                  style={{ fontSize: 15, height: 50 }}
                >
                  <Heart size={16} aria-hidden="true" /> I want to donate
                </Link>
                <Link
                  to="/register"
                  className="inline-flex items-center gap-2 px-8 font-semibold text-white rounded-xl transition-all duration-200 hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/45"
                  style={{ fontSize: 15, height: 50, background: 'rgba(0,0,0,0.12)', border: '1px solid rgba(255,255,255,0.22)' }}
                >
                  <Users size={16} aria-hidden="true" /> Register my NGO
                </Link>
              </div>
            </Reveal>
          </div>
        </section>

      </main>

      {/* ── FOOTER ──────────────────────────────────────────── */}
      <footer className="bg-[#071D2C] text-white px-6 pt-16 pb-8">
        <div className="max-w-[1120px] mx-auto">
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-10 mb-14">

            <div className="sm:col-span-2 lg:col-span-1">
              <div className="flex items-center gap-2.5 mb-4">
                <NeedLinkLogo size={32} />
                <span className="font-mono font-bold text-white text-lg tracking-tight">NeedLink</span>
              </div>
              <p className="text-white/32 text-sm font-light leading-relaxed mb-5">
                Connecting in-kind donors with verified NGOs across Uganda. Precise, traceable, impactful.
              </p>
              <div className="flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-[#22D3EE] nl-dot shrink-0" />
                <span className="font-mono text-[10px] tracking-[0.08em]" style={{ color: 'rgba(34,211,238,0.45)' }}>LIVE · UGANDA</span>
              </div>
            </div>

            <div>
              <h3 className="font-mono font-semibold text-[10px] tracking-[0.12em] uppercase mb-4" style={{ color: 'rgba(255,255,255,0.45)' }}>Platform</h3>
              <ul className="space-y-3">
                {[{ to: '/register', l: 'For Donors' }, { to: '/register', l: 'For NGOs' }, { to: '/login', l: 'Sign in' }, { to: '/register', l: 'Create account' }].map(({ to, l }) => (
                  <li key={l}><Link to={to} className="text-sm font-light transition-colors focus-visible:outline-none focus-visible:underline" style={{ color: 'rgba(255,255,255,0.32)' }} onMouseEnter={e => (e.currentTarget.style.color = 'white')} onMouseLeave={e => (e.currentTarget.style.color = 'rgba(255,255,255,0.32)')}>{l}</Link></li>
                ))}
              </ul>
            </div>

            <div>
              <h3 className="font-mono font-semibold text-[10px] tracking-[0.12em] uppercase mb-4" style={{ color: 'rgba(255,255,255,0.45)' }}>Learn</h3>
              <ul className="space-y-3">
                {[{ href: '#how-it-works', l: 'How it works' }, { href: '#features', l: 'Features' }, { href: '#download', l: 'Download app' }, { href: '#', l: 'FAQ' }].map(({ href, l }) => (
                  <li key={l}><a href={href} className="text-sm font-light transition-colors focus-visible:outline-none focus-visible:underline" style={{ color: 'rgba(255,255,255,0.32)' }} onMouseEnter={e => (e.currentTarget.style.color = 'white')} onMouseLeave={e => (e.currentTarget.style.color = 'rgba(255,255,255,0.32)')}>{l}</a></li>
                ))}
              </ul>
            </div>

            <div>
              <h3 className="font-mono font-semibold text-[10px] tracking-[0.12em] uppercase mb-4" style={{ color: 'rgba(255,255,255,0.45)' }}>Get the app</h3>
              <div className="flex flex-col gap-3">
                {[
                  { href: '#', label: 'Download on App Store', text: 'App Store (iOS)' },
                  { href: '#', label: 'Get on Google Play', text: 'Google Play (Android)' },
                ].map(({ href, label, text }) => (
                  <a key={text} href={href} aria-label={label} className="text-sm font-light transition-colors focus-visible:outline-none focus-visible:underline" style={{ color: 'rgba(255,255,255,0.32)' }} onMouseEnter={e => (e.currentTarget.style.color = 'white')} onMouseLeave={e => (e.currentTarget.style.color = 'rgba(255,255,255,0.32)')}>{text}</a>
                ))}
              </div>
            </div>

          </div>

          <div className="border-t pt-6 flex flex-col sm:flex-row items-center justify-between gap-3" style={{ borderColor: 'rgba(255,255,255,0.055)' }}>
            <p className="font-mono text-xs font-light" style={{ color: 'rgba(255,255,255,0.2)' }}>© {new Date().getFullYear()} NeedLink · Uganda · In-kind donations only</p>
            <p className="text-xs font-light" style={{ color: 'rgba(255,255,255,0.15)' }}>Connecting items to people who need them most.</p>
          </div>
        </div>
      </footer>
    </>
  )
}
