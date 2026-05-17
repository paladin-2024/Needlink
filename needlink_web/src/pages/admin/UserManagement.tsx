import { useEffect, useState } from 'react'
import { Search, AlertCircle } from 'lucide-react'
import { format, parseISO } from 'date-fns'
import { supabase } from '../../lib/supabase'

interface Donor {
  id: string
  full_name: string
  created_at: string
  pledge_count: number
}

function PageError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="p-8 flex flex-col items-center justify-center min-h-64 gap-4">
      <AlertCircle size={28} className="text-[#EF4444]" />
      <p className="text-[#164E63] font-semibold">{message}</p>
      <button onClick={onRetry} className="px-4 py-2 rounded-xl bg-[#0891B2] text-white text-sm font-semibold cursor-pointer hover:bg-[#0E7490] transition-colors">
        Retry
      </button>
    </div>
  )
}

export default function UserManagement() {
  const [donors, setDonors]       = useState<Donor[]>([])
  const [loading, setLoading]     = useState(true)
  const [loadError, setLoadError] = useState('')
  const [search, setSearch]       = useState('')

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const { data: profiles, error } = await supabase
        .from('profiles')
        .select('id, full_name, created_at')
        .eq('role', 'donor')
        .order('created_at', { ascending: false })
      if (error) throw new Error(error.message)

      const counts = await Promise.all(
        (profiles ?? []).map(p =>
          supabase.from('pledges').select('*', { count: 'exact', head: true }).eq('donor_id', p.id)
        )
      )

      setDonors((profiles ?? []).map((p, i) => ({ ...p, pledge_count: counts[i].count ?? 0 })))
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Failed to load donors.')
    } finally {
      setLoading(false)
    }
  }

  const activeDonors = donors.filter(d => d.pledge_count > 0).length
  const totalPledges = donors.reduce((s, d) => s + d.pledge_count, 0)

  const filtered = donors.filter(d =>
    d.full_name.toLowerCase().includes(search.toLowerCase())
  )

  if (loading) return (
    <div className="p-8 flex items-center justify-center min-h-64">
      <div className="w-7 h-7 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (loadError) return <PageError message={loadError} onRetry={load} />

  const topDonors = [...donors].sort((a, b) => b.pledge_count - a.pledge_count).slice(0, 5).filter(d => d.pledge_count > 0)
  const topMax    = topDonors[0]?.pledge_count ?? 1

  return (
    <div>

      {/* Sticky page header */}
      <div className="sticky top-0 z-10 bg-white px-8 py-5" style={{ borderBottom: '1px solid #E2E8F0' }}>
        <h1 className="font-heading font-bold text-[#164E63] text-2xl">User Management</h1>
        <p className="text-[#94A3B8] text-sm mt-0.5">All registered donors on the platform.</p>

        <div className="flex items-end gap-10 mt-5 pt-4" style={{ borderTop: '1px solid #F3F5F8' }}>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#0891B2]">{donors.length.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Registered donors</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#16A34A]">{activeDonors.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Active (pledged)</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#7C3AED]">{totalPledges.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Total pledges made</div>
          </div>
        </div>
      </div>

      {/* Body */}
      <div className="p-8">

        {/* Top donors leaderboard */}
        {topDonors.length > 0 && (
          <div className="bg-white rounded-2xl border border-[#E2E8F0] p-6 mb-6" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
            <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">Top Donors by Activity</h2>
            <div className="space-y-3.5">
              {topDonors.map((donor, i) => {
                const pct = Math.round((donor.pledge_count / topMax) * 100)
                return (
                  <div key={donor.id} className="flex items-center gap-4">
                    <span className="w-5 text-xs font-mono text-[#94A3B8] text-right shrink-0">{i + 1}</span>
                    <div className="w-7 h-7 rounded-xl flex items-center justify-center text-xs font-bold text-white shrink-0" style={{ background: '#0E7490' }}>
                      {donor.full_name.charAt(0).toUpperCase()}
                    </div>
                    <span className="w-44 text-sm font-semibold text-[#164E63] truncate shrink-0">{donor.full_name}</span>
                    <div className="flex-1 h-2 rounded-full bg-[#F3F5F8] overflow-hidden">
                      <div className="h-full rounded-full bg-[#0891B2] transition-all" style={{ width: `${pct}%` }} />
                    </div>
                    <div className="flex items-center gap-1.5 shrink-0">
                      <span className="font-mono font-bold text-[#164E63] text-sm w-6 text-right">{donor.pledge_count}</span>
                      <span className="text-[#94A3B8] text-xs">pledges</span>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        )}

        {/* Search */}
        <div className="relative max-w-xs mb-5">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search donors…"
            className="w-full pl-9 pr-4 py-2.5 border border-[#E2E8F0] rounded-xl text-sm text-[#164E63] bg-white focus:outline-none focus:border-[#0891B2] transition-colors"
          />
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-[#E2E8F0] overflow-hidden" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: '#F8FAFB', borderBottom: '1px solid #F1F5F9' }}>
                {['Donor', 'Joined', 'Pledges', 'Activity'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-[11px] font-semibold text-[#64748B] uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr><td colSpan={4} className="px-5 py-10 text-center text-[#94A3B8] text-sm">No donors found.</td></tr>
              )}
              {filtered.map(donor => (
                <tr key={donor.id} className="hover:bg-[#F8FAFB] transition-colors" style={{ borderTop: '1px solid #F1F5F9' }}>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <div
                        className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 font-bold text-sm text-white"
                        style={{ background: '#0E7490' }}
                      >
                        {donor.full_name.charAt(0).toUpperCase()}
                      </div>
                      <span className="font-semibold text-[#164E63]">{donor.full_name}</span>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-xs font-mono text-[#64748B]">{format(parseISO(donor.created_at), 'dd MMM yyyy')}</td>
                  <td className="px-5 py-4 font-mono font-bold text-[#164E63]">{donor.pledge_count}</td>
                  <td className="px-5 py-4">
                    {donor.pledge_count > 0 ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-green-50 text-green-700 border border-green-200">
                        <span className="w-1.5 h-1.5 rounded-full bg-green-500" /> Active
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-50 text-slate-400 border border-slate-200">
                        No pledges
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <p className="text-[#94A3B8] text-xs mt-4 text-center font-mono">
          {filtered.length} of {donors.length} donors
        </p>

      </div>
    </div>
  )
}
