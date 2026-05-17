import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, Building2, Users, Package,
  ArrowLeftRight, BarChart3, Settings2, LogOut, Bell,
} from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import NeedLinkLogo from './NeedLinkLogo'
import { supabase } from '../lib/supabase'

const MANAGEMENT = [
  { path: '/admin/overview', label: 'Overview',  Icon: LayoutDashboard },
  { path: '/admin/ngos',     label: 'NGOs',       Icon: Building2 },
  { path: '/admin/users',    label: 'Donors',     Icon: Users },
  { path: '/admin/needs',    label: 'Needs',      Icon: Package },
  { path: '/admin/notices',  label: 'Notices',    Icon: Bell },
]

const SYSTEM = [
  { path: '/admin/pledges',  label: 'Pledges',    Icon: ArrowLeftRight },
  { path: '/admin/reports',  label: 'Reports',    Icon: BarChart3 },
  { path: '/admin/settings', label: 'Settings',   Icon: Settings2 },
]

function NavItem({ path, label, Icon }: { path: string; label: string; Icon: React.ComponentType<{ size?: number }> }) {
  return (
    <NavLink
      to={path}
      className={({ isActive }) =>
        `flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-[13px] transition-all duration-150 ${
          isActive
            ? 'text-white font-semibold'
            : 'font-medium text-[#4A6B7A] hover:text-[#8DCFDF] hover:bg-white/[0.04]'
        }`
      }
      style={({ isActive }) =>
        isActive ? { background: 'rgba(8,145,178,0.22)' } : {}
      }
    >
      <Icon size={14} />
      {label}
    </NavLink>
  )
}

export default function AdminSidebar() {
  const { profile } = useAuth()
  const navigate = useNavigate()

  async function handleSignOut() {
    await supabase.auth.signOut()
    navigate('/login')
  }

  const initial = profile?.full_name?.charAt(0).toUpperCase() ?? 'A'

  return (
    <aside
      className="fixed top-0 left-0 h-screen w-[240px] flex flex-col z-40 overflow-y-auto"
      style={{ background: '#0C1A22', borderRight: '1px solid rgba(255,255,255,0.04)' }}
    >
      {/* Logo */}
      <div className="px-5 pt-6 pb-5" style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
        <div className="flex items-center gap-2.5">
          <NeedLinkLogo size={28} />
          <div>
            <p className="font-heading font-bold text-white text-[13px] leading-tight">NeedLink</p>
            <p className="text-[#4A8A9A] text-[10px] font-mono tracking-[0.18em] uppercase leading-tight mt-0.5">
              Admin Portal
            </p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-5">
        <div>
          <p className="px-3 mb-1.5 text-[10px] font-semibold text-[#2A4A5A] uppercase tracking-[0.15em]">
            Management
          </p>
          <div className="space-y-0.5">
            {MANAGEMENT.map(item => <NavItem key={item.path} {...item} />)}
          </div>
        </div>

        <div>
          <p className="px-3 mb-1.5 text-[10px] font-semibold text-[#2A4A5A] uppercase tracking-[0.15em]">
            System
          </p>
          <div className="space-y-0.5">
            {SYSTEM.map(item => <NavItem key={item.path} {...item} />)}
          </div>
        </div>
      </nav>

      {/* Footer */}
      <div className="px-4 py-4" style={{ borderTop: '1px solid rgba(255,255,255,0.05)' }}>
        <div className="flex items-center gap-2.5 mb-3">
          <div
            className="w-7 h-7 rounded-lg flex items-center justify-center text-xs font-bold text-white flex-shrink-0"
            style={{ background: '#0E3D52' }}
          >
            {initial}
          </div>
          <p className="text-[#5A8A9A] text-[11px] font-mono truncate" title={profile?.full_name ?? ''}>
            {profile?.full_name ?? 'Admin'}
          </p>
        </div>
        <button
          onClick={handleSignOut}
          className="flex items-center gap-2 text-[#3A5A6A] hover:text-[#EF4444] text-[12px] font-medium transition-colors cursor-pointer"
        >
          <LogOut size={13} />
          Sign out
        </button>
      </div>
    </aside>
  )
}
