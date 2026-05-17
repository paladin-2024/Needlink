import { BadgeCheck } from 'lucide-react'
import type { NeedStatus, PledgeStatus, Urgency } from '../types'

const needStatusStyles: Record<NeedStatus, string> = {
  open:    'bg-sky-50 text-sky-700 border border-sky-200',
  matched: 'bg-green-50 text-green-700 border border-green-200',
  closed:  'bg-slate-50 text-slate-500 border border-slate-200',
}

const pledgeStatusStyles: Record<PledgeStatus, string> = {
  pending:   'bg-amber-50 text-amber-700 border border-amber-200',
  confirmed: 'bg-green-50 text-green-700 border border-green-200',
  rejected:  'bg-red-50 text-red-600 border border-red-200',
}

export function NeedStatusBadge({ status }: { status: NeedStatus }) {
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold font-mono uppercase tracking-wide ${needStatusStyles[status]}`}>
      {status}
    </span>
  )
}

export function PledgeStatusBadge({ status }: { status: PledgeStatus }) {
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold font-mono uppercase tracking-wide ${pledgeStatusStyles[status]}`}>
      {status}
    </span>
  )
}

export function UrgencyBadge({ urgency }: { urgency: Urgency }) {
  if (urgency === 'normal') return null
  return (
    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-bold bg-[#EF4444] text-white uppercase tracking-wide">
      URGENT
    </span>
  )
}

export function VerifiedBadge() {
  return (
    <span title="Verified NGO" aria-label="Verified NGO">
      <BadgeCheck size={14} className="text-[#0891B2] shrink-0" />
    </span>
  )
}
