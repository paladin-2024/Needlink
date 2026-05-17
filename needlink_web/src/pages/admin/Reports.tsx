import { useEffect, useState } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
  PieChart, Pie, Cell, Legend,
} from 'recharts'
import { format, subMonths, parseISO, startOfMonth } from 'date-fns'
import { AlertCircle } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import type { ItemCategory } from '../../types'

interface MonthData    { label: string; pledges: number }
interface CategoryData { name: string; value: number; color: string }
interface TopNgo       { name: string; needs: number }

const CATEGORY_COLORS: Record<ItemCategory, string> = {
  food:      '#EA580C',
  clothing:  '#7C3AED',
  medicine:  '#16A34A',
  supplies:  '#0891B2',
}

const ChartTooltip = ({ active, payload, label }: { active?: boolean; payload?: { value: number }[]; label?: string }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white border border-[#E8EDF2] rounded-xl px-3.5 py-2.5 text-sm shadow-lg">
      <p className="text-[#64748B] text-xs mb-0.5">{label}</p>
      <p className="font-bold text-[#164E63]">{payload[0].value}</p>
    </div>
  )
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

export default function Reports() {
  const [monthly, setMonthly]         = useState<MonthData[]>([])
  const [categories, setCategories]   = useState<CategoryData[]>([])
  const [topNgos, setTopNgos]         = useState<TopNgo[]>([])
  const [fulfillment, setFulfillment] = useState(0)
  const [loading, setLoading]         = useState(true)
  const [loadError, setLoadError]     = useState('')

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const [
        { data: pledges,  error: e1 },
        { data: needs,    error: e2 },
        { data: ngos,     error: e3 },
      ] = await Promise.all([
        supabase.from('pledges').select('created_at, status'),
        supabase.from('donation_needs').select('category, ngo_id'),
        supabase.from('ngos').select('id, name'),
      ])

      const firstError = e1 ?? e2 ?? e3
      if (firstError) throw new Error(firstError.message)

      // Monthly pledge chart — last 6 months
      const monthMap: Record<string, number> = {}
      pledges?.forEach(p => {
        const key = format(startOfMonth(parseISO(p.created_at)), 'yyyy-MM')
        monthMap[key] = (monthMap[key] || 0) + 1
      })
      const months: MonthData[] = []
      for (let i = 5; i >= 0; i--) {
        const d = subMonths(new Date(), i)
        const key = format(startOfMonth(d), 'yyyy-MM')
        months.push({ label: format(d, 'MMM yyyy'), pledges: monthMap[key] || 0 })
      }
      setMonthly(months)

      // Fulfillment rate
      const total     = pledges?.length ?? 0
      const confirmed = pledges?.filter(p => p.status === 'confirmed').length ?? 0
      setFulfillment(total > 0 ? Math.round((confirmed / total) * 100) : 0)

      // Category breakdown
      const catMap: Partial<Record<ItemCategory, number>> = {}
      needs?.forEach(n => { catMap[n.category as ItemCategory] = (catMap[n.category as ItemCategory] || 0) + 1 })
      setCategories(
        (Object.entries(catMap) as [ItemCategory, number][])
          .map(([name, value]) => ({ name, value, color: CATEGORY_COLORS[name] }))
          .sort((a, b) => b.value - a.value)
      )

      // Top NGOs by active needs count
      const ngoNeedsMap: Record<string, number> = {}
      needs?.forEach(n => { ngoNeedsMap[n.ngo_id] = (ngoNeedsMap[n.ngo_id] || 0) + 1 })
      const top = (ngos ?? [])
        .map(n => ({ name: n.name, needs: ngoNeedsMap[n.id] || 0 }))
        .sort((a, b) => b.needs - a.needs)
        .slice(0, 5)
      setTopNgos(top)
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Failed to load reports.')
    } finally {
      setLoading(false)
    }
  }

  if (loading) return (
    <div className="p-8 flex items-center justify-center min-h-64">
      <div className="w-7 h-7 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (loadError) return <PageError message={loadError} onRetry={load} />

  return (
    <div className="p-8 max-w-6xl">
      <div className="mb-7">
        <h1 className="font-heading font-bold text-[#164E63] text-2xl">Reports</h1>
        <p className="text-[#64748B] text-sm mt-1">Platform-wide analytics and trends.</p>
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-3 gap-4 mb-7">
        <div className="bg-white rounded-2xl p-5 border border-[#E8EDF2]" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
          <p className="text-[#64748B] text-xs font-semibold uppercase tracking-wide mb-1">Fulfillment Rate</p>
          <p className="font-heading font-bold text-3xl text-[#16A34A]">{fulfillment}%</p>
          <p className="text-[#94A3B8] text-xs mt-1">Confirmed / total pledges</p>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-[#E8EDF2]" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
          <p className="text-[#64748B] text-xs font-semibold uppercase tracking-wide mb-1">Categories</p>
          <p className="font-heading font-bold text-3xl text-[#0891B2]">{categories.length}</p>
          <p className="text-[#94A3B8] text-xs mt-1">Active donation types</p>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-[#E8EDF2]" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
          <p className="text-[#64748B] text-xs font-semibold uppercase tracking-wide mb-1">This Month</p>
          <p className="font-heading font-bold text-3xl text-[#7C3AED]">{monthly[monthly.length - 1]?.pledges ?? 0}</p>
          <p className="text-[#94A3B8] text-xs mt-1">Pledges so far</p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-6 mb-6">
        {/* Monthly growth */}
        <div className="bg-white rounded-2xl p-6 border border-[#E8EDF2]" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
          <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">Monthly Pledge Growth</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={monthly} barSize={20}>
              <CartesianGrid vertical={false} stroke="#F0F4F8" />
              <XAxis dataKey="label" tick={{ fontSize: 10, fill: '#94A3B8', fontFamily: 'JetBrains Mono, monospace' }} tickLine={false} axisLine={false} />
              <YAxis tick={{ fontSize: 10, fill: '#94A3B8', fontFamily: 'JetBrains Mono, monospace' }} tickLine={false} axisLine={false} allowDecimals={false} width={24} />
              <Tooltip content={<ChartTooltip />} cursor={{ fill: '#F0FDFF' }} />
              <Bar dataKey="pledges" fill="#0891B2" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Category breakdown */}
        <div className="bg-white rounded-2xl p-6 border border-[#E8EDF2]" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
          <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">Category Breakdown</h2>
          {categories.length > 0 ? (
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie data={categories} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={75} innerRadius={40}>
                  {categories.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                </Pie>
                <Tooltip formatter={(v, n) => [v, String(n)]} contentStyle={{ borderRadius: 12, border: '1px solid #E8EDF2', fontSize: 12 }} />
                <Legend iconType="circle" iconSize={8} formatter={v => <span style={{ fontSize: 11, color: '#64748B', textTransform: 'capitalize' }}>{String(v)}</span>} />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-48 text-[#94A3B8] text-sm">No data yet</div>
          )}
        </div>
      </div>

      {/* Top NGOs */}
      <div className="bg-white rounded-2xl p-6 border border-[#E8EDF2]" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
        <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">Top NGOs by Active Needs</h2>
        <div className="space-y-3">
          {topNgos.length === 0 && <p className="text-[#94A3B8] text-sm text-center py-4">No data yet.</p>}
          {topNgos.map((ngo, i) => {
            const max = topNgos[0]?.needs || 1
            const pct = Math.round((ngo.needs / max) * 100)
            return (
              <div key={ngo.name} className="flex items-center gap-4">
                <span className="w-5 text-xs font-mono text-[#94A3B8] text-right flex-shrink-0">{i + 1}</span>
                <span className="w-40 text-sm font-semibold text-[#164E63] truncate">{ngo.name}</span>
                <div className="flex-1 h-2 rounded-full bg-[#E8EDF2] overflow-hidden">
                  <div className="h-full rounded-full" style={{ width: `${pct}%`, background: 'linear-gradient(90deg, #0891B2, #0E7490)' }} />
                </div>
                <span className="w-8 text-xs font-mono font-bold text-[#164E63] text-right">{ngo.needs}</span>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
