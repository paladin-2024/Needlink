import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Calendar, MapPin, Package, AlertCircle, CheckCircle2, Share2 } from 'lucide-react'
import { format } from 'date-fns'
import confetti from 'canvas-confetti'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../components/Toast'
import type { DonationNeed } from '../../types'
import { NeedStatusBadge, UrgencyBadge, VerifiedBadge } from '../../components/StatusBadge'

export default function NeedDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { user } = useAuth()
  const { toast } = useToast()
  const [need, setNeed] = useState<DonationNeed | null>(null)
  const [loading, setLoading] = useState(true)
  const [quantity, setQuantity] = useState(1)
  const [deliveryDate, setDeliveryDate] = useState('')
  const [notes, setNotes] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!id) return
    supabase.from('donation_needs').select('*, ngo:ngos(*)').eq('id', id).single()
      .then(({ data }) => { setNeed(data); setLoading(false) })
  }, [id])

  async function handlePledge(e: React.FormEvent) {
    e.preventDefault()
    if (!need || !user) return
    setError(''); setSubmitting(true)

    const { error: pledgeError } = await supabase.from('pledges').insert({
      need_id: need.id,
      donor_id: user.id,
      quantity,
      delivery_date: deliveryDate,
      notes: notes || null,
    })

    if (pledgeError) {
      setError(pledgeError.message)
      toast(pledgeError.message, 'error')
      setSubmitting(false)
      return
    }

    // Increment quantity_pledged
    const newPledged = need.quantity_pledged + quantity
    const newStatus = newPledged >= need.quantity_needed ? 'matched' : need.status
    await supabase.from('donation_needs')
      .update({ quantity_pledged: newPledged, status: newStatus })
      .eq('id', need.id)

    if (newStatus === 'matched') {
      confetti({ particleCount: 120, spread: 80, origin: { y: 0.6 }, colors: ['#0891B2', '#22D3EE', '#EA580C', '#16A34A'] })
      toast('Need fully matched! Thank you for your generosity.', 'success', 5000)
    } else {
      toast('Pledge submitted! The NGO will review and confirm soon.', 'success')
    }
    setSuccess(true); setSubmitting(false)
  }

  async function handleShare() {
    const url = window.location.href
    const text = `Help ${need?.ngo?.name ?? 'an NGO'} — they need ${need?.quantity_needed} ${need?.item_name}. Pledge on NeedLink:`
    if (navigator.share) {
      await navigator.share({ title: need?.item_name, text, url }).catch(() => null)
    } else {
      await navigator.clipboard.writeText(`${text} ${url}`)
      toast('Link copied to clipboard!', 'info')
    }
  }

  if (loading) return <div className="flex items-center justify-center h-64"><div className="w-8 h-8 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" /></div>
  if (!need) return <div className="text-center py-16 text-[#64748B]">Need not found.</div>

  const progress = Math.min(100, Math.round((need.quantity_pledged / need.quantity_needed) * 100))
  const remaining = Math.max(0, need.quantity_needed - need.quantity_pledged)

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-5">
        <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-sm text-[#64748B] hover:text-[#164E63] cursor-pointer transition-colors">
          <ArrowLeft size={16} /> Back
        </button>
        <button
          onClick={handleShare}
          className="flex items-center gap-1.5 text-sm text-[#64748B] hover:text-[#0891B2] px-3 py-1.5 rounded-lg hover:bg-sky-50 transition-colors cursor-pointer"
          aria-label="Share this need"
        >
          <Share2 size={15} /> Share
        </button>
      </div>

      <div className="bg-white rounded-2xl border border-[#A5F3FC] shadow-sm p-6 mb-5">
        <div className="flex items-start justify-between gap-3 mb-4 flex-wrap">
          <div className="flex items-center gap-2 flex-wrap">
            <NeedStatusBadge status={need.status} />
            <UrgencyBadge urgency={need.urgency} />
          </div>
          <span className="text-xs text-[#64748B] font-mono">
            Posted {format(new Date(need.created_at), 'MMM d, yyyy')}
          </span>
        </div>

        <h1 className="font-mono font-bold text-2xl text-[#164E63] mb-2">{need.item_name}</h1>

        {need.ngo && (
          <div className="flex items-center gap-1.5 text-sm text-[#64748B] mb-4">
            <MapPin size={14} />
            <span className="font-medium">{need.ngo.name}</span>
            {need.ngo.verified && <VerifiedBadge />}
            <span>·</span>
            <span>{need.ngo.location}</span>
          </div>
        )}

        {need.description && (
          <p className="text-[#164E63] text-sm leading-relaxed mb-5">{need.description}</p>
        )}

        <div className="grid grid-cols-2 gap-3 mb-5">
          <div className="bg-[#ECFEFF] rounded-xl p-3">
            <p className="text-xs text-[#64748B] mb-1">Needed</p>
            <p className="font-mono font-bold text-xl text-[#164E63]">{need.quantity_needed}</p>
          </div>
          <div className="bg-[#ECFEFF] rounded-xl p-3">
            <p className="text-xs text-[#64748B] mb-1">Still needed</p>
            <p className="font-mono font-bold text-xl text-[#EA580C]">{remaining}</p>
          </div>
        </div>

        <div className="space-y-1.5 mb-4">
          <div className="flex justify-between text-xs text-[#64748B]">
            <span><Package size={12} className="inline mr-1" />{need.quantity_pledged} pledged</span>
            <span>{progress}%</span>
          </div>
          <div className="h-3 bg-[#E8F1F6] rounded-full overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-700"
              style={{ width: `${progress}%`, background: progress >= 100 ? '#16A34A' : 'linear-gradient(90deg, #0891B2, #22D3EE)' }}
            />
          </div>
        </div>

        <div className="flex items-center gap-1.5 text-sm text-[#64748B]">
          <Calendar size={14} />
          <span>Deadline: <strong className="text-[#164E63]">{format(new Date(need.deadline), 'MMMM d, yyyy')}</strong></span>
        </div>
      </div>

      {need.status !== 'closed' && !success && (
        <div className="bg-white rounded-2xl border border-[#A5F3FC] shadow-sm p-6">
          <h2 className="font-mono font-semibold text-lg text-[#164E63] mb-4">Make a Pledge</h2>

          {error && (
            <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl p-3 mb-4">
              <AlertCircle size={14} />{error}
            </div>
          )}

          <form onSubmit={handlePledge} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-[#164E63] mb-1.5">
                Quantity <span className="text-[#64748B] font-normal">(max {remaining})</span>
              </label>
              <input
                type="number" min={1} max={remaining || undefined} required
                value={quantity} onChange={e => setQuantity(Number(e.target.value))}
                className="w-full px-4 py-2.5 border border-[#A5F3FC] rounded-xl text-sm text-[#164E63] bg-[#ECFEFF] focus:outline-none focus:ring-2 focus:ring-[#0891B2]"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-[#164E63] mb-1.5">Expected delivery date</label>
              <input
                type="date" required
                min={new Date().toISOString().split('T')[0]}
                max={need.deadline}
                value={deliveryDate} onChange={e => setDeliveryDate(e.target.value)}
                className="w-full px-4 py-2.5 border border-[#A5F3FC] rounded-xl text-sm text-[#164E63] bg-[#ECFEFF] focus:outline-none focus:ring-2 focus:ring-[#0891B2]"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-[#164E63] mb-1.5">Notes <span className="text-[#64748B] font-normal">(optional)</span></label>
              <textarea
                rows={3} value={notes} onChange={e => setNotes(e.target.value)}
                placeholder="Any special notes for the NGO…"
                className="w-full px-4 py-2.5 border border-[#A5F3FC] rounded-xl text-sm text-[#164E63] bg-[#ECFEFF] focus:outline-none focus:ring-2 focus:ring-[#0891B2] resize-none"
              />
            </div>

            <button
              type="submit" disabled={submitting || remaining === 0}
              className="w-full py-3 bg-[#EA580C] hover:bg-[#C2410C] disabled:opacity-60 text-white font-semibold rounded-xl transition-colors cursor-pointer"
            >
              {submitting ? 'Submitting…' : 'Submit Pledge'}
            </button>
          </form>
        </div>
      )}

      {success && (
        <div className="bg-green-50 border border-green-200 rounded-2xl p-6 flex items-center gap-3">
          <CheckCircle2 size={24} className="text-green-600 shrink-0" />
          <div>
            <p className="font-semibold text-green-800">Pledge submitted!</p>
            <p className="text-sm text-green-700 mt-0.5">The NGO will review your pledge and confirm soon.</p>
          </div>
        </div>
      )}
    </div>
  )
}
