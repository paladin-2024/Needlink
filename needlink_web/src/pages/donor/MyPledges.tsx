import { useEffect, useState } from 'react'
import { format } from 'date-fns'
import { Calendar, Package } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'
import type { Pledge } from '../../types'
import { PledgeStatusBadge } from '../../components/StatusBadge'

export default function MyPledges() {
  const { user } = useAuth()
  const [pledges, setPledges] = useState<Pledge[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return

    const load = async () => {
      const { data } = await supabase
        .from('pledges')
        .select('*, donation_need:donation_needs(*, ngo:ngos(name, location))')
        .eq('donor_id', user.id)
        .order('created_at', { ascending: false })
      setPledges(data ?? [])
      setLoading(false)
    }
    load()

    const channel = supabase
      .channel('my_pledges')
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'pledges', filter: `donor_id=eq.${user.id}` }, load)
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [user])

  if (loading) return (
    <div className="space-y-3">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="bg-white rounded-2xl border border-[#A5F3FC] p-5">
          <div className="flex justify-between mb-3">
            <div className="skeleton h-5 w-48" />
            <div className="skeleton h-5 w-20" />
          </div>
          <div className="skeleton h-4 w-32 mb-3" />
          <div className="flex gap-4">
            <div className="skeleton h-4 w-24" />
            <div className="skeleton h-4 w-32" />
          </div>
        </div>
      ))}
    </div>
  )

  return (
    <div>
      <div className="mb-6">
        <h1 className="font-mono font-bold text-2xl text-[#164E63]">My Pledges</h1>
        <p className="text-[#64748B] text-sm mt-1">Track the status of everything you've pledged</p>
      </div>

      {pledges.length === 0 ? (
        <div className="text-center py-16 text-[#64748B] bg-white rounded-2xl border border-[#A5F3FC]">
          <Package size={40} className="mx-auto mb-3 opacity-30" />
          <p className="font-semibold text-[#164E63] mb-1">No pledges yet</p>
          <p className="text-sm max-w-xs mx-auto">Find a need you care about, pledge a quantity, and track it here as the NGO confirms delivery.</p>
          <a href="/donor" className="inline-block mt-4 px-4 py-2 bg-[#0891B2] text-white text-sm font-medium rounded-xl hover:bg-[#0E7490] transition-colors">Browse needs</a>
        </div>
      ) : (
        <div className="space-y-3">
          {pledges.map(pledge => (
            <div key={pledge.id} className="bg-white rounded-2xl border border-[#A5F3FC] p-5 hover:border-[#0891B2] transition-colors">
              <div className="flex items-start justify-between gap-3 flex-wrap">
                <div>
                  <h3 className="font-mono font-semibold text-[#164E63]">
                    {pledge.donation_need?.item_name ?? 'Unknown item'}
                  </h3>
                  {pledge.donation_need?.ngo && (
                    <p className="text-sm text-[#64748B] mt-0.5">
                      {pledge.donation_need.ngo.name} · {pledge.donation_need.ngo.location}
                    </p>
                  )}
                </div>
                <PledgeStatusBadge status={pledge.status} />
              </div>

              <div className="mt-3 flex flex-wrap gap-4 text-sm text-[#64748B]">
                <span className="flex items-center gap-1.5">
                  <Package size={14} />
                  <strong className="text-[#164E63]">{pledge.quantity}</strong> units pledged
                </span>
                <span className="flex items-center gap-1.5">
                  <Calendar size={14} />
                  Delivery by <strong className="text-[#164E63] ml-1">{format(new Date(pledge.delivery_date), 'MMM d, yyyy')}</strong>
                </span>
              </div>

              {pledge.notes && (
                <p className="mt-2 text-sm text-[#64748B] italic">"{pledge.notes}"</p>
              )}

              <p className="mt-2 text-xs text-[#94A3B8] font-mono">
                Pledged on {format(new Date(pledge.created_at), 'MMM d, yyyy')}
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
