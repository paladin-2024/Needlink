import AdminSidebar from './AdminSidebar'

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen" style={{ background: '#F3F5F8' }}>
      <AdminSidebar />
      <main className="flex-1 ml-[240px] min-h-screen overflow-y-auto">
        {children}
      </main>
    </div>
  )
}
