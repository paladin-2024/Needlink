import { BadgeCheck } from 'lucide-react'
import type { NeedStatus, PledgeStatus, Urgency } from '../types'

const needStatusStyles: Record<NeedStatus, string> = {
  open: 'bg-sky-100 text-sky-800 border border-sky-300',
  matched: 'bg-green-100 text-green-800 border border-green-300',
  closed: 'bg-slate-100 text-slate-600 border border-slate-300',
}

const pledgeStatusStyles: Record<PledgeStatus, string> = {
  pending: 'bg-amber-100 text-amber-800 border border-amber-300',
  matched: 'bg-sky-100 text-sky-800 border border-sky-300',
  in_transit: 'bg-purple-100 text-purple-800 border border-purple-300',
  confirmed: 'bg-green-100 text-green-800 border border-green-300',
  rejected: 'bg-red-100 text-red-700 border border-red-300',
}

export function NeedStatusBadge({ status }: { status: NeedStatus }) {
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium font-mono uppercase tracking-wide ${needStatusStyles[status]}`}>
      {status}
    </span>
  )
}

export function PledgeStatusBadge({ status }: { status: PledgeStatus }) {
  const label = status.replace('_', ' ')
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium font-mono uppercase tracking-wide ${pledgeStatusStyles[status]}`}>
      {label}
    </span>
  )
}

export function UrgencyBadge({ urgency }: { urgency: Urgency }) {
  if (urgency === 'normal') return null
  return (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-semibold bg-red-500 text-white">
      ⚡ Urgent
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
