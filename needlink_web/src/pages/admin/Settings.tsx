import { useState } from 'react'
import { Eye, EyeOff, CheckCircle, AlertCircle } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'

export default function Settings() {
  const { profile } = useAuth()
  const [newPw, setNewPw]           = useState('')
  const [confirmPw, setConfirmPw]   = useState('')
  const [showNew, setShowNew]       = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)
  const [loading, setLoading]     = useState(false)
  const [success, setSuccess]     = useState(false)
  const [error, setError]         = useState('')

  async function handlePasswordChange(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setSuccess(false)

    if (newPw !== confirmPw) { setError('New passwords do not match.'); return }
    if (newPw.length < 8)    { setError('Password must be at least 8 characters.'); return }

    setLoading(true)
    const { error: err } = await supabase.auth.updateUser({ password: newPw })
    if (err) { setError(err.message); setLoading(false); return }

    setSuccess(true)
    setNewPw('')
    setConfirmPw('')
    setLoading(false)
  }

  return (
    <div className="p-8 max-w-2xl">
      <div className="mb-7">
        <h1 className="font-heading font-bold text-[#164E63] text-2xl">Settings</h1>
        <p className="text-[#64748B] text-sm mt-1">Admin account settings.</p>
      </div>

      {/* Profile info */}
      <div className="bg-white rounded-2xl p-6 border border-[#E8EDF2] mb-6" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
        <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-4">
          Account
        </h2>
        <div className="flex items-center gap-4">
          <div
            className="w-12 h-12 rounded-2xl flex items-center justify-center text-lg font-bold text-white flex-shrink-0"
            style={{ background: 'linear-gradient(135deg, #0891B2, #0E7490)' }}
          >
            {profile?.full_name?.charAt(0).toUpperCase() ?? 'A'}
          </div>
          <div>
            <p className="font-semibold text-[#164E63]">{profile?.full_name ?? 'Admin'}</p>
            <p className="text-[#64748B] text-xs mt-0.5 font-mono">super_admin</p>
          </div>
        </div>
      </div>

      {/* Password change */}
      <div className="bg-white rounded-2xl p-6 border border-[#E8EDF2]" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
        <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">
          Change Password
        </h2>

        {success && (
          <div className="flex items-center gap-2.5 bg-green-50 border border-green-200 text-green-700 text-sm rounded-xl p-3.5 mb-5">
            <CheckCircle size={15} className="shrink-0" />
            Password updated successfully.
          </div>
        )}

        {error && (
          <div className="flex items-center gap-2.5 bg-red-50 border border-red-100 text-red-700 text-sm rounded-xl p-3.5 mb-5" role="alert">
            <AlertCircle size={15} className="shrink-0" />
            {error}
          </div>
        )}

        <form onSubmit={handlePasswordChange} className="space-y-4">
          {[
            { id: 'new-pw',     label: 'New Password',     val: newPw,     set: setNewPw,     show: showNew,    toggle: () => setShowNew(v => !v)    },
            { id: 'confirm-pw', label: 'Confirm Password', val: confirmPw, set: setConfirmPw, show: showConfirm, toggle: () => setShowConfirm(v => !v) },
          ].map(({ id, label, val, set, show, toggle }) => (
            <div key={id}>
              <label htmlFor={id} className="block text-sm font-semibold text-[#164E63] mb-1.5">{label}</label>
              <div className="relative">
                <input
                  id={id}
                  type={show ? 'text' : 'password'}
                  required
                  value={val}
                  onChange={e => set(e.target.value)}
                  className="w-full px-4 py-3 pr-11 border border-[#E8EDF2] rounded-xl text-[#164E63] bg-white focus:outline-none focus:border-[#0891B2] focus:ring-2 focus:ring-[#0891B2]/10 transition-all text-sm"
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  onClick={toggle}
                  className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 text-[#94A3B8] hover:text-[#64748B] cursor-pointer rounded-lg hover:bg-[#F8FAFC] transition-colors"
                >
                  {show ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>
          ))}

          <button
            type="submit"
            disabled={loading}
            className="px-6 py-2.5 rounded-xl font-bold text-white text-sm transition-all duration-150 active:scale-[0.98] disabled:opacity-55 cursor-pointer mt-2"
            style={{ background: 'linear-gradient(135deg, #0891B2, #0E7490)' }}
          >
            {loading ? 'Updating…' : 'Update Password'}
          </button>
        </form>
      </div>

      {/* Platform info */}
      <div className="bg-white rounded-2xl p-6 border border-[#E8EDF2] mt-6" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
        <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-4">
          Platform
        </h2>
        <dl className="space-y-3 text-sm">
          {[
            { label: 'Platform', value: 'NeedLink' },
            { label: 'Region',   value: 'Uganda' },
            { label: 'Version',  value: '2.0.0' },
          ].map(({ label, value }) => (
            <div key={label} className="flex items-center justify-between">
              <dt className="text-[#64748B] font-medium">{label}</dt>
              <dd className="font-mono text-[#164E63] text-xs font-semibold">{value}</dd>
            </div>
          ))}
        </dl>
      </div>
    </div>
  )
}
