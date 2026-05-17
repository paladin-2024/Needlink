import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/donor/donor_home_screen.dart';
import 'screens/donor/need_detail_screen.dart';
import 'screens/donor/my_pledges_screen.dart';
import 'screens/donor/tracking_detail_screen.dart';
import 'screens/donor/profile_screen.dart';
import 'screens/ngo/ngo_home_screen.dart';
import 'screens/ngo/create_need_screen.dart';
import 'screens/ngo/ngo_pledges_screen.dart';
import 'screens/ngo/impact_reports_screen.dart';
import 'screens/ngo/ngo_settings_screen.dart';
import 'widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = Supabase.instance.client.auth.currentUser;
      final isAuth = user != null;
      final path = state.matchedLocation;

      if (!isAuth) {
        if (path == '/login' || path == '/register') return null;
        return '/login';
      }

      if (path == '/splash') return null;

      // Enforce role boundaries — fetch role from DB (cached by Supabase client)
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = profile?['role'] as String?;

      final isDonorPath = path.startsWith('/donor');
      final isNgoPath   = path.startsWith('/ngo');

      if (isDonorPath && role == 'ngo_admin') return '/ngo';
      if (isNgoPath   && role == 'donor')     return '/donor';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const _SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // Donor tabs (persistent bottom nav)
      ShellRoute(
        builder: (context, state, child) => DonorShell(child: child),
        routes: [
          GoRoute(path: '/donor', builder: (_, _) => const DonorHomeScreen()),
          GoRoute(path: '/donor/pledges', builder: (_, _) => const MyPledgesScreen()),
          GoRoute(path: '/donor/profile', builder: (_, _) => const DonorProfileScreen()),
        ],
      ),
      // Donor detail screens (no bottom nav)
      GoRoute(
        path: '/donor/need/:id',
        builder: (_, state) => NeedDetailScreen(needId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/donor/tracking/:id',
        builder: (_, state) => TrackingDetailScreen(pledgeId: state.pathParameters['id']!),
      ),

      // NGO tabs (persistent bottom nav)
      ShellRoute(
        builder: (context, state, child) => NgoShell(child: child),
        routes: [
          GoRoute(path: '/ngo', builder: (_, _) => const NgoHomeScreen()),
          GoRoute(path: '/ngo/pledges', builder: (_, _) => const NgoPledgesScreen()),
          GoRoute(path: '/ngo/reports', builder: (_, _) => const ImpactReportsScreen()),
          GoRoute(path: '/ngo/settings', builder: (_, _) => const NgoSettingsScreen()),
        ],
      ),
      // NGO detail screens (no bottom nav)
      GoRoute(path: '/ngo/needs/new', builder: (_, _) => const CreateNeedScreen()),
    ],
  );
});

class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.microtask(() async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (context.mounted) context.go('/login');
        return;
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (!context.mounted) return;
      if (data?['role'] == 'ngo_admin') {
        context.go('/ngo');
      } else {
        context.go('/donor');
      }
    });

    return const Scaffold(
      backgroundColor: Color(0xFFECFEFF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Logo(),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF0891B2), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: const Color(0xFF164E63), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 30),
      ),
      const SizedBox(height: 12),
      const Text('NeedLink', style: TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 28, color: Color(0xFF164E63))),
      const Text('Uganda · In-kind Donations', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
    ],
  );
}
