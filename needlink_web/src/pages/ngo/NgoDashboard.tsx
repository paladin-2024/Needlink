import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { Package, ClipboardList, CheckCircle2, TrendingUp, Plus } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'
import type { Ngo, DonationNeed, Pledge } from '../../types'

interface Stats {
  totalNeeds: number
  openNeeds: number
  matchedNeeds: number
  pendingPledges: number
  confirmedDeliveries: number
}

export default function NgoDashboard() {
  const { user } = useAuth()
  const [ngo, setNgo] = useState<Ngo | null>(null)
  const [stats, setStats] = useState<Stats | null>(null)
  const [recentNeeds, setRecentNeeds] = useState<DonationNeed[]>([])
  const [recentPledges, setRecentPledges] = useState<Pledge[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return
    async function load() {
      const { data: ngoData } = await supabase.from('ngos').select('*').eq('admin_id', user!.id).single()
      if (!ngoData) { setLoading(false); return }
      setNgo(ngoData)

      const [needsRes, pledgesRes, deliveriesRes] = await Promise.all([
        supabase.from('donation_needs').select('*').eq('ngo_id', ngoData.id),
        supabase.from('pledges').select('*, donation_need:donation_needs!inner(ngo_id)').eq('donation_need.ngo_id', ngoData.id),
        supabase.from('deliveries').select('id', { count: 'exact' }),
      ])

      const needs: DonationNeed[] = needsRes.data ?? []
      const pledges: Pledge[] = pledgesRes.data ?? []

      setStats({
        totalNeeds: needs.length,
        openNeeds: needs.filter(n => n.status === 'open').length,
        matchedNeeds: needs.filter(n => n.status === 'matched' || n.status === 'closed').length,
        pendingPledges: pledges.filter(p => p.status === 'pending').length,
        confirmedDeliveries: deliveriesRes.count ?? 0,
      })

      setRecentNeeds(needs.sort((a, b) => b.created_at.localeCompare(a.created_at)).slice(0, 3))
      setRecentPledges(pledges.sort((a, b) => b.created_at.localeCompare(a.created_at)).slice(0, 5))
      setLoading(false)
    }
    load()
  }, [user])

  if (loading) return <div className="flex items-center justify-center h-64"><div className="w-8 h-8 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" /></div>

  if (!ngo) return (
    <div className="text-center py-16">
      <p className="text-[#64748B] mb-3">No NGO profile found.</p>
      <p className="text-sm text-[#94A3B8]">Please contact support.</p>
    </div>
  )

  const statCards = [
    { label: 'Open needs', value: stats?.openNeeds ?? 0, icon: <Package size={20} />, color: 'text-[#0891B2]', bg: 'bg-sky-50' },
    { label: 'Matched needs', value: stats?.matchedNeeds ?? 0, icon: <CheckCircle2 size={20} />, color: 'text-green-600', bg: 'bg-green-50' },
    { label: 'Pending pledges', value: stats?.pendingPledges ?? 0, icon: <ClipboardList size={20} />, color: 'text-amber-600', bg: 'bg-amber-50' },
    { label: 'Confirmed deliveries', value: stats?.confirmedDeliveries ?? 0, icon: <TrendingUp size={20} />, color: 'text-purple-600', bg: 'bg-purple-50' },
  ]

  return (
    <div>
      <div className="flex items-start justify-between gap-3 mb-6 flex-wrap">
        <div>
          <h1 className="font-mono font-bold text-2xl text-[#164E63]">{ngo.name}</h1>
          <p className="text-[#64748B] text-sm mt-1">{ngo.location} · {ngo.contact_email}</p>
        </div>
        <Link
          to="/ngo/needs/new"
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-[#EA580C] hover:bg-[#C2410C] text-white text-sm font-semibold rounded-xl transition-colors"
        >
          <Plus size={16} /> Post Need
        </Link>
      </div>

      {/* Stats */}
      <div className="bg-white rounded-2xl border border-[#A5F3FC] mb-8 divide-y divide-[#E8F1F6] lg:divide-y-0 lg:divide-x lg:flex">
        {statCards.map(({ label, value, icon, color }) => (
          <div key={label} className="flex items-center gap-4 p-4 lg:flex-1">
            <span className={`${color} shrink-0`}>{icon}</span>
            <div className="min-w-0">
              <p className="font-mono font-bold text-xl text-[#164E63] leading-none">{value}</p>
              <p className="text-xs text-[#64748B] mt-1 truncate">{label}</p>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Needs */}
        <div className="bg-white rounded-2xl border border-[#A5F3FC] p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-mono font-semibold text-[#164E63]">Recent Needs</h2>
            <Link to="/ngo/needs" className="text-xs text-[#0891B2] hover:underline">View all</Link>
          </div>
          {recentNeeds.length === 0 ? (
            <p className="text-sm text-[#64748B] text-center py-4">No needs posted yet.</p>
          ) : (
            <div className="space-y-3">
              {recentNeeds.map(n => (
                <Link key={n.id} to={`/ngo/needs/${n.id}`} className="flex items-center justify-between p-3 rounded-xl bg-[#ECFEFF] hover:bg-[#E0F9FF] transition-colors">
                  <div>
                    <p className="text-sm font-medium text-[#164E63] font-mono">{n.item_name}</p>
                    <p className="text-xs text-[#64748B]">{n.quantity_pledged}/{n.quantity_needed} pledged</p>
                  </div>
                  <span className={`text-xs font-mono font-semibold px-2 py-0.5 rounded-full ${n.urgency === 'urgent' ? 'bg-red-100 text-red-700' : 'bg-sky-100 text-sky-700'}`}>
                    {n.status}
                  </span>
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Recent Pledges */}
        <div className="bg-white rounded-2xl border border-[#A5F3FC] p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-mono font-semibold text-[#164E63]">Recent Pledges</h2>
            <Link to="/ngo/pledges" className="text-xs text-[#0891B2] hover:underline">View all</Link>
          </div>
          {recentPledges.length === 0 ? (
            <p className="text-sm text-[#64748B] text-center py-4">No pledges yet.</p>
          ) : (
            <div className="space-y-2">
              {recentPledges.map(p => (
                <div key={p.id} className="flex items-center justify-between p-3 rounded-xl bg-[#ECFEFF]">
                  <div>
                    <p className="text-sm font-medium text-[#164E63] font-mono">{p.quantity} units</p>
                  </div>
                  <span className={`text-xs font-mono font-semibold px-2 py-0.5 rounded-full ${
                    p.status === 'confirmed' ? 'bg-green-100 text-green-700' :
                    p.status === 'pending' ? 'bg-amber-100 text-amber-700' :
                    p.status === 'rejected' ? 'bg-red-100 text-red-700' : 'bg-sky-100 text-sky-700'
                  }`}>
                    {p.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
