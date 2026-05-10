import { useEffect, useState, useCallback } from 'react'
import { Search, SlidersHorizontal } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import type { DonationNeed, ItemCategory, NeedStatus } from '../../types'
import NeedCard from '../../components/NeedCard'

const CATEGORIES: ItemCategory[] = ['food', 'clothing', 'medicine', 'supplies']

export default function DonorHome() {
  const [needs, setNeeds] = useState<DonationNeed[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState<ItemCategory | ''>('')
  const [urgencyFilter, setUrgencyFilter] = useState<'all' | 'urgent'>('all')
  const [statusFilter, setStatusFilter] = useState<NeedStatus | 'all'>('open')

  const fetchNeeds = useCallback(async () => {
    let query = supabase
      .from('donation_needs')
      .select('*, ngo:ngos(*)')
      .order('created_at', { ascending: false })

    if (statusFilter !== 'all') query = query.eq('status', statusFilter)
    if (category) query = query.eq('category', category)
    if (urgencyFilter === 'urgent') query = query.eq('urgency', 'urgent')

    const { data } = await query
    setNeeds(data ?? [])
    setLoading(false)
  }, [category, urgencyFilter, statusFilter])

  useEffect(() => {
    fetchNeeds()

    const channel = supabase
      .channel('donation_needs_feed')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'donation_needs' }, fetchNeeds)
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [fetchNeeds])

  const filtered = needs.filter(n =>
    n.item_name.toLowerCase().includes(search.toLowerCase()) ||
    n.ngo?.name?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div>
      <div className="mb-6">
        <h1 className="font-mono font-bold text-2xl text-[#164E63]">Browse Donation Needs</h1>
        <p className="text-[#64748B] text-sm mt-1">Find NGOs that need your help right now</p>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-2xl border border-[#A5F3FC] p-4 mb-6 space-y-3">
        <div className="relative">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#64748B]" />
          <input
            type="search"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search by item or NGO name…"
            className="w-full pl-9 pr-4 py-2.5 border border-[#A5F3FC] rounded-xl text-sm bg-[#ECFEFF] text-[#164E63] focus:outline-none focus:ring-2 focus:ring-[#0891B2] placeholder:text-[#94A3B8]"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <SlidersHorizontal size={14} className="text-[#64748B]" />

          {/* Category filter */}
          <div className="flex gap-1 flex-wrap">
            {['', ...CATEGORIES].map(c => (
              <button
                key={c}
                onClick={() => setCategory(c as ItemCategory | '')}
                className={`px-3 py-1 rounded-full text-xs font-medium border transition-all cursor-pointer ${
                  category === c
                    ? 'bg-[#0891B2] border-[#0891B2] text-white'
                    : 'bg-white border-[#A5F3FC] text-[#64748B] hover:border-[#0891B2]'
                }`}
              >
                {c || 'All categories'}
              </button>
            ))}
          </div>

          <div className="w-px h-4 bg-[#A5F3FC]" />

          <button
            onClick={() => setUrgencyFilter(u => u === 'urgent' ? 'all' : 'urgent')}
            className={`px-3 py-1 rounded-full text-xs font-semibold border transition-all cursor-pointer ${
              urgencyFilter === 'urgent'
                ? 'bg-red-500 border-red-500 text-white'
                : 'bg-white border-[#A5F3FC] text-[#64748B] hover:border-red-300'
            }`}
          >
            ⚡ Urgent only
          </button>

          <button
            onClick={() => setStatusFilter(s => s === 'open' ? 'all' : 'open')}
            className={`px-3 py-1 rounded-full text-xs font-medium border transition-all cursor-pointer ${
              statusFilter === 'open'
                ? 'bg-[#164E63] border-[#164E63] text-white'
                : 'bg-white border-[#A5F3FC] text-[#64748B] hover:border-[#164E63]'
            }`}
          >
            Open only
          </button>
        </div>
      </div>

      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="bg-white rounded-2xl border border-[#A5F3FC] p-5">
              <div className="flex gap-2 mb-3">
                <div className="skeleton h-5 w-20" />
                <div className="skeleton h-5 w-14" />
              </div>
              <div className="skeleton h-6 w-full mb-2" />
              <div className="skeleton h-4 w-2/3 mb-4" />
              <div className="skeleton h-2 w-full mb-1" />
              <div className="skeleton h-3 w-1/2 mt-3" />
            </div>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 text-[#64748B] bg-white rounded-2xl border border-[#A5F3FC]">
          <Package size={40} className="mx-auto mb-3 opacity-30" />
          <p className="font-semibold text-[#164E63] mb-1">No needs match your filters</p>
          <p className="text-sm">Try removing a filter, or check back later — needs update in real time.</p>
          {(category || urgencyFilter === 'urgent') && (
            <button
              onClick={() => { setCategory(''); setUrgencyFilter('all') }}
              className="mt-3 text-sm text-[#0891B2] hover:underline cursor-pointer"
            >
              Clear filters
            </button>
          )}
        </div>
      ) : (
        <>
          <p className="text-xs text-[#64748B] mb-3 font-mono">{filtered.length} needs found</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {filtered.map(need => (
              <NeedCard key={need.id} need={need} linkTo={`/donor/need/${need.id}`} />
            ))}
          </div>
        </>
      )}
    </div>
  )
}

function Package({ size, className }: { size: number; className?: string }) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24"
      fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"
      strokeLinejoin="round" className={className}>
      <path d="M11 21H4a2 2 0 0 1-2-2V5c0-1.1.9-2 2-2h5l2 3h9a2 2 0 0 1 2 2v2" />
      <path d="M17 17h4" /><path d="M19 15v4" />
    </svg>
  )
}
