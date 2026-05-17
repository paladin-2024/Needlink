import { useEffect, useState } from 'react'
import { Search, AlertCircle } from 'lucide-react'
import { format, parseISO } from 'date-fns'
import { supabase } from '../../lib/supabase'
import type { PledgeStatus } from '../../types'

interface Pledge {
  id: string
  quantity: number
  delivery_date: string
  status: PledgeStatus
  created_at: string
  profiles: { full_name: string } | null
  donation_needs: {
    item_name: string
    ngos: { name: string } | null
  } | null
}

const STATUS_STYLES: Record<PledgeStatus, { bg: string; text: string; dot: string }> = {
  pending:   { bg: 'bg-amber-50',  text: 'text-amber-700',  dot: 'bg-amber-400'  },
  confirmed: { bg: 'bg-green-50',  text: 'text-green-700',  dot: 'bg-green-500'  },
  rejected:  { bg: 'bg-red-50',    text: 'text-red-700',    dot: 'bg-red-500'    },
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

export default function PledgesOverview() {
  const [pledges, setPledges]     = useState<Pledge[]>([])
  const [loading, setLoading]     = useState(true)
  const [loadError, setLoadError] = useState('')
  const [search, setSearch]       = useState('')
  const [status, setStatus]       = useState<PledgeStatus | 'all'>('all')

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const { data, error } = await supabase
        .from('pledges')
        .select(`
          id, quantity, delivery_date, status, created_at,
          profiles(full_name),
          donation_needs(item_name, ngos(name))
        `)
        .order('created_at', { ascending: false })
        .limit(200)
      if (error) throw new Error(error.message)
      setPledges((data as Pledge[]) ?? [])
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Failed to load pledges.')
    } finally {
      setLoading(false)
    }
  }

  const countBy = (s: PledgeStatus) => pledges.filter(p => p.status === s).length

  const filtered = pledges.filter(p => {
    const matchStatus = status === 'all' || p.status === status
    const matchSearch =
      (p.profiles?.full_name ?? '').toLowerCase().includes(search.toLowerCase()) ||
      (p.donation_needs?.item_name ?? '').toLowerCase().includes(search.toLowerCase()) ||
      (p.donation_needs?.ngos?.name ?? '').toLowerCase().includes(search.toLowerCase())
    return matchStatus && matchSearch
  })

  if (loading) return (
    <div className="p-8 flex items-center justify-center min-h-64">
      <div className="w-7 h-7 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (loadError) return <PageError message={loadError} onRetry={load} />

  return (
    <div>

      {/* Sticky page header */}
      <div className="sticky top-0 z-10 bg-white px-8 py-5" style={{ borderBottom: '1px solid #E2E8F0' }}>
        <h1 className="font-heading font-bold text-[#164E63] text-2xl">Pledges Overview</h1>
        <p className="text-[#94A3B8] text-sm mt-0.5">System-wide pledge activity across all donors and NGOs.</p>

        <div className="flex items-end gap-10 mt-5 pt-4" style={{ borderTop: '1px solid #F3F5F8' }}>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#164E63]">{pledges.length.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Total pledges</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#D97706]">{countBy('pending').toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Pending</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#16A34A]">{countBy('confirmed').toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Confirmed</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#EF4444]">{countBy('rejected').toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Rejected</div>
          </div>
        </div>
      </div>

      {/* Body */}
      <div className="p-8">

        {/* Controls */}
        <div className="flex items-center gap-3 mb-5">
          <div className="relative">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search pledges…"
              className="pl-9 pr-4 py-2.5 border border-[#E2E8F0] rounded-xl text-sm text-[#164E63] bg-white focus:outline-none focus:border-[#0891B2] transition-colors w-56"
            />
          </div>
          <div className="flex gap-1 bg-white border border-[#E2E8F0] rounded-xl p-1">
            {(['all', 'pending', 'confirmed', 'rejected'] as const).map(s => (
              <button
                key={s}
                onClick={() => setStatus(s)}
                className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all cursor-pointer ${
                  status === s ? 'bg-[#0891B2] text-white' : 'text-[#64748B] hover:text-[#164E63]'
                }`}
              >
                {s}
              </button>
            ))}
          </div>
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-[#E2E8F0] overflow-hidden" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: '#F8FAFB', borderBottom: '1px solid #F1F5F9' }}>
                {['Donor', 'Item', 'NGO', 'Qty', 'Delivery', 'Pledged', 'Status'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-[11px] font-semibold text-[#64748B] uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr><td colSpan={7} className="px-5 py-10 text-center text-[#94A3B8] text-sm">No pledges found.</td></tr>
              )}
              {filtered.map(pledge => {
                const s = STATUS_STYLES[pledge.status]
                return (
                  <tr key={pledge.id} className="hover:bg-[#F8FAFB] transition-colors" style={{ borderTop: '1px solid #F1F5F9' }}>
                    <td className="px-5 py-4 font-semibold text-[#164E63]">{pledge.profiles?.full_name ?? '—'}</td>
                    <td className="px-5 py-4 text-[#64748B]">{pledge.donation_needs?.item_name ?? '—'}</td>
                    <td className="px-5 py-4 text-[#64748B]">{pledge.donation_needs?.ngos?.name ?? '—'}</td>
                    <td className="px-5 py-4 font-mono font-bold text-[#164E63]">{pledge.quantity}</td>
                    <td className="px-5 py-4 text-xs font-mono text-[#64748B]">{format(parseISO(pledge.delivery_date), 'dd MMM yyyy')}</td>
                    <td className="px-5 py-4 text-xs font-mono text-[#64748B]">{format(parseISO(pledge.created_at), 'dd MMM yyyy')}</td>
                    <td className="px-5 py-4">
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold capitalize ${s.bg} ${s.text}`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${s.dot}`} />
                        {pledge.status}
                      </span>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>

        <p className="text-[#94A3B8] text-xs mt-4 text-center font-mono">
          {filtered.length} of {pledges.length} pledges (latest 200)
        </p>

      </div>
    </div>
  )
}
