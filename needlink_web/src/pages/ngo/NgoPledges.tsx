import { useEffect, useState, useCallback } from 'react'
import { format } from 'date-fns'
import { CheckCircle2, XCircle, Calendar, Package } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../components/Toast'
import type { Pledge } from '../../types'
import { PledgeStatusBadge } from '../../components/StatusBadge'

export default function NgoPledges() {
  const { user } = useAuth()
  const { toast } = useToast()
  const [pledges, setPledges] = useState<Pledge[]>([])
  const [ngoId, setNgoId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [acting, setActing] = useState<string | null>(null)

  const load = useCallback(async () => {
    if (!user) return
    const { data: ngoData } = await supabase.from('ngos').select('id').eq('admin_id', user.id).single()
    if (!ngoData) { setLoading(false); return }
    setNgoId(ngoData.id)

    const { data } = await supabase
      .from('pledges')
      .select('*, donation_need:donation_needs!inner(*, ngo_id), donor:profiles!donor_id(full_name, phone)')
      .eq('donation_need.ngo_id', ngoData.id)
      .order('created_at', { ascending: false })

    setPledges(data ?? [])
    setLoading(false)
  }, [user])

  useEffect(() => {
    load()
    if (!ngoId) return
    const channel = supabase
      .channel('ngo_pledges')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'pledges' }, load)
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [load, ngoId])

  async function handleAction(pledge: Pledge, action: 'confirmed' | 'rejected') {
    setActing(pledge.id)
    await supabase.from('pledges').update({ status: action }).eq('id', pledge.id)

    if (action === 'confirmed') {
      await supabase.from('deliveries').insert({
        pledge_id: pledge.id,
        confirmed_by: user!.id,
      })
    } else if (action === 'rejected') {
      const { data: need } = await supabase.from('donation_needs').select('quantity_pledged, status').eq('id', pledge.need_id).single()
      if (need) {
        const newPledged = Math.max(0, need.quantity_pledged - pledge.quantity)
        const newStatus = need.status === 'matched' ? 'open' : need.status
        await supabase.from('donation_needs').update({ quantity_pledged: newPledged, status: newStatus }).eq('id', pledge.need_id)
      }
    }

    if (action === 'confirmed') {
      toast('Pledge confirmed. Delivery record created.', 'success')
    } else {
      toast('Pledge rejected and quantity adjusted.', 'info')
    }
    load()
    setActing(null)
  }

  if (loading) return (
    <div className="space-y-3">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="bg-white rounded-2xl border border-[#A5F3FC] p-4">
          <div className="flex justify-between mb-2">
            <div className="skeleton h-5 w-36" />
            <div className="skeleton h-5 w-20" />
          </div>
          <div className="skeleton h-4 w-48 mb-3" />
          <div className="flex gap-3">
            <div className="skeleton h-4 w-24" />
            <div className="skeleton h-4 w-32" />
          </div>
        </div>
      ))}
    </div>
  )

  const pending = pledges.filter(p => p.status === 'pending')
  const others = pledges.filter(p => p.status !== 'pending')

  return (
    <div>
      <div className="mb-6">
        <h1 className="font-mono font-bold text-2xl text-[#164E63]">Pledges</h1>
        <p className="text-[#64748B] text-sm mt-1">
          {pending.length} pending · {pledges.length} total
        </p>
      </div>

      {pending.length > 0 && (
        <div className="mb-6">
          <h2 className="font-mono font-semibold text-sm text-[#EA580C] mb-3 uppercase tracking-wide">⚡ Needs action</h2>
          <div className="space-y-3">
            {pending.map(pledge => <PledgeRow key={pledge.id} pledge={pledge} acting={acting} onAction={handleAction} />)}
          </div>
        </div>
      )}

      {others.length > 0 && (
        <div>
          <h2 className="font-mono font-semibold text-sm text-[#64748B] mb-3 uppercase tracking-wide">History</h2>
          <div className="space-y-2">
            {others.map(pledge => <PledgeRow key={pledge.id} pledge={pledge} acting={acting} onAction={handleAction} />)}
          </div>
        </div>
      )}

      {pledges.length === 0 && (
        <div className="text-center py-16 bg-white rounded-2xl border border-[#A5F3FC]">
          <p className="text-[#64748B]">No pledges yet.</p>
        </div>
      )}
    </div>
  )
}

function PledgeRow({ pledge, acting, onAction }: {
  pledge: Pledge
  acting: string | null
  onAction: (p: Pledge, a: 'confirmed' | 'rejected') => void
}) {
  const isPending = pledge.status === 'pending'
  return (
    <div className={`bg-white rounded-2xl border p-4 transition-colors ${isPending ? 'border-amber-200 shadow-sm' : 'border-[#A5F3FC]'}`}>
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <p className="font-mono font-semibold text-[#164E63]">
              {(pledge as any).donor?.full_name ?? 'Donor'}
            </p>
            {(pledge as any).donor?.phone && (
              <span className="text-xs text-[#64748B]">· {(pledge as any).donor.phone}</span>
            )}
          </div>
          <p className="text-sm text-[#64748B]">
            {pledge.donation_need?.item_name} — <strong className="text-[#164E63]">{pledge.quantity} units</strong>
          </p>
          <div className="flex flex-wrap gap-3 mt-2 text-xs text-[#64748B]">
            <span className="flex items-center gap-1"><Calendar size={11} /> Delivery: {format(new Date(pledge.delivery_date), 'MMM d, yyyy')}</span>
            <span className="flex items-center gap-1"><Package size={11} /> Pledged {format(new Date(pledge.created_at), 'MMM d')}</span>
          </div>
          {pledge.notes && <p className="text-xs text-[#64748B] italic mt-1">"{pledge.notes}"</p>}
        </div>

        <div className="flex items-center gap-2">
          <PledgeStatusBadge status={pledge.status} />
          {isPending && (
            <>
              <button
                onClick={() => onAction(pledge, 'confirmed')}
                disabled={acting === pledge.id}
                aria-label="Confirm delivery"
                className="p-2 rounded-xl bg-green-50 text-green-600 hover:bg-green-100 disabled:opacity-40 transition-colors cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500"
              >
                <CheckCircle2 size={18} />
              </button>
              <button
                onClick={() => onAction(pledge, 'rejected')}
                disabled={acting === pledge.id}
                aria-label="Reject pledge"
                className="p-2 rounded-xl bg-red-50 text-red-500 hover:bg-red-100 disabled:opacity-40 transition-colors cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-400"
              >
                <XCircle size={18} />
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
