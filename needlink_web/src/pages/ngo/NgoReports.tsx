import { useEffect, useState } from 'react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts'
import { TrendingUp, Target, Truck, Package } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'

interface ReportData {
  matchRate: number
  avgDaysToMatch: number
  deliveryConfirmRate: number
  totalItemsDonated: number
  needsByCategory: { name: string; value: number }[]
  pledgesByStatus: { name: string; value: number }[]
}

const CATEGORY_COLORS = { food: '#EA580C', clothing: '#8B5CF6', medicine: '#EF4444', supplies: '#0891B2' }
const PLEDGE_COLORS: Record<string, string> = {
  confirmed: '#16A34A', pending: '#D97706', rejected: '#DC2626', matched: '#0891B2', in_transit: '#7C3AED'
}

export default function NgoReports() {
  const { user } = useAuth()
  const [data, setData] = useState<ReportData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return
    async function load() {
      const { data: ngoData } = await supabase.from('ngos').select('id').eq('admin_id', user!.id).single()
      if (!ngoData) { setLoading(false); return }

      const [needsRes, pledgesRes] = await Promise.all([
        supabase.from('donation_needs').select('*').eq('ngo_id', ngoData.id),
        supabase.from('pledges').select('*, donation_need:donation_needs!inner(ngo_id, quantity)').eq('donation_need.ngo_id', ngoData.id),
      ])

      const needs = needsRes.data ?? []
      const pledges = pledgesRes.data ?? []

      // Match rate
      const matched = needs.filter(n => n.status === 'matched' || n.status === 'closed').length
      const matchRate = needs.length ? Math.round((matched / needs.length) * 100) : 0

      // Avg days to match (approx: using deadline vs created_at as proxy)
      const matchedNeeds = needs.filter(n => n.status === 'matched' || n.status === 'closed')
      const avgDaysToMatch = matchedNeeds.length
        ? Math.round(matchedNeeds.reduce((sum, n) => {
            const diff = (new Date(n.deadline).getTime() - new Date(n.created_at).getTime()) / 86400000
            return sum + diff
          }, 0) / matchedNeeds.length)
        : 0

      // Delivery confirmation rate
      const nonRejected = pledges.filter(p => p.status !== 'rejected').length
      const confirmed = pledges.filter(p => p.status === 'confirmed').length
      const deliveryConfirmRate = nonRejected ? Math.round((confirmed / nonRejected) * 100) : 0

      // Total items donated
      const totalItemsDonated = pledges
        .filter(p => p.status === 'confirmed')
        .reduce((sum, p) => sum + p.quantity, 0)

      // Needs by category
      const catCounts: Record<string, number> = {}
      needs.forEach(n => { catCounts[n.category] = (catCounts[n.category] ?? 0) + 1 })
      const needsByCategory = Object.entries(catCounts).map(([name, value]) => ({ name, value }))

      // Pledges by status
      const statusCounts: Record<string, number> = {}
      pledges.forEach(p => { statusCounts[p.status] = (statusCounts[p.status] ?? 0) + 1 })
      const pledgesByStatus = Object.entries(statusCounts).map(([name, value]) => ({ name, value }))

      setData({ matchRate, avgDaysToMatch, deliveryConfirmRate, totalItemsDonated, needsByCategory, pledgesByStatus })
      setLoading(false)
    }
    load()
  }, [user])

  if (loading) return <div className="flex items-center justify-center h-64"><div className="w-8 h-8 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" /></div>
  if (!data) return <div className="text-center py-16 text-[#64748B]">No report data available yet.</div>

  const kpis = [
    { label: 'Match rate', value: `${data.matchRate}%`, icon: <Target size={20} />, color: 'text-green-600', bg: 'bg-green-50', desc: 'Needs matched or closed' },
    { label: 'Avg. days to match', value: `${data.avgDaysToMatch}d`, icon: <TrendingUp size={20} />, color: 'text-[#0891B2]', bg: 'bg-sky-50', desc: 'From post to matched' },
    { label: 'Delivery rate', value: `${data.deliveryConfirmRate}%`, icon: <Truck size={20} />, color: 'text-purple-600', bg: 'bg-purple-50', desc: 'Confirmed of non-rejected' },
    { label: 'Items donated', value: data.totalItemsDonated.toLocaleString(), icon: <Package size={20} />, color: 'text-[#EA580C]', bg: 'bg-orange-50', desc: 'Confirmed deliveries' },
  ]

  return (
    <div>
      <div className="mb-6">
        <h1 className="font-mono font-bold text-2xl text-[#164E63]">Reports</h1>
        <p className="text-[#64748B] text-sm mt-1">Impact overview for your NGO</p>
      </div>

      {/* KPIs */}
      <div className="bg-white rounded-2xl border border-[#A5F3FC] mb-8 divide-y divide-[#E8F1F6] lg:divide-y-0 lg:divide-x lg:flex">
        {kpis.map(({ label, value, icon, color, desc }) => (
          <div key={label} className="flex items-start gap-3 p-5 lg:flex-1">
            <span className={`${color} mt-0.5 shrink-0`}>{icon}</span>
            <div className="min-w-0">
              <p className="font-mono font-bold text-2xl text-[#164E63] leading-none">{value}</p>
              <p className="text-sm font-medium text-[#164E63] mt-1">{label}</p>
              <p className="text-xs text-[#94A3B8] mt-0.5">{desc}</p>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Needs by Category */}
        <div className="bg-white rounded-2xl border border-[#A5F3FC] p-5">
          <h2 className="font-mono font-semibold text-[#164E63] mb-4">Needs by Category</h2>
          {data.needsByCategory.length === 0 ? (
            <p className="text-sm text-[#64748B] text-center py-8">No data yet</p>
          ) : (
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={data.needsByCategory} barSize={32}>
                <XAxis dataKey="name" tick={{ fontSize: 12, fontFamily: 'Fira Code', fill: '#64748B' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fontFamily: 'Fira Code', fill: '#94A3B8' }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{ background: '#fff', border: '1px solid #A5F3FC', borderRadius: 12, fontSize: 12, fontFamily: 'Fira Code' }}
                  cursor={{ fill: '#ECFEFF' }}
                />
                <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                  {data.needsByCategory.map(entry => (
                    <Cell key={entry.name} fill={CATEGORY_COLORS[entry.name as keyof typeof CATEGORY_COLORS] ?? '#0891B2'} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Pledges by Status */}
        <div className="bg-white rounded-2xl border border-[#A5F3FC] p-5">
          <h2 className="font-mono font-semibold text-[#164E63] mb-4">Pledges by Status</h2>
          {data.pledgesByStatus.length === 0 ? (
            <p className="text-sm text-[#64748B] text-center py-8">No data yet</p>
          ) : (
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie data={data.pledgesByStatus} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} innerRadius={45} paddingAngle={3}>
                  {data.pledgesByStatus.map(entry => (
                    <Cell key={entry.name} fill={PLEDGE_COLORS[entry.name] ?? '#94A3B8'} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ background: '#fff', border: '1px solid #A5F3FC', borderRadius: 12, fontSize: 12, fontFamily: 'Fira Code' }}
                />
                <Legend iconType="circle" iconSize={8}
                  formatter={(v) => <span style={{ fontSize: 12, fontFamily: 'Fira Code', color: '#164E63' }}>{v}</span>}
                />
              </PieChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>
    </div>
  )
}
