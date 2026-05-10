import { useState, useEffect, useRef } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Eye, EyeOff, AlertCircle } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import NeedLinkLogo from '../../components/NeedLinkLogo'

function useAnimatedCount(target: number, duration = 1400) {
  const [count, setCount] = useState(0)
  const raf = useRef<number>(0)
  useEffect(() => {
    if (target === 0) return
    const start = performance.now()
    const tick = (now: number) => {
      const t = Math.min((now - start) / duration, 1)
      setCount(Math.round(t * target))
      if (t < 1) raf.current = requestAnimationFrame(tick)
    }
    raf.current = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf.current)
  }, [target, duration])
  return count
}

function NetworkSVG() {
  return (
    <svg viewBox="0 0 440 340" fill="none" aria-hidden="true" className="absolute inset-0 w-full h-full">
      <line x1="88" y1="90" x2="218" y2="52" stroke="white" strokeWidth="1" strokeOpacity="0.12" />
      <line x1="218" y1="52" x2="354" y2="114" stroke="white" strokeWidth="1" strokeOpacity="0.12" />
      <line x1="88" y1="90" x2="152" y2="198" stroke="white" strokeWidth="1" strokeOpacity="0.12" />
      <line x1="354" y1="114" x2="284" y2="238" stroke="white" strokeWidth="1" strokeOpacity="0.12" />
      <line x1="152" y1="198" x2="284" y2="238" stroke="white" strokeWidth="1" strokeOpacity="0.12" />
      <line x1="68" y1="268" x2="152" y2="198" stroke="white" strokeWidth="1" strokeOpacity="0.12" />
      <line x1="284" y1="238" x2="388" y2="256" stroke="white" strokeWidth="1" strokeOpacity="0.12" />
      <line x1="218" y1="52" x2="152" y2="198" stroke="white" strokeWidth="1" strokeOpacity="0.06" />
      <circle cx="88" cy="90" r="4" fill="white" fillOpacity="0.25" />
      <circle cx="218" cy="52" r="3.5" fill="white" fillOpacity="0.22" />
      <circle cx="354" cy="114" r="6" fill="white" fillOpacity="0.3" />
      <circle cx="152" cy="198" r="4.5" fill="white" fillOpacity="0.25" />
      <circle cx="284" cy="238" r="5.5" fill="white" fillOpacity="0.28" />
      <circle cx="68" cy="268" r="3" fill="white" fillOpacity="0.2" />
      <circle cx="388" cy="256" r="3.5" fill="white" fillOpacity="0.22" />
      <circle cx="354" cy="114" r="14" stroke="white" strokeWidth="1" strokeOpacity="0.08" />
      <circle cx="284" cy="238" r="12" stroke="white" strokeWidth="1" strokeOpacity="0.08" />
      <circle cx="354" cy="114" r="24" stroke="white" strokeWidth="0.5" strokeOpacity="0.04" />
    </svg>
  )
}

export default function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [totalItems, setTotalItems] = useState(0)
  const animatedCount = useAnimatedCount(totalItems)

  useEffect(() => {
    supabase.from('pledges').select('quantity').eq('status', 'confirmed')
      .then(({ data }) => {
        const sum = (data ?? []).reduce((acc, p) => acc + (p.quantity ?? 0), 0)
        setTotalItems(sum)
      })
  }, [])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) { setError(error.message); setLoading(false); return }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', data.user.id)
      .single()

    navigate(profile?.role === 'ngo_admin' ? '/ngo' : '/donor')
  }

  return (
    <div className="min-h-screen flex">

      {/* ── Brand panel (desktop) ── */}
      <div
        className="hidden lg:flex lg:w-[44%] flex-col relative overflow-hidden flex-shrink-0"
        style={{ background: '#071D2C' }}
      >
        <NetworkSVG />

        <div className="relative z-10 flex flex-col h-full p-12">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-3 w-fit">
            <NeedLinkLogo size={36} />
            <span className="font-mono font-bold text-lg text-white tracking-tight">NeedLink</span>
          </Link>

          {/* Statement */}
          <div className="flex-1 flex flex-col justify-center">
            <p className="text-white/40 text-xs font-mono tracking-[0.2em] uppercase mb-8">
              Uganda · In-kind Donations
            </p>
            <h2
              className="text-white font-bold leading-[1.15]"
              style={{ fontSize: 'clamp(1.9rem, 3.2vw, 2.8rem)' }}
            >
              Connecting donors<br />with what matters.
            </h2>
            <p className="mt-5 text-white/50 text-[0.95rem] leading-relaxed" style={{ maxWidth: '26ch' }}>
              Food, clothing, medicine, school supplies — precise, traceable giving to verified NGOs.
            </p>
          </div>

          {/* Live stat */}
          <div className="flex items-center gap-3">
            <span className="w-2 h-2 rounded-full bg-[#22D3EE] animate-pulse flex-shrink-0" />
            <span className="text-white/55 text-sm font-mono">
              <span className="text-white font-semibold">
                {animatedCount > 0 ? animatedCount.toLocaleString() : '—'}
              </span>{' '}
              items donated this year
            </span>
          </div>
        </div>
      </div>

      {/* ── Form panel ── */}
      <div className="flex-1 flex flex-col bg-white min-h-screen">
        {/* Top bar */}
        <div className="flex items-center justify-between px-8 pt-7 pb-0">
          <Link to="/" className="flex items-center gap-2 lg:invisible" aria-label="NeedLink home">
            <NeedLinkLogo size={26} />
            <span className="font-mono font-bold text-[#164E63] text-sm">NeedLink</span>
          </Link>
          <p className="text-sm text-[#64748B]">
            No account?{' '}
            <Link to="/register" className="text-[#0891B2] font-semibold hover:underline">
              Create one
            </Link>
          </p>
        </div>

        {/* Centered form */}
        <div className="flex-1 flex items-center justify-center px-8 py-12">
          <div className="w-full max-w-[22rem]">

            <div className="auth-in mb-9" style={{ '--i': '0' } as React.CSSProperties}>
              <h1
                className="font-bold text-[#0F2333] leading-tight"
                style={{ fontSize: 'clamp(1.7rem, 4vw, 2.15rem)' }}
              >
                Welcome back.
              </h1>
              <p className="text-[#64748B] mt-2 text-[0.95rem]">
                Sign in to your NeedLink account.
              </p>
            </div>

            {error && (
              <div
                className="auth-in flex items-start gap-2.5 bg-red-50 border border-red-100 text-red-700 text-sm rounded-2xl p-4 mb-5"
                role="alert"
                aria-live="polite"
                style={{ '--i': '0.5' } as React.CSSProperties}
              >
                <AlertCircle size={15} className="shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">

              <div className="auth-in" style={{ '--i': '1' } as React.CSSProperties}>
                <label htmlFor="email" className="block text-sm font-semibold text-[#0F2333] mb-2">
                  Email address
                </label>
                <input
                  id="email"
                  type="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  className="w-full px-4 py-3.5 border-2 border-[#E8EDF2] rounded-2xl text-[#0F2333] bg-white focus:outline-none focus:border-[#0891B2] placeholder:text-[#B0BECA] transition-colors duration-150 text-[0.95rem]"
                  placeholder="you@example.com"
                />
              </div>

              <div className="auth-in" style={{ '--i': '2' } as React.CSSProperties}>
                <label htmlFor="password" className="block text-sm font-semibold text-[#0F2333] mb-2">
                  Password
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="current-password"
                    required
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    className="w-full px-4 py-3.5 pr-12 border-2 border-[#E8EDF2] rounded-2xl text-[#0F2333] bg-white focus:outline-none focus:border-[#0891B2] placeholder:text-[#B0BECA] transition-colors duration-150 text-[0.95rem]"
                    placeholder="••••••••"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(v => !v)}
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-2 rounded-xl text-[#94A3B8] hover:text-[#64748B] hover:bg-[#F1F5F9] transition-colors cursor-pointer"
                  >
                    {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
                  </button>
                </div>
              </div>

              <div className="auth-in pt-2" style={{ '--i': '3' } as React.CSSProperties}>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 px-4 bg-[#EA580C] hover:bg-[#C2410C] active:scale-[0.98] disabled:opacity-55 text-white font-bold rounded-2xl transition-all duration-150 cursor-pointer text-[0.95rem] tracking-wide"
                >
                  {loading ? 'Signing in…' : 'Sign in'}
                </button>
              </div>
            </form>

            <p className="auth-in text-xs text-center text-[#94A3B8] mt-8" style={{ '--i': '4' } as React.CSSProperties}>
              By signing in you agree to our{' '}
              <span className="text-[#64748B] underline-offset-2 hover:underline cursor-pointer">Terms</span>
              {' '}and{' '}
              <span className="text-[#64748B] underline-offset-2 hover:underline cursor-pointer">Privacy Policy</span>.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
