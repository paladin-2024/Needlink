import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;
  late AnimationController _dotCtrl;

  static const _slides = [
    _Slide(
      svgAsset: 'assets/illustrations/onboard_give.svg',
      accent: Color(0xFF0AC8EC),
      title: 'Give What Matters',
      body:
          'Connect surplus food, clothing, medicine, and supplies with NGOs that need them most across Uganda.',
    ),
    _Slide(
      svgAsset: 'assets/illustrations/onboard_link.svg',
      accent: Color(0xFF7C3AED),
      title: 'Link Up With NGOs',
      body:
          'Browse verified organisations, follow their needs, and pledge exactly what they are asking for.',
    ),
    _Slide(
      svgAsset: 'assets/illustrations/onboard_track.svg',
      accent: Color(0xFF16A34A),
      title: 'Track Every Step',
      body:
          'Follow your donation from pledge to confirmed delivery. Every contribution is fully visible.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final isLast = _page == _slides.length - 1;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF071D2C),
      body: Stack(
        children: [

          // ── Floating particles background (Lottie) ───────────────────────
          Positioned.fill(
            child: Lottie.asset(
              'assets/lottie/onboard_particles.json',
              fit: BoxFit.fill,
              repeat: true,
            ),
          ),

          // ── Accent color wash — morphs per slide ─────────────────────────
          AnimatedPositioned(
            duration: 600.ms,
            curve: Curves.easeInOut,
            top: -120,
            left: _page == 0 ? -60 : _page == 1 ? size.width * 0.3 : size.width * 0.5,
            child: AnimatedContainer(
              duration: 600.ms,
              curve: Curves.easeInOut,
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    slide.accent.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // ── Top bar ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                  child: Row(
                    children: [
                      _MiniLogo(),
                      const SizedBox(width: 10),
                      const Text(
                        'NeedLink',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4A6B7A),
                          ),
                          child: const Text('Skip', style: TextStyle(fontSize: 13)),
                        ),
                    ],
                  ),
                ),

                // ── Page view ───────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) => _SlidePage(slide: _slides[i], isActive: i == _page),
                  ),
                ),

                // ── Dots + CTA ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 44),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (i) => _Dot(active: i == _page, color: _slides[_page].accent),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // CTA button
                      AnimatedContainer(
                        duration: 350.ms,
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              slide.accent,
                              slide.accent.withValues(alpha: 0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: slide.accent.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _next,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: 220.ms,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  key: ValueKey(isLast),
                                  children: [
                                    Text(
                                      isLast ? 'Get Started' : 'Next',
                                      style: const TextStyle(
                                        fontFamily: 'Sora',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (!isLast) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 18),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide model ──────────────────────────────────────────────────────────────

class _Slide {
  final String svgAsset;
  final Color accent;
  final String title;
  final String body;
  const _Slide({
    required this.svgAsset,
    required this.accent,
    required this.title,
    required this.body,
  });
}

// ── Individual slide page ────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  final bool isActive;
  const _SlidePage({required this.slide, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG illustration with reveal animation
          SvgPicture.asset(
            slide.svgAsset,
            width: double.infinity,
            height: 240,
            fit: BoxFit.contain,
          )
              .animate(key: ValueKey(slide.svgAsset))
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 44),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: 26,
              color: Colors.white,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          )
              .animate(key: ValueKey('title_${slide.svgAsset}'))
              .slideY(begin: 0.25, end: 0, duration: 450.ms, delay: 100.ms, curve: Curves.easeOutQuart)
              .fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 16),

          // Body
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5A8A9A),
              height: 1.65,
            ),
          )
              .animate(key: ValueKey('body_${slide.svgAsset}'))
              .slideY(begin: 0.2, end: 0, duration: 450.ms, delay: 180.ms, curve: Curves.easeOutQuart)
              .fadeIn(duration: 400.ms, delay: 180.ms),
        ],
      ),
    );
  }
}

// ── Animated progress dot ────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final bool active;
  final Color color;
  const _Dot({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 280.ms,
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 3.5),
      width: active ? 22 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? color : const Color(0xFF1A3A4A),
        borderRadius: BorderRadius.circular(3),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 0)]
            : null,
      ),
    );
  }
}

// ── Mini logo for top bar ────────────────────────────────────────────────────

class _MiniLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(30, 30),
        painter: _MiniLogoPainter(),
      );
}

class _MiniLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(s * 0.22)),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: const [Color(0xFF1178A0), Color(0xFF071D2C)],
        ).createShader(Rect.fromLTWH(0, 0, s, s)),
    );
    final path = Path()
      ..moveTo(s * 0.20, s * 0.19)
      ..lineTo(s * 0.20, s * 0.81)
      ..lineTo(s * 0.51, s * 0.19)
      ..lineTo(s * 0.51, s * 0.81)
      ..lineTo(s * 0.80, s * 0.81);
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
      Offset(s * 0.80, s * 0.81),
      s * 0.043,
      Paint()..color = const Color(0xFF0AC8EC).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
