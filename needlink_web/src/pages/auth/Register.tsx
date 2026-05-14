import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Eye, EyeOff, AlertCircle, Users, Building2, Phone, Mail, User, MapPin } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import NeedLinkLogo from '../../components/NeedLinkLogo'
import type { Role } from '../../types'

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
    </svg>
  )
}

const roles: { value: Role; icon: React.ReactNode; title: string; desc: string }[] = [
  { value: 'donor', icon: <Users size={20} />, title: 'Donor', desc: 'Give items to NGOs' },
  { value: 'ngo_admin', icon: <Building2 size={20} />, title: 'NGO Admin', desc: 'Receive & manage donations' },
]

export default function Register() {
  const navigate = useNavigate()
  const [role, setRole] = useState<Role>('donor')
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [ngoName, setNgoName] = useState('')
  const [ngoLocation, setNgoLocation] = useState('')
  const [ngoEmail, setNgoEmail] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)

    const { data, error: signUpError } = await supabase.auth.signUp({ email, password })
    if (signUpError || !data.user) {
      setError(signUpError?.message ?? 'Sign up failed')
      setLoading(false)
      return
    }

    const { error: profileError } = await supabase.from('profiles').upsert({
      id: data.user.id,
      full_name: fullName,
      role,
      phone: phone || null,
    })
    if (profileError) { setError(profileError.message); setLoading(false); return }

    if (role === 'ngo_admin') {
      const { error: ngoError } = await supabase.from('ngos').insert({
        admin_id: data.user.id,
        name: ngoName,
        location: ngoLocation,
        contact_email: ngoEmail || email,
      })
      if (ngoError) { setError(ngoError.message); setLoading(false); return }
    }

    navigate(role === 'ngo_admin' ? '/ngo' : '/donor')
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
          <Link to="/" className="flex items-center gap-3 w-fit">
            <NeedLinkLogo size={36} />
            <span className="font-mono font-bold text-lg text-white tracking-tight">NeedLink</span>
          </Link>

          <div className="flex-1 flex flex-col justify-center">
            <p className="text-white/40 text-xs font-mono tracking-[0.2em] uppercase mb-8">
              Uganda · In-kind Donations
            </p>
            <h2
              className="text-white font-bold leading-[1.15]"
              style={{ fontSize: 'clamp(1.9rem, 3.2vw, 2.8rem)' }}
            >
              Join the network.<br />Make it count.
            </h2>
            <p className="mt-5 text-white/50 text-[0.95rem] leading-relaxed" style={{ maxWidth: '26ch' }}>
              Verified NGOs. Real items. Traceable impact across every district in Uganda.
            </p>
          </div>

          <div className="space-y-3">
            {[
              { n: '240+', label: 'NGOs registered' },
              { n: '18', label: 'Districts covered' },
            ].map(({ n, label }) => (
              <div key={label} className="flex items-baseline gap-3">
                <span className="font-mono font-bold text-white text-lg">{n}</span>
                <span className="text-white/45 text-sm">{label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── Form panel ── */}
      <div className="flex-1 flex flex-col bg-white overflow-y-auto">
        {/* Top bar */}
        <div className="flex items-center justify-between px-8 pt-7 flex-shrink-0">
          <Link to="/" className="flex items-center gap-2 lg:invisible" aria-label="NeedLink home">
            <NeedLinkLogo size={26} />
            <span className="font-mono font-bold text-[#164E63] text-sm">NeedLink</span>
          </Link>
          <p className="text-sm text-[#64748B]">
            Have an account?{' '}
            <Link to="/login" className="text-[#0891B2] font-semibold hover:underline">
              Sign in
            </Link>
          </p>
        </div>

        {/* Form */}
        <div className="flex-1 flex items-start justify-center px-8 py-10">
          <div className="w-full max-w-[22rem]">

            <div className="auth-in mb-8" style={{ '--i': '0' } as React.CSSProperties}>
              <h1
                className="font-bold text-[#0F2333] leading-tight"
                style={{ fontSize: 'clamp(1.7rem, 4vw, 2.15rem)' }}
              >
                Create account.
              </h1>
              <p className="text-[#64748B] mt-2 text-[0.95rem]">
                Join Uganda's in-kind donation network.
              </p>
            </div>

            {/* Role selector */}
            <div className="auth-in mb-6" style={{ '--i': '1' } as React.CSSProperties}>
              <p className="text-sm font-semibold text-[#0F2333] mb-3">I am joining as</p>
              <div className="grid grid-cols-2 gap-3">
                {roles.map(({ value: r, icon, title, desc }) => (
                  <button
                    key={r}
                    type="button"
                    onClick={() => setRole(r)}
                    className={`p-4 rounded-2xl border-2 text-left transition-all duration-150 cursor-pointer ${
                      role === r
                        ? 'border-[#0891B2] bg-[#F0FAFE]'
                        : 'border-[#E8EDF2] bg-white hover:border-[#A5F3FC]'
                    }`}
                  >
                    <span className={`block mb-2 ${role === r ? 'text-[#0891B2]' : 'text-[#94A3B8]'}`}>
                      {icon}
                    </span>
                    <span className={`block text-sm font-semibold ${role === r ? 'text-[#0F2333]' : 'text-[#64748B]'}`}>
                      {title}
                    </span>
                    <span className="block text-xs text-[#94A3B8] mt-0.5 leading-tight">{desc}</span>
                  </button>
                ))}
              </div>
            </div>

            {error && (
              <div
                className="auth-in flex items-start gap-2.5 bg-red-50 border border-red-100 text-red-700 text-sm rounded-2xl p-4 mb-5"
                role="alert"
                aria-live="polite"
                style={{ '--i': '1.5' } as React.CSSProperties}
              >
                <AlertCircle size={15} className="shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">

              <Field
                icon={<User size={15} />}
                label="Full name"
                id="fullName"
                type="text"
                value={fullName}
                onChange={setFullName}
                required
                placeholder="Jane Nakato"
                delay={2}
                autoComplete="name"
              />

              <Field
                icon={<Mail size={15} />}
                label="Email address"
                id="email"
                type="email"
                value={email}
                onChange={setEmail}
                required
                placeholder="you@example.com"
                delay={3}
                autoComplete="email"
              />

              <Field
                icon={<Phone size={15} />}
                label="Phone (optional)"
                id="phone"
                type="tel"
                value={phone}
                onChange={setPhone}
                placeholder="+256 700 000 000"
                delay={4}
                autoComplete="tel"
              />

              <div className="auth-in" style={{ '--i': '5' } as React.CSSProperties}>
                <label htmlFor="password" className="block text-sm font-semibold text-[#0F2333] mb-2">
                  Password
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="new-password"
                    required
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    className="w-full px-4 py-3.5 pr-12 border-2 border-[#E8EDF2] rounded-2xl text-[#0F2333] bg-white focus:outline-none focus:border-[#0891B2] placeholder:text-[#B0BECA] transition-colors duration-150 text-[0.95rem]"
                    placeholder="Min. 8 characters"
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

              {/* NGO Details — revealed when ngo_admin selected */}
              {role === 'ngo_admin' && (
                <div
                  className="pt-4 border-t-2 border-[#E8EDF2] space-y-4"
                  style={{ animation: 'auth-slide-up 0.4s cubic-bezier(0.16, 1, 0.3, 1) both' }}
                >
                  <p className="text-xs font-bold text-[#0891B2] font-mono tracking-widest uppercase">
                    NGO Details
                  </p>

                  <Field
                    icon={<Building2 size={15} />}
                    label="NGO name"
                    id="ngoName"
                    type="text"
                    value={ngoName}
                    onChange={setNgoName}
                    required
                    placeholder="Hope Foundation Uganda"
                    delay={0}
                  />

                  <Field
                    icon={<MapPin size={15} />}
                    label="District / location"
                    id="ngoLocation"
                    type="text"
                    value={ngoLocation}
                    onChange={setNgoLocation}
                    required
                    placeholder="Kampala"
                    delay={0}
                  />

                  <Field
                    icon={<Mail size={15} />}
                    label="NGO contact email"
                    id="ngoEmail"
                    type="email"
                    value={ngoEmail}
                    onChange={setNgoEmail}
                    placeholder="info@ngo.org (defaults to yours)"
                    delay={0}
                  />
                </div>
              )}

              <div className="auth-in pt-2" style={{ '--i': '6' } as React.CSSProperties}>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 px-4 bg-[#EA580C] hover:bg-[#C2410C] active:scale-[0.98] disabled:opacity-55 text-white font-bold rounded-2xl transition-all duration-150 cursor-pointer text-[0.95rem] tracking-wide"
                >
                  {loading ? 'Creating account…' : 'Create account'}
                </button>
              </div>
            </form>

            <p className="auth-in text-xs text-center text-[#94A3B8] mt-6" style={{ '--i': '7' } as React.CSSProperties}>
              By creating an account you agree to our{' '}
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

function Field({
  icon, label, id, type, value, onChange, required, placeholder, delay, autoComplete,
}: {
  icon: React.ReactNode; label: string; id: string; type: string
  value: string; onChange: (v: string) => void; required?: boolean
  placeholder?: string; delay: number; autoComplete?: string
}) {
  return (
    <div className="auth-in" style={{ '--i': delay } as React.CSSProperties}>
      <label htmlFor={id} className="block text-sm font-semibold text-[#0F2333] mb-2">
        {label}
      </label>
      <div className="relative">
        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#94A3B8]">{icon}</span>
        <input
          id={id}
          type={type}
          required={required}
          value={value}
          autoComplete={autoComplete}
          onChange={e => onChange(e.target.value)}
          className="w-full pl-10 pr-4 py-3.5 border-2 border-[#E8EDF2] rounded-2xl text-[#0F2333] bg-white focus:outline-none focus:border-[#0891B2] placeholder:text-[#B0BECA] transition-colors duration-150 text-[0.95rem]"
          placeholder={placeholder}
        />
      </div>
    </div>
  )
}
