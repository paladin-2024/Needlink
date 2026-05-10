import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import {
  LayoutDashboard, Package, ClipboardList,
  BarChart3, LogOut, Bell, Menu, X
} from 'lucide-react'
import { useState } from 'react'
import CommandPalette, { CommandPaletteTrigger } from './CommandPalette'
import NeedLinkLogo from './NeedLinkLogo'

const donorNav = [
  { to: '/donor', icon: <Package size={18} />, label: 'Browse Needs' },
  { to: '/donor/pledges', icon: <ClipboardList size={18} />, label: 'My Pledges' },
]

const ngoNav = [
  { to: '/ngo', icon: <LayoutDashboard size={18} />, label: 'Dashboard' },
  { to: '/ngo/needs', icon: <Package size={18} />, label: 'My Needs' },
  { to: '/ngo/pledges', icon: <ClipboardList size={18} />, label: 'Pledges' },
  { to: '/ngo/reports', icon: <BarChart3 size={18} />, label: 'Reports' },
]

export default function Layout({ children }: { children: React.ReactNode }) {
  const { profile, signOut } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()
  const [mobileOpen, setMobileOpen] = useState(false)

  const navItems = profile?.role === 'ngo_admin' ? ngoNav : donorNav

  async function handleSignOut() {
    await signOut()
    navigate('/login')
  }

  const Sidebar = () => (
    <aside className="flex flex-col h-full bg-[#164E63] text-white">
      <div className="p-6 border-b border-white/10">
        <Link to="/" className="flex items-center gap-2.5">
          <NeedLinkLogo size={32} />
          <span className="font-mono font-bold text-xl tracking-tight">NeedLink</span>
        </Link>
        <p className="text-xs text-white/50 mt-1 font-mono">Uganda · In-kind Donations</p>
      </div>

      <nav className="flex-1 p-4 space-y-1">
        {navItems.map(({ to, icon, label }) => {
          const active = location.pathname === to
          return (
            <Link
              key={to}
              to={to}
              onClick={() => setMobileOpen(false)}
              className={`flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 ${
                active
                  ? 'bg-white/15 text-white shadow-sm'
                  : 'text-white/60 hover:bg-white/10 hover:text-white'
              }`}
            >
              {icon}
              {label}
            </Link>
          )
        })}
      </nav>

      <div className="p-4 border-t border-white/10">
        <div className="flex items-center gap-3 px-4 py-2 mb-2">
          <div className="w-8 h-8 rounded-full bg-[#0891B2] flex items-center justify-center text-sm font-bold">
            {profile?.full_name?.[0]?.toUpperCase()}
          </div>
          <div className="min-w-0">
            <p className="text-sm font-medium text-white truncate">{profile?.full_name}</p>
            <p className="text-xs text-white/50 font-mono">{profile?.role}</p>
          </div>
        </div>
        <button
          onClick={handleSignOut}
          className="flex items-center gap-2 w-full px-4 py-2 rounded-xl text-sm text-white/60 hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
        >
          <LogOut size={16} />
          Sign out
        </button>
      </div>
    </aside>
  )

  return (
    <div className="flex h-screen bg-[#ECFEFF]">
      {/* Desktop sidebar */}
      <div className="hidden lg:flex lg:w-64 lg:flex-col lg:flex-shrink-0">
        <Sidebar />
      </div>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div className="absolute inset-0 bg-black/40" onClick={() => setMobileOpen(false)} />
          <div className="absolute left-0 top-0 bottom-0 w-64 flex flex-col">
            <Sidebar />
          </div>
        </div>
      )}

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="bg-white border-b border-[#A5F3FC] px-4 lg:px-8 py-4 flex items-center justify-between">
          <button
            className="lg:hidden p-2 rounded-lg text-[#164E63] hover:bg-[#ECFEFF] cursor-pointer"
            onClick={() => setMobileOpen(!mobileOpen)}
          >
            {mobileOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
          <div className="flex items-center gap-2 ml-auto">
            <CommandPaletteTrigger />
            <button aria-label="Notifications" className="p-2 rounded-lg text-[#64748B] hover:bg-[#ECFEFF] relative cursor-pointer focus-visible:ring-2 focus-visible:ring-[#0891B2] focus-visible:outline-none">
              <Bell size={18} />
            </button>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-4 lg:p-8">
          {children}
        </main>
      </div>
      <CommandPalette />
    </div>
  )
}
