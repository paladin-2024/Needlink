import { Link } from 'react-router-dom'
import { Calendar, MapPin, Package } from 'lucide-react'
import { format } from 'date-fns'
import type { DonationNeed } from '../types'
import { NeedStatusBadge, UrgencyBadge, VerifiedBadge } from './StatusBadge'

const categoryColors: Record<string, string> = {
  food: 'bg-orange-50 text-orange-700 border-orange-200',
  clothing: 'bg-purple-50 text-purple-700 border-purple-200',
  medicine: 'bg-red-50 text-red-700 border-red-200',
  supplies: 'bg-blue-50 text-blue-700 border-blue-200',
}

const categoryIcons: Record<string, string> = {
  food: '🌾',
  clothing: '👕',
  medicine: '💊',
  supplies: '📦',
}

interface Props {
  need: DonationNeed
  linkTo: string
  showNgo?: boolean
}

export default function NeedCard({ need, linkTo, showNgo = true }: Props) {
  const progress = Math.min(100, Math.round((need.quantity_pledged / need.quantity_needed) * 100))

  return (
    <Link to={linkTo} className="block group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#0891B2] focus-visible:ring-offset-2 rounded-2xl">
      <div className="bg-white rounded-2xl border border-[#A5F3FC] shadow-sm group-hover:shadow-md group-hover:border-[#0891B2] transition-all duration-200 p-5 h-full">
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex items-center gap-2 flex-wrap">
            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${categoryColors[need.category]}`}>
              <span>{categoryIcons[need.category]}</span>
              {need.category}
            </span>
            <UrgencyBadge urgency={need.urgency} />
          </div>
          <NeedStatusBadge status={need.status} />
        </div>

        <h3 className="font-mono font-semibold text-[#164E63] text-lg leading-snug mb-1 group-hover:text-[#0891B2] transition-colors">
          {need.item_name}
        </h3>

        {showNgo && need.ngo && (
          <div className="flex items-center gap-1.5 text-sm text-[#64748B] mb-3">
            <MapPin size={13} />
            <span>{need.ngo.name}</span>
            {need.ngo.verified && <VerifiedBadge />}
            <span>· {need.ngo.location}</span>
          </div>
        )}

        {need.description && (
          <p className="text-sm text-[#64748B] line-clamp-2 mb-4">{need.description}</p>
        )}

        <div className="space-y-2">
          <div className="flex justify-between text-xs text-[#64748B]">
            <span className="flex items-center gap-1"><Package size={12} /> {need.quantity_pledged} / {need.quantity_needed} pledged</span>
            <span>{progress}%</span>
          </div>
          <div className="h-2 bg-[#E8F1F6] rounded-full overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-500"
              style={{
                width: `${progress}%`,
                background: progress >= 100 ? '#16A34A' : 'linear-gradient(90deg, #0891B2, #22D3EE)',
              }}
            />
          </div>
        </div>

        <div className="mt-3 flex items-center gap-1.5 text-xs text-[#64748B]">
          <Calendar size={12} />
          <span>Deadline: {format(new Date(need.deadline), 'MMM d, yyyy')}</span>
        </div>
      </div>
    </Link>
  )
}
