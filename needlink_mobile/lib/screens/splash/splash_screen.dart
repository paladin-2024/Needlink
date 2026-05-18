import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    var user = Supabase.instance.client.auth.currentUser;

    // Only show the full splash animation on first launch (no active session).
    if (user == null) {
      await Future.delayed(const Duration(milliseconds: 2400));
      if (!mounted) return;
    }

    if (user == null) {
      final completer = Completer<void>();
      late StreamSubscription<AuthState> sub;
      sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          if (!completer.isCompleted) completer.complete();
          sub.cancel();
        }
      });
      await completer.future
          .timeout(const Duration(seconds: 3), onTimeout: () {})
          .catchError((_) {});
      sub.cancel();
      user = Supabase.instance.client.auth.currentUser;
    }

    if (!mounted) return;

    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      if (mounted) context.go(onboardingDone ? '/login' : '/onboarding');
      return;
    }

    var profileData = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (profileData == null) {
      // First OAuth sign-in — no profile row exists yet. Create one now using
      // the role the user selected in the register screen (stored before OAuth
      // opened the browser), or default to 'donor'.
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('pending_oauth_role') ?? 'donor';
      final name = (user.userMetadata?['full_name'] as String?)
          ?? (user.userMetadata?['name'] as String?)
          ?? '';
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id, 'full_name': name, 'role': role,
      }, onConflict: 'id', ignoreDuplicates: true);
      await prefs.remove('pending_oauth_role');
      profileData = {'role': role};
    }

    if (!mounted) return;
    context.go(profileData['role'] == 'ngo_admin' ? '/ngo' : '/donor');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071D2C),
      body: Stack(
        children: [

          // ── Background: Lottie orbit animation ─────────────────────────────
          Positioned.fill(
            child: Lottie.asset(
              'assets/lottie/splash_orbit.json',
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),

          // ── Radial vignette overlay ─────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF071D2C).withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Logo mark — scale + fade in
                _LogoMark(size: 96)
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutQuart,
                    )
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut),

                const SizedBox(height: 28),

                // Wordmark — slide up + fade
                Column(
                  children: [
                    Text(
                      'NeedLink',
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate(delay: 300.ms)
                        .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOutQuart)
                        .fadeIn(duration: 500.ms),

                    const SizedBox(height: 8),

                    Text(
                      'Uganda · In-kind Donations',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A8A9A),
                        letterSpacing: 0.4,
                      ),
                    )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 600.ms),
                  ],
                ),

                const SizedBox(height: 60),

                // Loading indicator — fade in last
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF0AC8EC),
                    strokeWidth: 1.5,
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom logo mark (matches app icon) ──────────────────────────────────────

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _LogoPainter(),
      );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.215),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.32),
          radius: 0.9,
          colors: const [Color(0xFF1178A0), Color(0xFF071D2C)],
        ).createShader(Rect.fromLTWH(0, 0, s, s)),
    );

    final x1 = s * 0.2021;
    final x2 = s * 0.5098;
    final x3 = s * 0.7979;
    final y1 = s * 0.1934;
    final y2 = s * 0.8066;

    final path = Path()
      ..moveTo(x1, y1)
      ..lineTo(x1, y2)
      ..lineTo(x2, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y2);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.127
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.074
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      Offset(x3, y2),
      s * 0.043,
      Paint()..color = const Color(0xFF0AC8EC).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
