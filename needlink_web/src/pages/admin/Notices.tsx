import { useEffect, useState } from 'react'
import { Bell, Pin, PinOff, Trash2, AlertCircle, Send } from 'lucide-react'
import { formatDistanceToNow, parseISO } from 'date-fns'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../components/Toast'

type Audience = 'all' | 'donors' | 'ngos'

interface Notice {
  id: string
  title: string
  body: string
  audience: Audience
  pinned: boolean
  created_at: string
}

const AUDIENCE_META: Record<Audience, { label: string; bg: string; color: string }> = {
  all:    { label: 'Everyone', bg: '#EEF9FC', color: '#0891B2' },
  donors: { label: 'Donors',  bg: '#F5F3FF', color: '#7C3AED' },
  ngos:   { label: 'NGOs',    bg: '#F0FDF4', color: '#16A34A' },
}

function PageError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="p-8 flex flex-col items-center justify-center min-h-64 gap-4">
      <AlertCircle size={28} className="text-[#EF4444]" />
      <p className="text-[#164E63] font-semibold">{message}</p>
      <button onClick={onRetry} className="px-4 py-2 rounded-xl bg-[#0891B2] text-white text-sm font-semibold cursor-pointer hover:bg-[#0E7490] transition-colors">
        Retry
      </button>
    </div>
  )
}

export default function Notices() {
  const { user } = useAuth()
  const { toast } = useToast()

  const [notices, setNotices]     = useState<Notice[]>([])
  const [loading, setLoading]     = useState(true)
  const [loadError, setLoadError] = useState('')
  const [showPinned, setShowPinned] = useState(false)

  const [title, setTitle]       = useState('')
  const [body, setBody]         = useState('')
  const [audience, setAudience] = useState<Audience>('all')
  const [pinned, setPinned]     = useState(false)
  const [sending, setSending]   = useState(false)

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const { data, error } = await supabase
        .from('notices')
        .select('id, title, body, audience, pinned, created_at')
        .order('pinned', { ascending: false })
        .order('created_at', { ascending: false })
      if (error) throw new Error(error.message)
      setNotices((data as Notice[]) ?? [])
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Failed to load notices.')
    } finally {
      setLoading(false)
    }
  }

  async function send() {
    if (!title.trim() || !body.trim()) {
      toast('Title and message are required.', 'error')
      return
    }
    setSending(true)
    try {
      const { data, error } = await supabase
        .from('notices')
        .insert({ title: title.trim(), body: body.trim(), audience, pinned, created_by: user?.id })
        .select()
        .single()
      if (error) throw new Error(error.message)
      setNotices(prev => [data as Notice, ...prev])
      setTitle('')
      setBody('')
      setAudience('all')
      setPinned(false)
      toast('Notice published.', 'success')
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to publish notice.', 'error')
    } finally {
      setSending(false)
    }
  }

  async function togglePin(id: string, current: boolean) {
    try {
      const { error } = await supabase.from('notices').update({ pinned: !current }).eq('id', id)
      if (error) throw new Error(error.message)
      setNotices(prev => prev.map(n => n.id === id ? { ...n, pinned: !current } : n))
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to update notice.', 'error')
    }
  }

  async function deleteNotice(id: string) {
    if (!confirm('Delete this notice? It will no longer be visible to users.')) return
    try {
      const { error } = await supabase.from('notices').delete().eq('id', id)
      if (error) throw new Error(error.message)
      setNotices(prev => prev.filter(n => n.id !== id))
      toast('Notice deleted.', 'info')
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to delete notice.', 'error')
    }
  }

  const pinnedCount = notices.filter(n => n.pinned).length
  const countByAud  = (a: Audience) => notices.filter(n => n.audience === a).length
  const displayed   = showPinned ? notices.filter(n => n.pinned) : notices

  if (loading) return (
    <div className="p-8 flex items-center justify-center min-h-64">
      <div className="w-7 h-7 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (loadError) return <PageError message={loadError} onRetry={load} />

  return (
    <div>

      {/* Sticky header */}
      <div className="sticky top-0 z-10 bg-white px-8 py-5" style={{ borderBottom: '1px solid #E2E8F0' }}>
        <h1 className="font-heading font-bold text-[#164E63] text-2xl">Notices</h1>
        <p className="text-[#94A3B8] text-sm mt-0.5">Broadcast messages to donors and NGOs on the platform.</p>

        <div className="flex items-end gap-10 mt-5 pt-4" style={{ borderTop: '1px solid #F3F5F8' }}>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#164E63]">{notices.length}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Total sent</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#D97706]">{pinnedCount}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">Pinned</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#0891B2]">{countByAud('all')}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">To everyone</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#7C3AED]">{countByAud('donors')}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">To donors</div>
          </div>
          <div>
            <div className="font-mono font-bold text-[1.4rem] leading-none text-[#16A34A]">{countByAud('ngos')}</div>
            <div className="text-[#94A3B8] text-xs mt-1.5">To NGOs</div>
          </div>
        </div>
      </div>

      {/* Body */}
      <div className="p-8">
        <div className="grid gap-6" style={{ gridTemplateColumns: '1fr 340px' }}>

          {/* Notices list */}
          <div>
            <div className="flex items-center gap-3 mb-4">
              <div className="flex gap-1 bg-white border border-[#E2E8F0] rounded-xl p-1">
                <button
                  onClick={() => setShowPinned(false)}
                  className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                    !showPinned ? 'bg-[#0891B2] text-white' : 'text-[#64748B] hover:text-[#164E63]'
                  }`}
                >
                  All notices
                </button>
                <button
                  onClick={() => setShowPinned(true)}
                  className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer flex items-center gap-1.5 ${
                    showPinned ? 'bg-[#0891B2] text-white' : 'text-[#64748B] hover:text-[#164E63]'
                  }`}
                >
                  <Pin size={10} />
                  Pinned
                </button>
              </div>
              <span className="text-[#94A3B8] text-xs font-mono">
                {displayed.length} notice{displayed.length !== 1 ? 's' : ''}
              </span>
            </div>

            <div className="bg-white rounded-2xl border border-[#E2E8F0] overflow-hidden" style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}>
              {displayed.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-16 gap-3">
                  <Bell size={24} className="text-[#CBD5E1]" />
                  <p className="text-[#94A3B8] text-sm">
                    {showPinned ? 'No pinned notices.' : 'No notices sent yet. Compose one to get started.'}
                  </p>
                </div>
              ) : (
                displayed.map((notice, i) => {
                  const meta = AUDIENCE_META[notice.audience]
                  return (
                    <div
                      key={notice.id}
                      className="group px-6 py-4 hover:bg-[#F8FAFB] transition-colors"
                      style={{ borderTop: i === 0 ? 'none' : '1px solid #F1F5F9' }}
                    >
                      <div className="flex items-start gap-3">
                        {notice.pinned && (
                          <Pin size={12} className="text-[#D97706] mt-1 flex-shrink-0" />
                        )}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2.5 mb-1">
                            <p className="font-semibold text-[#164E63] text-sm truncate">{notice.title}</p>
                            <span
                              className="flex-shrink-0 text-[10px] font-semibold font-mono px-2 py-0.5 rounded-full"
                              style={{ background: meta.bg, color: meta.color }}
                            >
                              {meta.label}
                            </span>
                          </div>
                          <p className="text-[#64748B] text-xs leading-relaxed" style={{
                            display: '-webkit-box',
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: 'vertical',
                            overflow: 'hidden',
                          }}>
                            {notice.body}
                          </p>
                          <p className="text-[#94A3B8] text-[10px] font-mono mt-1.5">
                            {formatDistanceToNow(parseISO(notice.created_at), { addSuffix: true })}
                          </p>
                        </div>
                        <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0 mt-0.5">
                          <button
                            onClick={() => togglePin(notice.id, notice.pinned)}
                            title={notice.pinned ? 'Unpin' : 'Pin'}
                            className="p-1.5 rounded-lg hover:bg-[#F1F5F9] text-[#CBD5E1] hover:text-[#D97706] transition-colors cursor-pointer"
                          >
                            {notice.pinned ? <PinOff size={13} /> : <Pin size={13} />}
                          </button>
                          <button
                            onClick={() => deleteNotice(notice.id)}
                            title="Delete"
                            className="p-1.5 rounded-lg hover:bg-[#FEF2F2] text-[#CBD5E1] hover:text-[#EF4444] transition-colors cursor-pointer"
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </div>
                    </div>
                  )
                })
              )}
            </div>
          </div>

          {/* Compose form */}
          <div
            className="bg-white rounded-2xl border border-[#E2E8F0] p-6 self-start"
            style={{ boxShadow: '0 1px 8px rgba(15,23,42,0.04)' }}
          >
            <h2 className="font-heading font-bold text-[#164E63] text-[13px] uppercase tracking-wide mb-5">
              New Notice
            </h2>

            <div className="space-y-4">
              <div>
                <label className="block text-[10px] font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">
                  Title
                </label>
                <input
                  value={title}
                  onChange={e => setTitle(e.target.value)}
                  placeholder="Notice title"
                  maxLength={120}
                  className="w-full px-3.5 py-2.5 border border-[#E2E8F0] rounded-xl text-sm text-[#164E63] bg-[#F8FAFB] focus:outline-none focus:border-[#0891B2] focus:bg-white transition-colors"
                />
              </div>

              <div>
                <label className="block text-[10px] font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">
                  Message
                </label>
                <textarea
                  value={body}
                  onChange={e => setBody(e.target.value)}
                  placeholder="Write the notice message…"
                  rows={5}
                  className="w-full px-3.5 py-2.5 border border-[#E2E8F0] rounded-xl text-sm text-[#164E63] bg-[#F8FAFB] focus:outline-none focus:border-[#0891B2] focus:bg-white transition-colors resize-none leading-relaxed"
                />
              </div>

              <div>
                <label className="block text-[10px] font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">
                  Audience
                </label>
                <div className="flex gap-1.5">
                  {(['all', 'donors', 'ngos'] as const).map(a => {
                    const meta = AUDIENCE_META[a]
                    const sel  = audience === a
                    return (
                      <button
                        key={a}
                        onClick={() => setAudience(a)}
                        className="flex-1 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer border"
                        style={sel
                          ? { background: meta.bg, color: meta.color, borderColor: meta.color + '60' }
                          : { background: 'white', color: '#94A3B8', borderColor: '#E2E8F0' }
                        }
                      >
                        {meta.label}
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* Pin toggle */}
              <div
                className="flex items-center justify-between px-3.5 py-2.5 rounded-xl cursor-pointer transition-all select-none"
                style={{
                  background: pinned ? '#FFFBEB' : '#F8FAFB',
                  border: `1px solid ${pinned ? '#D9770640' : '#E2E8F0'}`,
                }}
                onClick={() => setPinned(p => !p)}
              >
                <div className="flex items-center gap-2.5">
                  <Pin size={13} className={pinned ? 'text-[#D97706]' : 'text-[#94A3B8]'} />
                  <div>
                    <p className={`text-xs font-semibold ${pinned ? 'text-[#D97706]' : 'text-[#64748B]'}`}>
                      Pin this notice
                    </p>
                    <p className="text-[10px] text-[#94A3B8]">Stays at top for all users</p>
                  </div>
                </div>
                <div
                  className="relative w-8 h-4 rounded-full transition-colors flex-shrink-0"
                  style={{ background: pinned ? '#D97706' : '#CBD5E1' }}
                >
                  <div
                    className="absolute top-0.5 w-3 h-3 rounded-full bg-white transition-all"
                    style={{ left: pinned ? '14px' : '2px' }}
                  />
                </div>
              </div>

              <button
                onClick={send}
                disabled={sending || !title.trim() || !body.trim()}
                className="w-full py-2.5 rounded-xl bg-[#0891B2] text-white text-sm font-semibold flex items-center justify-center gap-2 hover:bg-[#0E7490] transition-colors cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {sending ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    <Send size={13} />
                    Publish Notice
                  </>
                )}
              </button>
            </div>
          </div>

        </div>
      </div>
    </div>
  )
}
