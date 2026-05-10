import { useEffect, useState, useCallback } from 'react'
import { Link } from 'react-router-dom'
import { Plus, Pencil, XCircle } from 'lucide-react'
import { format } from 'date-fns'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../components/Toast'
import type { DonationNeed } from '../../types'
import { NeedStatusBadge, UrgencyBadge } from '../../components/StatusBadge'

export default function NgoNeeds() {
  const { user } = useAuth()
  const { toast } = useToast()
  const [needs, setNeeds] = useState<DonationNeed[]>([])
  const [ngoId, setNgoId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [closing, setClosing] = useState<string | null>(null)

  const load = useCallback(async () => {
    if (!user) return
    const { data: ngoData } = await supabase.from('ngos').select('id').eq('admin_id', user.id).single()
    if (!ngoData) { setLoading(false); return }
    setNgoId(ngoData.id)
    const { data } = await supabase.from('donation_needs').select('*').eq('ngo_id', ngoData.id).order('created_at', { ascending: false })
    setNeeds(data ?? [])
    setLoading(false)
  }, [user])

  useEffect(() => { load() }, [load])

  async function handleClose(needId: string) {
    if (!confirm('Close this need? All pending pledges will be automatically rejected.')) return
    setClosing(needId)
    await supabase.from('donation_needs').update({ status: 'closed' }).eq('id', needId)
    await supabase.from('pledges').update({ status: 'rejected' }).eq('need_id', needId).eq('status', 'pending')
    toast('Need closed. Pending pledges have been rejected.', 'info')
    load()
    setClosing(null)
  }

  if (loading) return (
    <div className="bg-white rounded-2xl border border-[#A5F3FC] overflow-hidden">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 px-4 py-3 border-b border-[#E8F1F6]">
          <div className="skeleton h-4 w-40" />
          <div className="skeleton h-4 w-16 ml-4" />
          <div className="skeleton h-2 w-24 ml-auto" />
          <div className="skeleton h-4 w-16" />
          <div className="skeleton h-5 w-14" />
        </div>
      ))}
    </div>
  )

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="font-mono font-bold text-2xl text-[#164E63]">My Needs</h1>
          <p className="text-[#64748B] text-sm mt-1">{needs.length} needs posted</p>
        </div>
        <Link
          to="/ngo/needs/new"
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-[#EA580C] hover:bg-[#C2410C] text-white text-sm font-semibold rounded-xl transition-colors"
        >
          <Plus size={16} /> Post Need
        </Link>
      </div>

      {needs.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-[#A5F3FC]">
          <p className="text-[#64748B]">No needs posted yet.</p>
          <Link to="/ngo/needs/new" className="text-[#EA580C] font-medium text-sm hover:underline mt-2 block">Post your first need →</Link>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-[#A5F3FC] overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-[#E8F1F6] bg-[#F8FCFE]">
                {['Item', 'Category', 'Progress', 'Deadline', 'Status', ''].map(h => (
                  <th key={h} className="text-left px-4 py-3 font-mono text-xs font-semibold text-[#64748B] uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {needs.map(need => {
                const progress = Math.min(100, Math.round((need.quantity_pledged / need.quantity_needed) * 100))
                return (
                  <tr key={need.id} className="border-b border-[#E8F1F6] last:border-0 hover:bg-[#FAFEFF] transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <UrgencyBadge urgency={need.urgency} />
                        <span className="font-mono font-medium text-[#164E63]">{need.item_name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-[#64748B] capitalize">{need.category}</td>
                    <td className="px-4 py-3 min-w-[120px]">
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-1.5 bg-[#E8F1F6] rounded-full overflow-hidden">
                          <div className="h-full rounded-full bg-gradient-to-r from-[#0891B2] to-[#22D3EE]" style={{ width: `${progress}%` }} />
                        </div>
                        <span className="text-xs font-mono text-[#64748B]">{need.quantity_pledged}/{need.quantity_needed}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-[#64748B] font-mono text-xs">{format(new Date(need.deadline), 'MMM d, yy')}</td>
                    <td className="px-4 py-3"><NeedStatusBadge status={need.status} /></td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        {need.status !== 'closed' && (
                          <>
                            <Link to={`/ngo/needs/${need.id}/edit`} className="p-1.5 rounded-lg text-[#64748B] hover:text-[#0891B2] hover:bg-sky-50 transition-colors cursor-pointer" title="Edit">
                              <Pencil size={14} />
                            </Link>
                            <button
                              onClick={() => handleClose(need.id)}
                              disabled={closing === need.id}
                              className="p-1.5 rounded-lg text-[#64748B] hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer disabled:opacity-40"
                              title="Close need"
                            >
                              <XCircle size={14} />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
