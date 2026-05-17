import { useEffect, useState } from 'react'
import { Building2, Users, Package, ArrowLeftRight, CheckCircle, Clock, AlertCircle } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import { format, subDays, parseISO } from 'date-fns'
import { supabase } from '../../lib/supabase'
import { useToast } from '../../components/Toast'

interface KPI { ngos: number; donors: number; openNeeds: number; pledges: number }
interface PendingNgo { id: string; name: string; location: string; registration_number: string | null; created_at: string }
interface DayCount { label: string; date: string; pledges: number }

function KpiCard({ icon: Icon, label, value, color }: { icon: React.ComponentType<{ size?: number; className?: string; style?: React.CSSProperties }>; label: string; value: number; color: string }) {
  return (
    <div className="bg-white rounded-2xl p-5 border border-[#E8EDF2]" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
      <div className="flex items-center justify-between mb-3">
        <p className="text-[#64748B] text-xs font-semibold uppercase tracking-wide">{label}</p>
        <div className="w-8 h-8 rounded-xl flex items-center justify-center" style={{ background: color + '18' }}>
          <Icon size={15} style={{ color }} />
        </div>
      </div>
      <p className="font-heading font-bold text-[#164E63] text-3xl">{value.toLocaleString()}</p>
    </div>
  )
}

const ChartTooltip = ({ active, payload, label }: { active?: boolean; payload?: { value: number }[]; label?: string }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white border border-[#E8EDF2] rounded-xl px-3.5 py-2.5 text-sm shadow-lg">
      <p className="text-[#64748B] text-xs mb-0.5">{label}</p>
      <p className="font-bold text-[#164E63]">{payload[0].value} pledges</p>
    </div>
  )
}

function PageError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="p-8 flex flex-col items-center justify-center min-h-64 gap-4">
      <AlertCircle size={28} className="text-[#EF4444]" />
      <p className="text-[#164E63] font-semibold">{message}</p>
      <button
        onClick={onRetry}
        className="px-4 py-2 rounded-xl bg-[#0891B2] text-white text-sm font-semibold cursor-pointer hover:bg-[#0E7490] transition-colors"
      >
        Retry
      </button>
    </div>
  )
}

export default function Overview() {
  const { toast } = useToast()
  const [kpi, setKpi]           = useState<KPI>({ ngos: 0, donors: 0, openNeeds: 0, pledges: 0 })
  const [chartData, setChart]   = useState<DayCount[]>([])
  const [pending, setPending]   = useState<PendingNgo[]>([])
  const [loading, setLoading]   = useState(true)
  const [loadError, setLoadError] = useState('')

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const [
        { count: ngos,      error: e1 },
        { count: donors,    error: e2 },
        { count: openNeeds, error: e3 },
        { count: pledges,   error: e4 },
        { data: pledgeRows, error: e5 },
        { data: pendingNgos, error: e6 },
      ] = await Promise.all([
        supabase.from('ngos').select('*', { count: 'exact', head: true }),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'donor'),
        supabase.from('donation_needs').select('*', { count: 'exact', head: true }).eq('status', 'open'),
        supabase.from('pledges').select('*', { count: 'exact', head: true }),
        supabase.from('pledges').select('created_at').gte('created_at', subDays(new Date(), 30).toISOString()),
        supabase.from('ngos').select('id, name, location, registration_number, created_at').eq('verified', false).order('created_at', { ascending: false }),
      ])

      const firstError = e1 ?? e2 ?? e3 ?? e4 ?? e5 ?? e6
      if (firstError) throw new Error(firstError.message)

      setKpi({ ngos: ngos ?? 0, donors: donors ?? 0, openNeeds: openNeeds ?? 0, pledges: pledges ?? 0 })
      setPending(pendingNgos ?? [])

      const map: Record<string, number> = {}
      pledgeRows?.forEach(p => { const d = p.created_at.slice(0, 10); map[d] = (map[d] || 0) + 1 })
      const days: DayCount[] = []
      for (let i = 29; i >= 0; i--) {
        const d = subDays(new Date(), i)
        const key = format(d, 'yyyy-MM-dd')
        days.push({ date: key, label: format(d, 'MMM d'), pledges: map[key] || 0 })
      }
      setChart(days)
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Failed to load overview data.')
    } finally {
      setLoading(false)
    }
  }

  async function verifyNgo(id: string) {
    try {
      const { error } = await supabase.from('ngos').update({ verified: true }).eq('id', id)
      if (error) throw new Error(error.message)
      setPending(p => p.filter(n => n.id !== id))
      toast('NGO verified successfully.', 'success')
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to verify NGO.', 'error')
    }
  }

  async function rejectNgo(id: string, name: string) {
    if (!confirm(`Reject and delete NGO "${name}"? This cannot be undone.`)) return
    try {
      const { error } = await supabase.from('ngos').delete().eq('id', id)
      if (error) throw new Error(error.message)
      setPending(p => p.filter(n => n.id !== id))
      toast(`"${name}" has been removed.`, 'info')
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to reject NGO.', 'error')
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
        <h1 className="font-heading font-bold text-[#164E63] text-2xl">Overview</h1>
        <p className="text-[#64748B] text-sm mt-1">Platform health at a glance.</p>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <KpiCard icon={Building2}      label="Total NGOs"    value={kpi.ngos}      color="#0891B2" />
        <KpiCard icon={Users}          label="Total Donors"  value={kpi.donors}    color="#16A34A" />
        <KpiCard icon={Package}        label="Open Needs"    value={kpi.openNeeds} color="#EA580C" />
        <KpiCard icon={ArrowLeftRight} label="Total Pledges" value={kpi.pledges}   color="#7C3AED" />
      </div>

      {/* Chart */}
      <div className="bg-white rounded-2xl p-6 border border-[#E8EDF2] mb-6" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
        <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">
          Pledge Activity — Last 30 Days
        </h2>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={chartData} barSize={8}>
            <CartesianGrid vertical={false} stroke="#F0F4F8" />
            <XAxis dataKey="label" tick={{ fontSize: 10, fill: '#94A3B8', fontFamily: 'JetBrains Mono, monospace' }} tickLine={false} axisLine={false} interval={4} />
            <YAxis tick={{ fontSize: 10, fill: '#94A3B8', fontFamily: 'JetBrains Mono, monospace' }} tickLine={false} axisLine={false} allowDecimals={false} width={24} />
            <Tooltip content={<ChartTooltip />} cursor={{ fill: '#F0FDFF' }} />
            <Bar dataKey="pledges" fill="#0891B2" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Pending approvals */}
      {pending.length > 0 ? (
        <div className="bg-white rounded-2xl border border-[#E8EDF2] overflow-hidden" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
          <div className="flex items-center justify-between px-6 py-4 border-b border-[#E8EDF2]">
            <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide">
              Pending NGO Approvals
            </h2>
            <span className="bg-[#EF4444] text-white text-xs font-bold px-2 py-0.5 rounded-full">{pending.length}</span>
          </div>
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-[#F8FAFC]">
                {['NGO Name', 'Location', 'Reg. Number', 'Submitted', 'Actions'].map(h => (
                  <th key={h} className="px-5 py-3 text-left text-[11px] font-semibold text-[#64748B] uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {pending.map(ngo => (
                <tr key={ngo.id} className="border-t border-[#E8EDF2] hover:bg-[#F8FAFC] transition-colors">
                  <td className="px-5 py-3.5 font-semibold text-[#164E63]">{ngo.name}</td>
                  <td className="px-5 py-3.5 text-[#64748B]">{ngo.location}</td>
                  <td className="px-5 py-3.5 font-mono text-[#64748B] text-xs">{ngo.registration_number ?? '—'}</td>
                  <td className="px-5 py-3.5 text-[#64748B] text-xs font-mono">{format(parseISO(ngo.created_at), 'dd MMM yyyy')}</td>
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-2">
                      <button onClick={() => verifyNgo(ngo.id)} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#0891B2] text-white text-xs font-semibold hover:bg-[#0E7490] transition-colors cursor-pointer">
                        <CheckCircle size={12} /> Verify
                      </button>
                      <button onClick={() => rejectNgo(ngo.id, ngo.name)} className="px-3 py-1.5 rounded-lg border border-[#EF4444] text-[#EF4444] text-xs font-semibold hover:bg-red-50 transition-colors cursor-pointer">
                        Reject
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-[#E8EDF2] p-8 text-center" style={{ boxShadow: '0 1px 6px rgba(8,145,178,0.06)' }}>
          <Clock size={28} className="text-[#CBD5E1] mx-auto mb-3" />
          <p className="font-heading font-bold text-[#164E63] text-sm">No pending approvals</p>
          <p className="text-[#64748B] text-xs mt-1">All NGO registrations have been reviewed.</p>
        </div>
      )}
    </div>
  )
}
