import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
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

// Listens to Supabase auth state changes and notifies GoRouter to re-evaluate
// its redirect (so post-OAuth sign-in routes correctly without manual navigation).
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier();
  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final uri = state.uri;

      // Intercept OAuth deep link before GoRouter tries to route it.
      // Supabase (via authCallbackUrlHostname) will exchange the code;
      // SplashScreen then waits for SIGNED_IN and routes by role.
      if (uri.scheme == 'io.needlink.app' || location == '/login-callback') {
        return '/splash';
      }

      // Root path falls through to splash
      if (location == '/') return '/splash';

      return null; // all other guards handled inside SplashScreen / individual pages
    },
    routes: [
      // Handles the OAuth deep link path after scheme stripping
      GoRoute(path: '/login-callback', redirect: (_, _) => '/splash'),

      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // ── Donor shell (persistent bottom nav) ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DonorShell(child: child),
        routes: [
          GoRoute(path: '/donor', builder: (_, _) => const DonorHomeScreen()),
          GoRoute(path: '/donor/pledges', builder: (_, _) => const MyPledgesScreen()),
          GoRoute(path: '/donor/profile', builder: (_, _) => const DonorProfileScreen()),
        ],
      ),
      // Donor detail screens (full-screen, no bottom nav)
      GoRoute(
        path: '/donor/need/:id',
        builder: (_, state) => NeedDetailScreen(needId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/donor/tracking/:id',
        builder: (_, state) => TrackingDetailScreen(pledgeId: state.pathParameters['id']!),
      ),

      // ── NGO shell (persistent bottom nav) ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => NgoShell(child: child),
        routes: [
          GoRoute(path: '/ngo', builder: (_, _) => const NgoHomeScreen()),
          GoRoute(path: '/ngo/pledges', builder: (_, _) => const NgoPledgesScreen()),
          GoRoute(path: '/ngo/reports', builder: (_, _) => const ImpactReportsScreen()),
          GoRoute(path: '/ngo/settings', builder: (_, _) => const NgoSettingsScreen()),
        ],
      ),
      // NGO detail screens (full-screen, no bottom nav)
      GoRoute(path: '/ngo/needs/new', builder: (_, _) => const CreateNeedScreen()),
    ],
  );
});
