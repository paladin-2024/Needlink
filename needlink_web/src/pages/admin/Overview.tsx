import { useEffect, useState } from 'react'
import { CheckCircle, AlertCircle, TrendingUp } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import { format, subDays, parseISO, differenceInDays } from 'date-fns'
import { supabase } from '../../lib/supabase'
import { useToast } from '../../components/Toast'

interface KPI { ngos: number; donors: number; openNeeds: number; pledges: number }
interface PendingNgo { id: string; name: string; location: string; registration_number: string | null; created_at: string }
interface DayCount { label: string; date: string; pledges: number }
interface UrgentNeed { id: string; item_name: string; quantity_needed: number; quantity_pledged: number; deadline: string; ngos: { name: string } | null }
interface RecentDonor { id: string; full_name: string; created_at: string }

const ChartTooltip = ({ active, payload, label }: { active?: boolean; payload?: { value: number }[]; label?: string }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white border border-[#E2E8F0] rounded-xl px-3.5 py-2.5 shadow-lg">
      <p className="text-[#94A3B8] text-xs mb-0.5 font-mono">{label}</p>
      <p className="font-bold text-[#164E63] font-mono">{payload[0].value} pledges</p>
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

export default function Overview() {
  const { toast } = useToast()
  const [kpi, setKpi]                 = useState<KPI>({ ngos: 0, donors: 0, openNeeds: 0, pledges: 0 })
  const [chartData, setChart]         = useState<DayCount[]>([])
  const [pending, setPending]         = useState<PendingNgo[]>([])
  const [urgentNeeds, setUrgentNeeds] = useState<UrgentNeed[]>([])
  const [recentDonors, setRecent]     = useState<RecentDonor[]>([])
  const [loading, setLoading]         = useState(true)
  const [loadError, setLoadError]     = useState('')

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const [
        { count: ngos,        error: e1 },
        { count: donors,      error: e2 },
        { count: openNeeds,   error: e3 },
        { count: pledges,     error: e4 },
        { data: pledgeRows,   error: e5 },
        { data: pendingNgos,  error: e6 },
        { data: urgentData,   error: e7 },
        { data: recentData,   error: e8 },
      ] = await Promise.all([
        supabase.from('ngos').select('*', { count: 'exact', head: true }),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'donor'),
        supabase.from('donation_needs').select('*', { count: 'exact', head: true }).eq('status', 'open'),
        supabase.from('pledges').select('*', { count: 'exact', head: true }),
        supabase.from('pledges').select('created_at').gte('created_at', subDays(new Date(), 30).toISOString()),
        supabase.from('ngos').select('id, name, location, registration_number, created_at').eq('verified', false).order('created_at', { ascending: false }),
        supabase.from('donation_needs')
          .select('id, item_name, quantity_needed, quantity_pledged, deadline, ngos(name)')
          .eq('urgency', 'urgent').eq('status', 'open')
          .order('deadline', { ascending: true }).limit(6),
        supabase.from('profiles')
          .select('id, full_name, created_at')
          .eq('role', 'donor')
          .order('created_at', { ascending: false }).limit(7),
      ])

      if (e1 ?? e2 ?? e3 ?? e4 ?? e5 ?? e6 ?? e7 ?? e8) throw new Error('Failed to load data.')

      setKpi({ ngos: ngos ?? 0, donors: donors ?? 0, openNeeds: openNeeds ?? 0, pledges: pledges ?? 0 })
      setPending(pendingNgos ?? [])
      setUrgentNeeds((urgentData as UrgentNeed[]) ?? [])
      setRecent((recentData as RecentDonor[]) ?? [])

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

  const weekPledges  = chartData.slice(-7).reduce((s, d) => s + d.pledges, 0)
  const prevWeek     = chartData.slice(-14, -7).reduce((s, d) => s + d.pledges, 0)
  const weekDelta    = prevWeek > 0 ? Math.round(((weekPledges - prevWeek) / prevWeek) * 100) : null

  return (
    <div>

      {/* Sticky page header */}
      <div className="sticky top-0 z-10 bg-white px-8 py-5" style={{ borderBottom: '1px solid #E2E8F0' }}>
        <div className="flex items-start justify-between">
          <div>
            <h1 className="font-heading font-bold text-[#164E63] text-2xl">Overview</h1>
            <p className="text-[#94A3B8] text-sm mt-0.5">Platform health at a glance.</p>
          </div>
          {pending.length > 0 && (
            <span className="flex items-center gap-1.5 bg-[#FEF2F2] text-[#EF4444] text-xs font-semibold px-3 py-1.5 rounded-full border border-[#FECACA]">
              <span className="w-1.5 h-1.5 rounded-full bg-[#EF4444]" />
              {pending.length} pending approval{pending.length !== 1 ? 's' : ''}
            </span>
          )}
        </div>

        <div className="flex items-end gap-10 mt-5 pt-4" style={{ borderTop: '1px solid #F3F5F8' }}>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#0891B2]">{kpi.ngos.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">NGOs registered</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#16A34A]">{kpi.donors.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Donors</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#EA580C]">{kpi.openNeeds.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Open needs</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#7C3AED]">{kpi.pledges.toLocaleString()}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Total pledges</div>
          </div>
          {urgentNeeds.length > 0 && (
            <div>
              <div className="font-mono font-bold text-[1.4rem] leading-none text-[#EF4444]">{urgentNeeds.length}</div>
              <div className="text-[#94A3B8] text-xs mt-1.5">Urgent open needs</div>
            </div>
          )}
        </div>
      </div>

      {/* Body */}
      <div className="p-8 space-y-6">

        {/* Row 1: Chart + Pending panel */}
        <div className="grid gap-6" style={{ gridTemplateColumns: '1fr 380px' }}>

          {/* Pledge activity chart */}
          <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0]" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
            <div className="flex items-end justify-between mb-6">
              <div>
                <h2 className="font-heading font-bold text-[#164E63] text-base">Pledge Activity</h2>
                <p className="text-[#94A3B8] text-[11px] font-mono mt-0.5 uppercase tracking-wide">Last 30 days</p>
              </div>
              <div className="text-right">
                <div className="flex items-end gap-2 justify-end">
                  <p className="font-mono font-bold text-[#164E63] text-2xl leading-none">{weekPledges}</p>
                  {weekDelta !== null && (
                    <span className={`flex items-center gap-0.5 text-xs font-semibold mb-0.5 ${weekDelta >= 0 ? 'text-[#16A34A]' : 'text-[#EF4444]'}`}>
                      <TrendingUp size={12} />
                      {weekDelta >= 0 ? '+' : ''}{weekDelta}%
                    </span>
                  )}
                </div>
                <p className="text-[#94A3B8] text-[11px] mt-0.5">this week vs last</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={chartData} barSize={7}>
                <CartesianGrid vertical={false} stroke="#F0F4F8" />
                <XAxis dataKey="label" tick={{ fontSize: 10, fill: '#94A3B8', fontFamily: 'JetBrains Mono, monospace' }} tickLine={false} axisLine={false} interval={4} />
                <YAxis tick={{ fontSize: 10, fill: '#94A3B8', fontFamily: 'JetBrains Mono, monospace' }} tickLine={false} axisLine={false} allowDecimals={false} width={24} />
                <Tooltip content={<ChartTooltip />} cursor={{ fill: '#F3F5F8' }} />
                <Bar dataKey="pledges" fill="#0891B2" radius={[3, 3, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Pending approvals panel */}
          <div className="bg-white rounded-2xl border border-[#E2E8F0] flex flex-col overflow-hidden" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
            <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid #F1F5F9' }}>
              <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide">
                Pending Approvals
              </h2>
              {pending.length > 0 && (
                <span className="bg-[#EF4444] text-white text-xs font-bold font-mono px-2 py-0.5 rounded-full">{pending.length}</span>
              )}
            </div>

            {pending.length === 0 ? (
              <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">
                <div className="w-10 h-10 rounded-xl bg-[#F3F5F8] flex items-center justify-center mb-3">
                  <CheckCircle size={18} className="text-[#CBD5E1]" />
                </div>
                <p className="font-semibold text-[#94A3B8] text-sm">All caught up</p>
                <p className="text-[#CBD5E1] text-xs mt-1">No NGOs awaiting review.</p>
              </div>
            ) : (
              <div className="flex-1 overflow-y-auto">
                {pending.map((ngo, i) => (
                  <div key={ngo.id} className="px-5 py-4" style={{ borderTop: i > 0 ? '1px solid #F1F5F9' : undefined }}>
                    <div className="mb-2.5">
                      <p className="font-semibold text-[#164E63] text-sm leading-tight">{ngo.name}</p>
                      <p className="text-[#94A3B8] text-xs mt-0.5">
                        {ngo.location} · Submitted {format(parseISO(ngo.created_at), 'dd MMM yyyy')}
                      </p>
                      {ngo.registration_number && (
                        <p className="font-mono text-[10px] text-[#CBD5E1] mt-0.5">Reg: {ngo.registration_number}</p>
                      )}
                    </div>
                    <div className="flex gap-2">
                      <button onClick={() => verifyNgo(ngo.id)} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#0891B2] text-white text-xs font-semibold hover:bg-[#0E7490] transition-colors cursor-pointer">
                        <CheckCircle size={11} /> Verify
                      </button>
                      <button onClick={() => rejectNgo(ngo.id, ngo.name)} className="px-3 py-1.5 rounded-lg border border-[#EF4444] text-[#EF4444] text-xs font-semibold hover:bg-red-50 transition-colors cursor-pointer">
                        Reject
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

        </div>

        {/* Row 2: Urgent needs + Recent sign-ups */}
        <div className="grid gap-6" style={{ gridTemplateColumns: '1fr 380px' }}>

          {/* Urgent open needs */}
          <div className="bg-white rounded-2xl border border-[#E2E8F0] overflow-hidden" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
            <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom: '1px solid #F1F5F9' }}>
              <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide">
                Urgent Open Needs
              </h2>
              {urgentNeeds.length > 0 && (
                <span className="bg-[#FEF2F2] text-[#EF4444] text-xs font-bold font-mono px-2 py-0.5 rounded-full border border-[#FECACA]">
                  {urgentNeeds.length} urgent
                </span>
              )}
            </div>

            {urgentNeeds.length === 0 ? (
              <div className="px-6 py-10 text-center">
                <p className="text-[#94A3B8] text-sm font-semibold">No urgent needs</p>
                <p className="text-[#CBD5E1] text-xs mt-1">All urgent items are fulfilled or closed.</p>
              </div>
            ) : (
              <div>
                {urgentNeeds.map((need, i) => {
                  const pct = need.quantity_needed > 0 ? Math.round((need.quantity_pledged / need.quantity_needed) * 100) : 0
                  const daysLeft = differenceInDays(parseISO(need.deadline), new Date())
                  return (
                    <div key={need.id} className="px-6 py-4 flex items-center gap-4" style={{ borderTop: i > 0 ? '1px solid #F1F5F9' : undefined }}>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <p className="font-semibold text-[#164E63] text-sm truncate">{need.item_name}</p>
                          <span className="shrink-0 px-1.5 py-0.5 rounded text-[10px] font-bold bg-[#EF4444] text-white uppercase tracking-wide">URGENT</span>
                        </div>
                        <p className="text-[#94A3B8] text-xs truncate">{need.ngos?.name ?? '—'}</p>
                        <div className="flex items-center gap-2 mt-2">
                          <div className="flex-1 h-1.5 rounded-full bg-[#E2E8F0] overflow-hidden">
                            <div className="h-full rounded-full bg-[#EF4444]" style={{ width: `${pct}%` }} />
                          </div>
                          <span className="font-mono text-xs text-[#64748B] shrink-0">{pct}%</span>
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <p className={`font-mono text-xs font-bold ${daysLeft <= 3 ? 'text-[#EF4444]' : daysLeft <= 7 ? 'text-[#D97706]' : 'text-[#64748B]'}`}>
                          {daysLeft <= 0 ? 'Overdue' : `${daysLeft}d left`}
                        </p>
                        <p className="text-[#CBD5E1] text-[10px] mt-0.5 font-mono">{format(parseISO(need.deadline), 'dd MMM')}</p>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          {/* Recent donor sign-ups */}
          <div className="bg-white rounded-2xl border border-[#E2E8F0] overflow-hidden" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
            <div className="px-5 py-4" style={{ borderBottom: '1px solid #F1F5F9' }}>
              <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide">
                Recent Sign-ups
              </h2>
            </div>

            {recentDonors.length === 0 ? (
              <div className="px-5 py-10 text-center">
                <p className="text-[#94A3B8] text-sm">No donors yet.</p>
              </div>
            ) : (
              <div>
                {recentDonors.map((donor, i) => {
                  const daysAgo = differenceInDays(new Date(), parseISO(donor.created_at))
                  const timeLabel = daysAgo === 0 ? 'Today' : daysAgo === 1 ? 'Yesterday' : `${daysAgo}d ago`
                  return (
                    <div key={donor.id} className="flex items-center gap-3 px-5 py-3.5" style={{ borderTop: i > 0 ? '1px solid #F1F5F9' : undefined }}>
                      <div className="w-8 h-8 rounded-xl flex items-center justify-center text-xs font-bold text-white shrink-0" style={{ background: '#0E7490' }}>
                        {donor.full_name.charAt(0).toUpperCase()}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-semibold text-[#164E63] text-sm truncate">{donor.full_name}</p>
                        <p className="text-[#94A3B8] text-xs font-mono">{format(parseISO(donor.created_at), 'dd MMM yyyy')}</p>
                      </div>
                      <span className="text-[#94A3B8] text-xs font-mono shrink-0">{timeLabel}</span>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

        </div>
      </div>

    </div>
  )
}
