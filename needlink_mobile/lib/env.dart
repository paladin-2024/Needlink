// The anon key is intentionally public (safe to embed in mobile apps).
// Supabase RLS enforces all data access rules server-side.
// For CI/CD pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://gdbhdbobqkngcasykjzq.supabase.co');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_CB3fHPHydP38Ye1I16QKQg_VDVt2pTA');
