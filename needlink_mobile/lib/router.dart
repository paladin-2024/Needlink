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
import 'screens/donor/saved_needs_screen.dart';
import 'screens/donor/notifications_screen.dart';
import 'screens/donor/ngo_map_screen.dart';
import 'screens/ngo/ngo_home_screen.dart';
import 'screens/ngo/create_need_screen.dart';
import 'screens/ngo/ngo_pledges_screen.dart';
import 'screens/ngo/impact_reports_screen.dart';
import 'screens/ngo/ngo_analytics_screen.dart';
import 'screens/ngo/ngo_settings_screen.dart';
import 'screens/ngo/verification_request_screen.dart';
import 'widgets/app_shell.dart';

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

      if (uri.scheme == 'io.needlink.app' || location == '/login-callback') {
        return '/splash';
      }

      if (location == '/') return '/splash';

      return null;
    },
    routes: [
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
      // Donor full-screen routes
      GoRoute(
        path: '/donor/need/:id',
        builder: (_, state) => NeedDetailScreen(needId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/donor/tracking/:id',
        builder: (_, state) => TrackingDetailScreen(pledgeId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/donor/saved', builder: (_, _) => const SavedNeedsScreen()),
      GoRoute(path: '/donor/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/donor/map', builder: (_, _) => const NgoMapScreen()),

      // ── NGO shell (persistent bottom nav) ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => NgoShell(child: child),
        routes: [
          GoRoute(path: '/ngo', builder: (_, _) => const NgoHomeScreen()),
          GoRoute(path: '/ngo/analytics', builder: (_, _) => const NgoAnalyticsScreen()),
          GoRoute(path: '/ngo/reports', builder: (_, _) => const ImpactReportsScreen()),
          GoRoute(path: '/ngo/pledges', builder: (_, _) => const NgoPledgesScreen()),
          GoRoute(path: '/ngo/settings', builder: (_, _) => const NgoSettingsScreen()),
        ],
      ),
      // NGO full-screen routes
      GoRoute(path: '/ngo/needs/new', builder: (_, _) => const CreateNeedScreen()),
      GoRoute(path: '/ngo/needs/new/:templateId',
        builder: (_, state) => CreateNeedScreen(templateId: state.pathParameters['templateId'])),
      GoRoute(path: '/ngo/verification', builder: (_, _) => const VerificationRequestScreen()),
    ],
  );
});
