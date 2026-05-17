import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import { ToastProvider } from './components/Toast'
import AdminLogin from './pages/auth/Login'
import AdminLayout from './components/AdminLayout'
import Overview from './pages/admin/Overview'
import NgoManagement from './pages/admin/NgoManagement'
import UserManagement from './pages/admin/UserManagement'
import NeedsOverview from './pages/admin/NeedsOverview'
import PledgesOverview from './pages/admin/PledgesOverview'
import Reports from './pages/admin/Reports'
import Settings from './pages/admin/Settings'

function AdminRoute({ children }: { children: React.ReactNode }) {
  const { user, profile, loading } = useAuth()

  if (loading) return (
    <div className="min-h-screen flex items-center justify-center" style={{ background: '#0C1A22' }}>
      <div className="w-8 h-8 border-2 border-[#0891B2] border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (!user || profile?.role !== 'super_admin') return <Navigate to="/login" replace />
  return <AdminLayout>{children}</AdminLayout>
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ToastProvider>
        <Routes>
          <Route path="/login" element={<AdminLogin />} />
          <Route path="/admin" element={<Navigate to="/admin/overview" replace />} />
          <Route path="/admin/overview"  element={<AdminRoute><Overview /></AdminRoute>} />
          <Route path="/admin/ngos"      element={<AdminRoute><NgoManagement /></AdminRoute>} />
          <Route path="/admin/users"     element={<AdminRoute><UserManagement /></AdminRoute>} />
          <Route path="/admin/needs"     element={<AdminRoute><NeedsOverview /></AdminRoute>} />
          <Route path="/admin/pledges"   element={<AdminRoute><PledgesOverview /></AdminRoute>} />
          <Route path="/admin/reports"   element={<AdminRoute><Reports /></AdminRoute>} />
          <Route path="/admin/settings"  element={<AdminRoute><Settings /></AdminRoute>} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
        </ToastProvider>
      </AuthProvider>
    </BrowserRouter>
  )
}
