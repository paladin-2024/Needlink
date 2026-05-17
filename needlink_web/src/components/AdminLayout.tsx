import AdminSidebar from './AdminSidebar'

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen" style={{ background: '#F0FDFF' }}>
      <AdminSidebar />
      <main className="flex-1 ml-[220px] min-h-screen overflow-y-auto">
        {children}
      </main>
    </div>
  )
}
