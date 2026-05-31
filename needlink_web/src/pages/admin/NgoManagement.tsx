import { useEffect, useState } from 'react'
import { BadgeCheck, Building2, CheckCircle, Trash2, Search, AlertCircle } from 'lucide-react'
import { format, parseISO } from 'date-fns'
import { supabase } from '../../lib/supabase'
import { useToast } from '../../components/Toast'

interface Ngo {
  id: string
  name: string
  location: string
  registration_number: string | null
  contact_email: string
  verified: boolean
  created_at: string
  needs_count?: number
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

export default function NgoManagement() {
  const { toast } = useToast()
  const [ngos, setNgos]           = useState<Ngo[]>([])
  const [loading, setLoading]     = useState(true)
  const [loadError, setLoadError] = useState('')
  const [search, setSearch]       = useState('')
  const [filter, setFilter]       = useState<'all' | 'verified' | 'pending'>('all')
  const [deleting, setDeleting]   = useState<string | null>(null)

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const { data, error } = await supabase
        .from('ngos')
        .select('id, name, location, registration_number, contact_email, verified, created_at')
        .order('created_at', { ascending: false })
      if (error) throw new Error(error.message)

      const needCounts = await Promise.all(
        (data ?? []).map(n =>
          supabase.from('donation_needs').select('*', { count: 'exact', head: true }).eq('ngo_id', n.id)
        )
      )

      setNgos((data ?? []).map((n, i) => ({ ...n, needs_count: needCounts[i].count ?? 0 })))
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Failed to load NGOs.')
    } finally {
      setLoading(false)
    }
  }

  async function verify(id: string) {
    try {
      const { error } = await supabase.from('ngos').update({ verified: true }).eq('id', id)
      if (error) throw new Error(error.message)
      setNgos(prev => prev.map(n => n.id === id ? { ...n, verified: true } : n))
      toast('NGO verified successfully.', 'success')
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to verify NGO.', 'error')
    }
  }

  async function reject(id: string, name: string) {
    if (!confirm(`Reject and remove NGO "${name}"? This cannot be undone.`)) return
    setDeleting(id)
    try {
      const { error } = await supabase.from('ngos').delete().eq('id', id)
      if (error) throw new Error(error.message)
      setNgos(prev => prev.filter(n => n.id !== id))
      toast(`"${name}" has been removed.`, 'info')
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to reject NGO.', 'error')
    } finally {
      setDeleting(null)
    }
  }

  async function deleteNgo(id: string, name: string) {
    if (!confirm(`Delete NGO "${name}"? This will remove the organisation and all its data. This cannot be undone.`)) return
    setDeleting(id)
    try {
      const { error } = await supabase.from('ngos').delete().eq('id', id)
      if (error) throw new Error(error.message)
      setNgos(prev => prev.filter(n => n.id !== id))
      toast(`"${name}" has been deleted.`, 'info')
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to delete NGO.', 'error')
    } finally {
      setDeleting(null)
    }
  }

  const total    = ngos.length
  const verified = ngos.filter(n => n.verified).length
  const pending  = ngos.filter(n => !n.verified).length

  const filtered = ngos.filter(n => {
    const matchFilter = filter === 'all' || (filter === 'verified' ? n.verified : !n.verified)
    const matchSearch = n.name.toLowerCase().includes(search.toLowerCase()) ||
                        n.location.toLowerCase().includes(search.toLowerCase())
    return matchFilter && matchSearch
  })

  if (loading) return (
    <div className="p-8 flex items-center justify-center min-h-64">
      <div className="w-7 h-7 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (loadError) return <PageError message={loadError} onRetry={load} />

  const topNgos = [...ngos].sort((a, b) => (b.needs_count ?? 0) - (a.needs_count ?? 0)).slice(0, 5)
  const topMax  = topNgos[0]?.needs_count ?? 1

  return (
    <div>

      {/* Sticky page header */}
      <div className="sticky top-0 z-10 bg-white px-8 py-5" style={{ borderBottom: '1px solid #E2E8F0' }}>
        <h1 className="font-heading font-bold text-[#164E63] text-2xl">NGO Management</h1>
        <p className="text-[#94A3B8] text-sm mt-0.5">Verify and manage registered organisations.</p>

        <div className="flex items-end gap-10 mt-5 pt-4" style={{ borderTop: '1px solid #F3F5F8' }}>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#0891B2]">{total}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Total organisations</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#16A34A]">{verified}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Verified</div>
          </div>
          <div>
            <div className={`font-mono font-bold text-[1.4rem] leading-none ${pending > 0 ? 'text-[#EF4444]' : 'text-[#94A3B8]'}`}>{pending}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Pending review</div>
          </div>
        </div>
      </div>

      {/* Body */}
      <div className="p-8">

        {/* Most active NGOs */}
        {topNgos.some(n => (n.needs_count ?? 0) > 0) && (
          <div className="bg-white rounded-2xl border border-[#E2E8F0] p-6 mb-6" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
            <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">Most Active Organisations</h2>
            <div className="space-y-3.5">
              {topNgos.filter(n => (n.needs_count ?? 0) > 0).map((ngo, i) => {
                const pct = Math.round(((ngo.needs_count ?? 0) / topMax) * 100)
                return (
                  <div key={ngo.id} className="flex items-center gap-4">
                    <span className="w-5 text-xs font-mono text-[#94A3B8] text-right shrink-0">{i + 1}</span>
                    <div className="w-40 shrink-0">
                      <p className="text-sm font-semibold text-[#164E63] truncate">{ngo.name}</p>
                      <p className="text-[#94A3B8] text-[10px] font-mono">{ngo.location}</p>
                    </div>
                    <div className="flex-1 h-2 rounded-full bg-[#F3F5F8] overflow-hidden">
                      <div className="h-full rounded-full bg-[#0891B2] transition-all" style={{ width: `${pct}%` }} />
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <span className="font-mono font-bold text-[#164E63] text-sm w-8 text-right">{ngo.needs_count}</span>
                      <span className="text-[#94A3B8] text-xs">needs</span>
                      {ngo.verified ? (
                        <BadgeCheck size={13} className="text-[#0891B2]" />
                      ) : (
                        <span className="text-[10px] font-semibold text-[#D97706] bg-amber-50 px-1.5 py-0.5 rounded-full border border-amber-200">pending</span>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        )}

        {/* Controls */}
        <div className="flex items-center gap-3 mb-5">
          <div className="relative flex-1 max-w-xs">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search NGOs…"
              className="w-full pl-9 pr-4 py-2.5 border border-[#E2E8F0] rounded-xl text-sm text-[#164E63] bg-white focus:outline-none focus:border-[#0891B2] transition-colors"
            />
          </div>
          <div className="flex gap-1 bg-white border border-[#E2E8F0] rounded-xl p-1">
            {(['all', 'verified', 'pending'] as const).map(f => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all cursor-pointer ${
                  filter === f ? 'bg-[#0891B2] text-white' : 'text-[#64748B] hover:text-[#164E63]'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-[#E2E8F0] overflow-hidden" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: '#F8FAFB', borderBottom: '1px solid #F1F5F9' }}>
                {['Organisation', 'Location', 'Reg. Number', 'Needs', 'Joined', 'Status', 'Actions'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-[11px] font-semibold text-[#64748B] uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr><td colSpan={7} className="px-5 py-10 text-center text-[#94A3B8] text-sm">No NGOs found.</td></tr>
              )}
              {filtered.map(ngo => (
                <tr key={ngo.id} className="hover:bg-[#F8FAFB] transition-colors" style={{ borderTop: '1px solid #F1F5F9' }}>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2.5">
                      <div className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0" style={{ background: '#EEF9FC' }}>
                        <Building2 size={13} className="text-[#0891B2]" />
                      </div>
                      <span className="font-semibold text-[#164E63]">{ngo.name}</span>
                      {ngo.verified && <BadgeCheck size={14} className="text-[#0891B2] shrink-0" />}
                    </div>
                  </td>
                  <td className="px-5 py-4 text-[#64748B]">{ngo.location}</td>
                  <td className="px-5 py-4 font-mono text-[#64748B] text-xs">{ngo.registration_number ?? '—'}</td>
                  <td className="px-5 py-4 font-mono font-bold text-[#164E63] text-sm">{ngo.needs_count}</td>
                  <td className="px-5 py-4 text-xs font-mono text-[#64748B]">{format(parseISO(ngo.created_at), 'dd MMM yyyy')}</td>
                  <td className="px-5 py-4">
                    {ngo.verified ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-green-50 text-green-700 border border-green-200">
                        <span className="w-1.5 h-1.5 rounded-full bg-green-500" /> Verified
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                        <span className="w-1.5 h-1.5 rounded-full bg-amber-400" /> Pending
                      </span>
                    )}
                  </td>
                  <td className="px-5 py-4">
                    {!ngo.verified ? (
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => verify(ngo.id)}
                          disabled={deleting === ngo.id}
                          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#0891B2] text-white text-xs font-semibold hover:bg-[#0E7490] transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                        >
                          <CheckCircle size={11} /> Verify
                        </button>
                        <button
                          onClick={() => reject(ngo.id, ngo.name)}
                          disabled={deleting === ngo.id}
                          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-[#EF4444] text-[#EF4444] text-xs font-semibold hover:bg-red-50 transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                        >
                          {deleting === ngo.id
                            ? <div className="w-3 h-3 border border-[#EF4444] border-t-transparent rounded-full animate-spin" />
                            : <Trash2 size={11} />
                          }
                          Reject
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => deleteNgo(ngo.id, ngo.name)}
                        disabled={deleting === ngo.id}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-[#FECACA] text-[#EF4444] text-xs font-semibold hover:bg-red-50 transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                      >
                        {deleting === ngo.id
                          ? <div className="w-3 h-3 border border-[#EF4444] border-t-transparent rounded-full animate-spin" />
                          : <Trash2 size={11} />
                        }
                        Delete
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

      </div>
    </div>
  )
}
