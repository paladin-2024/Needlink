import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, AlertCircle } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../components/Toast'
import type { ItemCategory, Urgency } from '../../types'

export default function CreateNeed() {
  const { user } = useAuth()
  const { toast } = useToast()
  const navigate = useNavigate()
  const [ngoId, setNgoId] = useState<string | null>(null)
  const [itemName, setItemName] = useState('')
  const [category, setCategory] = useState<ItemCategory>('food')
  const [quantity, setQuantity] = useState(1)
  const [urgency, setUrgency] = useState<Urgency>('normal')
  const [deadline, setDeadline] = useState('')
  const [description, setDescription] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!user) return
    supabase.from('ngos').select('id').eq('admin_id', user.id).single()
      .then(({ data }) => setNgoId(data?.id ?? null))
  }, [user])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!ngoId) { setError('NGO not found'); return }
    setError(''); setLoading(true)

    const { error: insertError } = await supabase.from('donation_needs').insert({
      ngo_id: ngoId,
      item_name: itemName,
      category,
      quantity_needed: quantity,
      urgency,
      deadline,
      description: description || null,
    })

    if (insertError) {
      setError(insertError.message)
      toast(insertError.message, 'error')
      setLoading(false)
      return
    }
    toast(`"${itemName}" posted successfully!`, 'success')
    navigate('/ngo/needs')
  }

  const categories: ItemCategory[] = ['food', 'clothing', 'medicine', 'supplies']
  const categoryLabels = { food: '🌾 Food', clothing: '👕 Clothing', medicine: '💊 Medicine', supplies: '📦 Supplies' }

  return (
    <div className="max-w-xl mx-auto">
      <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-sm text-[#64748B] hover:text-[#164E63] mb-5 cursor-pointer transition-colors">
        <ArrowLeft size={16} /> Back to needs
      </button>

      <div className="bg-white rounded-2xl border border-[#A5F3FC] shadow-sm p-6">
        <h1 className="font-mono font-bold text-xl text-[#164E63] mb-5">Post a New Need</h1>

        {error && (
          <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl p-3 mb-4">
            <AlertCircle size={14} />{error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-[#164E63] mb-1.5">Item name *</label>
            <input
              type="text" required value={itemName} onChange={e => setItemName(e.target.value)}
              placeholder="e.g. School exercise books"
              className="w-full px-4 py-2.5 border border-[#A5F3FC] rounded-xl text-sm text-[#164E63] bg-[#ECFEFF] focus:outline-none focus:ring-2 focus:ring-[#0891B2]"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-[#164E63] mb-1.5">Category *</label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {categories.map(c => (
                <button
                  key={c} type="button" onClick={() => setCategory(c)}
                  className={`py-2 px-3 rounded-xl text-xs font-semibold border-2 transition-all cursor-pointer ${
                    category === c
                      ? 'bg-[#164E63] border-[#164E63] text-white'
                      : 'bg-white border-[#A5F3FC] text-[#64748B] hover:border-[#0891B2]'
                  }`}
                >
                  {categoryLabels[c]}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-[#164E63] mb-1.5">Quantity needed *</label>
              <input
                type="number" min={1} required value={quantity} onChange={e => setQuantity(Number(e.target.value))}
                className="w-full px-4 py-2.5 border border-[#A5F3FC] rounded-xl text-sm text-[#164E63] bg-[#ECFEFF] focus:outline-none focus:ring-2 focus:ring-[#0891B2]"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-[#164E63] mb-1.5">Deadline *</label>
              <input
                type="date" required value={deadline} onChange={e => setDeadline(e.target.value)}
                min={new Date().toISOString().split('T')[0]}
                className="w-full px-4 py-2.5 border border-[#A5F3FC] rounded-xl text-sm text-[#164E63] bg-[#ECFEFF] focus:outline-none focus:ring-2 focus:ring-[#0891B2]"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-[#164E63] mb-1.5">Urgency *</label>
            <div className="flex gap-3">
              {(['normal', 'urgent'] as Urgency[]).map(u => (
                <button
                  key={u} type="button" onClick={() => setUrgency(u)}
                  className={`flex-1 py-2.5 rounded-xl text-sm font-semibold border-2 transition-all cursor-pointer ${
                    urgency === u
                      ? u === 'urgent' ? 'bg-red-500 border-red-500 text-white' : 'bg-[#164E63] border-[#164E63] text-white'
                      : 'bg-white border-[#A5F3FC] text-[#64748B] hover:border-[#0891B2]'
                  }`}
                >
                  {u === 'urgent' ? '⚡ Urgent' : 'Normal'}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-[#164E63] mb-1.5">Description <span className="text-[#64748B] font-normal">(optional)</span></label>
            <textarea
              rows={3} value={description} onChange={e => setDescription(e.target.value)}
              placeholder="Any additional context about this need…"
              className="w-full px-4 py-2.5 border border-[#A5F3FC] rounded-xl text-sm text-[#164E63] bg-[#ECFEFF] focus:outline-none focus:ring-2 focus:ring-[#0891B2] resize-none"
            />
          </div>

          <button
            type="submit" disabled={loading}
            className="w-full py-3 bg-[#EA580C] hover:bg-[#C2410C] disabled:opacity-60 text-white font-semibold rounded-xl transition-colors cursor-pointer"
          >
            {loading ? 'Posting…' : 'Post Need'}
          </button>
        </form>
      </div>
    </div>
  )
}
