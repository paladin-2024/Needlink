import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, Package, ClipboardList, LayoutDashboard, BarChart3, Plus, LogOut } from 'lucide-react'
import { useAuth } from '../context/AuthContext'

interface Command {
  id: string
  label: string
  description?: string
  icon: React.ReactNode
  action: () => void
  role?: 'donor' | 'ngo_admin' | 'both'
}

export default function CommandPalette() {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)
  const navigate = useNavigate()
  const { profile, signOut } = useAuth()

  const allCommands: Command[] = [
    { id: 'browse', label: 'Browse Needs', description: 'See all open donation needs', icon: <Package size={16} />, action: () => navigate('/donor'), role: 'donor' },
    { id: 'pledges', label: 'My Pledges', description: 'Track your pledge status', icon: <ClipboardList size={16} />, action: () => navigate('/donor/pledges'), role: 'donor' },
    { id: 'ngo-dash', label: 'NGO Dashboard', description: 'Overview of your NGO activity', icon: <LayoutDashboard size={16} />, action: () => navigate('/ngo'), role: 'ngo_admin' },
    { id: 'ngo-needs', label: 'My Needs', description: 'Manage your posted needs', icon: <Package size={16} />, action: () => navigate('/ngo/needs'), role: 'ngo_admin' },
    { id: 'post-need', label: 'Post a New Need', description: 'Add a donation need for your NGO', icon: <Plus size={16} />, action: () => navigate('/ngo/needs/new'), role: 'ngo_admin' },
    { id: 'ngo-pledges', label: 'Review Pledges', description: 'Confirm or reject incoming pledges', icon: <ClipboardList size={16} />, action: () => navigate('/ngo/pledges'), role: 'ngo_admin' },
    { id: 'reports', label: 'Reports', description: 'View impact metrics and analytics', icon: <BarChart3 size={16} />, action: () => navigate('/ngo/reports'), role: 'ngo_admin' },
    { id: 'signout', label: 'Sign Out', icon: <LogOut size={16} />, action: async () => { await signOut(); navigate('/login') }, role: 'both' },
  ]

  const commands = allCommands.filter(c => {
    if (c.role && c.role !== 'both' && c.role !== profile?.role) return false
    if (!query) return true
    return c.label.toLowerCase().includes(query.toLowerCase()) || c.description?.toLowerCase().includes(query.toLowerCase())
  })

  const execute = useCallback((cmd: Command) => {
    setOpen(false)
    setQuery('')
    cmd.action()
  }, [])

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        setOpen(o => !o)
        setQuery('')
        setSelected(0)
      }
      if (!open) return
      if (e.key === 'Escape') { setOpen(false); setQuery('') }
      if (e.key === 'ArrowDown') { e.preventDefault(); setSelected(s => Math.min(s + 1, commands.length - 1)) }
      if (e.key === 'ArrowUp') { e.preventDefault(); setSelected(s => Math.max(s - 1, 0)) }
      if (e.key === 'Enter' && commands[selected]) execute(commands[selected])
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, commands, selected, execute])

  useEffect(() => {
    if (open) { setTimeout(() => inputRef.current?.focus(), 10); setSelected(0) }
  }, [open])

  useEffect(() => { setSelected(0) }, [query])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh] px-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-[#164E63]/40 backdrop-blur-sm"
        onClick={() => { setOpen(false); setQuery('') }}
      />

      {/* Palette */}
      <div
        className="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-[#A5F3FC] overflow-hidden"
        style={{ animation: 'palette-in 0.15s cubic-bezier(0.16, 1, 0.3, 1)' }}
      >
        <style>{`
          @keyframes palette-in {
            from { opacity: 0; transform: scale(0.96) translateY(-8px); }
            to { opacity: 1; transform: scale(1) translateY(0); }
          }
        `}</style>

        {/* Search input */}
        <div className="flex items-center gap-3 px-4 py-3 border-b border-[#E8F1F6]">
          <Search size={18} className="text-[#64748B] shrink-0" />
          <input
            ref={inputRef}
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Search commands…"
            className="flex-1 text-[#164E63] text-sm bg-transparent outline-none placeholder:text-[#94A3B8]"
            aria-label="Search commands"
          />
          <kbd className="hidden sm:inline-flex items-center gap-1 px-2 py-0.5 text-xs text-[#94A3B8] bg-[#F1F5F9] rounded border border-[#E2E8F0]">
            ESC
          </kbd>
        </div>

        {/* Commands */}
        <div className="py-2 max-h-72 overflow-y-auto">
          {commands.length === 0 ? (
            <p className="text-sm text-[#94A3B8] text-center py-6">No commands match "{query}"</p>
          ) : commands.map((cmd, i) => (
            <button
              key={cmd.id}
              onClick={() => execute(cmd)}
              onMouseEnter={() => setSelected(i)}
              className={`w-full flex items-center gap-3 px-4 py-2.5 text-left transition-colors cursor-pointer ${
                i === selected ? 'bg-[#ECFEFF] text-[#164E63]' : 'text-[#64748B] hover:bg-[#F8FCFE]'
              }`}
            >
              <span className={i === selected ? 'text-[#0891B2]' : 'text-[#94A3B8]'}>{cmd.icon}</span>
              <div className="min-w-0">
                <p className="text-sm font-medium text-[#164E63] truncate">{cmd.label}</p>
                {cmd.description && <p className="text-xs text-[#94A3B8] truncate">{cmd.description}</p>}
              </div>
              {i === selected && (
                <kbd className="ml-auto shrink-0 text-xs text-[#94A3B8] bg-[#F1F5F9] px-1.5 py-0.5 rounded border border-[#E2E8F0]">↵</kbd>
              )}
            </button>
          ))}
        </div>

        <div className="px-4 py-2 border-t border-[#E8F1F6] flex items-center gap-3 text-xs text-[#94A3B8]">
          <span><kbd className="font-sans">↑↓</kbd> navigate</span>
          <span><kbd className="font-sans">↵</kbd> select</span>
          <span><kbd className="font-sans">esc</kbd> close</span>
          <span className="ml-auto">NeedLink</span>
        </div>
      </div>
    </div>
  )
}

/** Floating trigger hint shown in the app header */
export function CommandPaletteTrigger() {
  return (
    <button
      onClick={() => window.dispatchEvent(new KeyboardEvent('keydown', { key: 'k', ctrlKey: true, bubbles: true }))}
      className="hidden sm:flex items-center gap-2 px-3 py-1.5 text-xs text-[#64748B] bg-[#F1F5F9] hover:bg-[#E8F1F6] border border-[#E2E8F0] rounded-lg transition-colors cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#0891B2]"
      aria-label="Open command palette"
    >
      <Search size={12} />
      <span>Quick nav</span>
      <kbd className="font-sans text-[10px] bg-white border border-[#E2E8F0] px-1 rounded">⌘K</kbd>
    </button>
  )
}
