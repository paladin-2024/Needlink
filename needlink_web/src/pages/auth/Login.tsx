import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Eye, EyeOff, AlertCircle } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import NeedLinkLogo from '../../components/NeedLinkLogo'

export default function AdminLogin() {
  const navigate = useNavigate()
  const [email, setEmail]           = useState('')
  const [password, setPassword]     = useState('')
  const [showPass, setShowPass]     = useState(false)
  const [error, setError]           = useState('')
  const [loading, setLoading]       = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)

    const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password })
    if (authError || !data.user) { setError(authError?.message ?? 'Sign-in failed.'); setLoading(false); return }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', data.user.id)
      .single()

    if (profile?.role !== 'super_admin') {
      await supabase.auth.signOut()
      setError('Access restricted to admin accounts.')
      setLoading(false)
      return
    }

    navigate('/admin/overview')
  }

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center px-4"
      style={{ background: '#0C1A22' }}
    >
      {/* Logo */}
      <div className="flex flex-col items-center mb-8">
        <NeedLinkLogo size={46} />
        <span className="font-heading font-bold text-xl text-white mt-3 tracking-tight">NeedLink</span>
        <span className="text-[#7BC5D4] text-[11px] font-mono tracking-[0.22em] uppercase mt-1.5">Admin Portal</span>
      </div>

      {/* Card */}
      <div className="w-full max-w-[22rem] bg-white rounded-2xl p-8 shadow-2xl">
        <h1 className="font-heading font-bold text-[#164E63] text-xl mb-1">Sign in</h1>
        <p className="text-[#64748B] text-sm mb-6">Admin access only — no self-registration.</p>

        {error && (
          <div
            className="flex items-start gap-2.5 bg-red-50 border border-red-100 text-red-700 text-sm rounded-xl p-3.5 mb-5"
            role="alert"
            aria-live="polite"
          >
            <AlertCircle size={15} className="shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-semibold text-[#164E63] mb-1.5">
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="w-full px-4 py-3 border border-[#E8EDF2] rounded-xl text-[#164E63] bg-white focus:outline-none focus:border-[#0891B2] focus:ring-2 focus:ring-[#0891B2]/10 transition-all text-sm"
              placeholder="admin@needlink.ug"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-semibold text-[#164E63] mb-1.5">
              Password
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPass ? 'text' : 'password'}
                autoComplete="current-password"
                required
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="w-full px-4 py-3 pr-11 border border-[#E8EDF2] rounded-xl text-[#164E63] bg-white focus:outline-none focus:border-[#0891B2] focus:ring-2 focus:ring-[#0891B2]/10 transition-all text-sm"
                placeholder="••••••••"
              />
              <button
                type="button"
                onClick={() => setShowPass(v => !v)}
                aria-label={showPass ? 'Hide password' : 'Show password'}
                className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 text-[#94A3B8] hover:text-[#64748B] transition-colors cursor-pointer rounded-lg hover:bg-[#F8FAFC]"
              >
                {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 rounded-xl font-bold text-white text-sm tracking-wide mt-2 transition-all duration-150 active:scale-[0.98] disabled:opacity-55 cursor-pointer bg-[#0891B2] hover:bg-[#0E7490]"
          >
            {loading ? 'Signing in…' : 'Sign in to Admin Portal'}
          </button>
        </form>
      </div>

      <p className="text-[#3A5A6A] text-xs mt-6">
        Not an admin? Use the NeedLink mobile app.
      </p>
    </div>
  )
}
