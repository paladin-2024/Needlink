import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import { ToastProvider } from './components/Toast'
import Layout from './components/Layout'
import Login from './pages/auth/Login'
import Register from './pages/auth/Register'
import DonorHome from './pages/donor/DonorHome'
import NeedDetail from './pages/donor/NeedDetail'
import MyPledges from './pages/donor/MyPledges'
import NgoDashboard from './pages/ngo/NgoDashboard'
import NgoNeeds from './pages/ngo/NgoNeeds'
import CreateNeed from './pages/ngo/CreateNeed'
import NgoPledges from './pages/ngo/NgoPledges'
import NgoReports from './pages/ngo/NgoReports'
import Landing from './pages/Landing'

function ProtectedRoute({ children, requiredRole }: { children: React.ReactNode; requiredRole?: 'donor' | 'ngo_admin' }) {
  const { user, profile, loading } = useAuth()

  if (loading) return (
    <div className="min-h-screen bg-[#ECFEFF] flex items-center justify-center">
      <div className="w-10 h-10 border-3 border-[#0891B2] border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (!user) return <Navigate to="/login" replace />
  if (requiredRole && profile?.role !== requiredRole) {
    return <Navigate to={profile?.role === 'ngo_admin' ? '/ngo' : '/donor'} replace />
  }

  return <Layout>{children}</Layout>
}

function RootRedirect() {
  const { user, profile, loading } = useAuth()
  if (loading) return null
  if (user) return <Navigate to={profile?.role === 'ngo_admin' ? '/ngo' : '/donor'} replace />
  return <Landing />
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ToastProvider>
        <Routes>
          <Route path="/" element={<RootRedirect />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />

          {/* Donor routes */}
          <Route path="/donor" element={<ProtectedRoute requiredRole="donor"><DonorHome /></ProtectedRoute>} />
          <Route path="/donor/need/:id" element={<ProtectedRoute requiredRole="donor"><NeedDetail /></ProtectedRoute>} />
          <Route path="/donor/pledges" element={<ProtectedRoute requiredRole="donor"><MyPledges /></ProtectedRoute>} />

          {/* NGO Admin routes */}
          <Route path="/ngo" element={<ProtectedRoute requiredRole="ngo_admin"><NgoDashboard /></ProtectedRoute>} />
          <Route path="/ngo/needs" element={<ProtectedRoute requiredRole="ngo_admin"><NgoNeeds /></ProtectedRoute>} />
          <Route path="/ngo/needs/new" element={<ProtectedRoute requiredRole="ngo_admin"><CreateNeed /></ProtectedRoute>} />
          <Route path="/ngo/pledges" element={<ProtectedRoute requiredRole="ngo_admin"><NgoPledges /></ProtectedRoute>} />
          <Route path="/ngo/reports" element={<ProtectedRoute requiredRole="ngo_admin"><NgoReports /></ProtectedRoute>} />
        </Routes>
        </ToastProvider>
      </AuthProvider>
    </BrowserRouter>
  )
}
