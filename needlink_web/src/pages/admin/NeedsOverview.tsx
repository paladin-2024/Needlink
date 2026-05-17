import { useEffect, useState } from 'react'
import { Search, AlertCircle } from 'lucide-react'
import { format, parseISO } from 'date-fns'
import { supabase } from '../../lib/supabase'
import { NeedStatusBadge } from '../../components/StatusBadge'
import type { NeedStatus, ItemCategory } from '../../types'

interface Need {
  id: string
  item_name: string
  category: ItemCategory
  quantity_needed: number
  quantity_pledged: number
  status: NeedStatus
  urgency: 'normal' | 'urgent'
  deadline: string
  created_at: string
  ngos: { name: string } | null
}

const CATEGORY_COLORS: Record<ItemCategory, string> = {
  food:      '#EA580C',
  clothing:  '#7C3AED',
  medicine:  '#16A34A',
  supplies:  '#0891B2',
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

export default function NeedsOverview() {
  const [needs, setNeeds]         = useState<Need[]>([])
  const [loading, setLoading]     = useState(true)
  const [loadError, setLoadError] = useState('')
  const [search, setSearch]       = useState('')
  const [status, setStatus]       = useState<NeedStatus | 'all'>('all')
  const [category, setCategory]   = useState<ItemCategory | 'all'>('all')

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const { data, error } = await supabase
        .from('donation_needs')
        .select('id, item_name, category, quantity_needed, quantity_pledged, status, urgency, deadline, created_at, ngos(name)')
        .order('created_at', { ascending: false })
      if (error) throw new Error(error.message)
      setNeeds((data as Need[]) ?? [])
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Failed to load needs.')
    } finally {
      setLoading(false)
    }
  }

  const countBy = (s: NeedStatus) => needs.filter(n => n.status === s).length

  const filtered = needs.filter(n => {
    const matchStatus   = status === 'all'   || n.status === status
    const matchCategory = category === 'all' || n.category === category
    const matchSearch   = n.item_name.toLowerCase().includes(search.toLowerCase()) ||
                          (n.ngos?.name ?? '').toLowerCase().includes(search.toLowerCase())
    return matchStatus && matchCategory && matchSearch
  })

  if (loading) return (
    <div className="p-8 flex items-center justify-center min-h-64">
      <div className="w-7 h-7 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (loadError) return <PageError message={loadError} onRetry={load} />

  const catBreakdown = (['food', 'clothing', 'medicine', 'supplies'] as const).map(cat => ({
    cat,
    count:   needs.filter(n => n.category === cat).length,
    open:    needs.filter(n => n.category === cat && n.status === 'open').length,
    urgent:  needs.filter(n => n.category === cat && n.urgency === 'urgent').length,
    color:   CATEGORY_COLORS[cat],
  }))
  const catMax = Math.max(...catBreakdown.map(c => c.count), 1)

  return (
    <div>

      {/* Sticky page header */}
      <div className="sticky top-0 z-10 bg-white px-8 py-5" style={{ borderBottom: '1px solid #E2E8F0' }}>
        <h1 className="font-heading font-bold text-[#164E63] text-2xl">Needs Overview</h1>
        <p className="text-[#94A3B8] text-sm mt-0.5">All donation needs across every NGO.</p>

        <div className="flex items-end gap-10 mt-5 pt-4" style={{ borderTop: '1px solid #F3F5F8' }}>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#0891B2]">{needs.length.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Total needs</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#EA580C]">{countBy('open').toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Open</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#16A34A]">{countBy('matched').toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Matched</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#94A3B8]">{countBy('closed').toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Closed</div>
          </div>
        </div>
      </div>

      {/* Body */}
      <div className="p-8">

        {/* Category breakdown */}
        {needs.length > 0 && (
          <div className="bg-white rounded-2xl border border-[#E2E8F0] p-6 mb-6" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
            <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">Breakdown by Category</h2>
            <div className="grid grid-cols-4 gap-6">
              {catBreakdown.filter(c => c.count > 0).map(c => (
                <div key={c.cat}>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-semibold capitalize" style={{ color: c.color }}>{c.cat}</span>
                    <span className="font-mono font-bold text-[#164E63] text-sm">{c.count}</span>
                  </div>
                  <div className="h-2 rounded-full bg-[#F3F5F8] overflow-hidden mb-2">
                    <div className="h-full rounded-full transition-all" style={{ width: `${Math.round((c.count / catMax) * 100)}%`, background: c.color }} />
                  </div>
                  <div className="flex items-center gap-3 text-[10px] font-mono text-[#94A3B8]">
                    <span>{c.open} open</span>
                    {c.urgent > 0 && <span className="text-[#EF4444] font-semibold">{c.urgent} urgent</span>}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Controls */}
        <div className="flex flex-wrap items-center gap-3 mb-5">
          <div className="relative">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search needs…"
              className="pl-9 pr-4 py-2.5 border border-[#E2E8F0] rounded-xl text-sm text-[#164E63] bg-white focus:outline-none focus:border-[#0891B2] transition-colors w-56"
            />
          </div>
          <div className="flex gap-1 bg-white border border-[#E2E8F0] rounded-xl p-1">
            {(['all', 'open', 'matched', 'closed'] as const).map(s => (
              <button
                key={s}
                onClick={() => setStatus(s)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all cursor-pointer ${
                  status === s ? 'bg-[#0891B2] text-white' : 'text-[#64748B] hover:text-[#164E63]'
                }`}
              >
                {s}
              </button>
            ))}
          </div>
          <div className="flex gap-1 bg-white border border-[#E2E8F0] rounded-xl p-1">
            {(['all', 'food', 'clothing', 'medicine', 'supplies'] as const).map(c => (
              <button
                key={c}
                onClick={() => setCategory(c)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all cursor-pointer ${
                  category === c ? 'bg-[#0891B2] text-white' : 'text-[#64748B] hover:text-[#164E63]'
                }`}
              >
                {c}
              </button>
            ))}
          </div>
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-[#E2E8F0] overflow-hidden" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: '#F8FAFB', borderBottom: '1px solid #F1F5F9' }}>
                {['Item', 'NGO', 'Category', 'Progress', 'Status', 'Deadline'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-[11px] font-semibold text-[#64748B] uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr><td colSpan={6} className="px-5 py-10 text-center text-[#94A3B8] text-sm">No needs found.</td></tr>
              )}
              {filtered.map(need => {
                const pct = need.quantity_needed > 0
                  ? Math.round((need.quantity_pledged / need.quantity_needed) * 100)
                  : 0
                return (
                  <tr key={need.id} className="hover:bg-[#F8FAFB] transition-colors" style={{ borderTop: '1px solid #F1F5F9' }}>
                    <td className="px-5 py-4">
                      <div className="flex items-start gap-2.5">
                        <span
                          className="w-2 h-2 rounded-sm flex-shrink-0 mt-1.5"
                          style={{ background: CATEGORY_COLORS[need.category] }}
                        />
                        <div>
                          <p className="font-semibold text-[#164E63] leading-tight">{need.item_name}</p>
                          {need.urgency === 'urgent' && (
                            <span className="inline-block mt-0.5 px-1.5 py-0.5 rounded text-[10px] font-bold bg-[#EF4444] text-white uppercase tracking-wide">
                              URGENT
                            </span>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-[#64748B]">{need.ngos?.name ?? '—'}</td>
                    <td className="px-5 py-4">
                      <span
                        className="inline-block px-2 py-0.5 rounded-full text-xs font-semibold capitalize"
                        style={{ background: CATEGORY_COLORS[need.category] + '18', color: CATEGORY_COLORS[need.category] }}
                      >
                        {need.category}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-2">
                        <div className="w-24 h-1.5 rounded-full bg-[#E2E8F0] overflow-hidden">
                          <div
                            className="h-full rounded-full"
                            style={{ width: `${pct}%`, background: CATEGORY_COLORS[need.category] }}
                          />
                        </div>
                        <span className="font-mono text-xs text-[#64748B]">{pct}%</span>
                      </div>
                      <p className="text-[10px] font-mono text-[#94A3B8] mt-0.5">
                        {need.quantity_pledged}/{need.quantity_needed}
                      </p>
                    </td>
                    <td className="px-5 py-4"><NeedStatusBadge status={need.status} /></td>
                    <td className="px-5 py-4 text-xs font-mono text-[#64748B]">
                      {format(parseISO(need.deadline), 'dd MMM yyyy')}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>

        <p className="text-[#94A3B8] text-xs mt-4 text-center font-mono">
          {filtered.length} of {needs.length} needs
        </p>

      </div>
    </div>
  )
}
