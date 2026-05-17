// The anon key is intentionally public (safe to embed in mobile apps).
// Supabase RLS enforces all data access rules server-side.
// For CI/CD pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://bxkztuzxnjqrgpyisqmn.supabase.co');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_6PA8svoNE_4SnZamQLmITQ_9bZ7dcj1');
