import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ngoNameCtrl = TextEditingController();
  final _ngoLocCtrl = TextEditingController();
  String _role = 'donor';
  bool _loading = false;
  bool _googleLoading = false;
  bool _showPass = false;
  String? _error;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _ngoNameCtrl.dispose(); _ngoLocCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final uid = res.user!.id;
      await Supabase.instance.client.from('profiles').insert({
        'id': uid, 'full_name': _nameCtrl.text.trim(),
        'role': _role, 'phone': _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text.trim() : null,
      });
      if (_role == 'ngo_admin') {
        await Supabase.instance.client.from('ngos').insert({
          'admin_id': uid, 'name': _ngoNameCtrl.text.trim(),
          'location': _ngoLocCtrl.text.trim(), 'contact_email': _emailCtrl.text.trim(),
        });
      }
      if (!mounted) return;
      context.go(_role == 'ngo_admin' ? '/ngo' : '/donor');
    } on AuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.needlink.app://login-callback',
      );
      if (mounted) setState(() => _googleLoading = false);
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _googleLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _googleLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 260,
            child: CustomPaint(painter: const NetworkPainter()),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const NLMark(),
                        const SizedBox(width: 10),
                        Text('NeedLink', style: GoogleFonts.jetBrainsMono(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold,
                        )),
                      ]),
                      const SizedBox(height: 24),
                      Text('Create account.', style: GoogleFonts.sora(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.15,
                      )),
                      const SizedBox(height: 5),
                      Text("Join Uganda's in-kind donation network.", style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 13,
                      )),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28), topRight: Radius.circular(28),
                      ),
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Role selector
                              Text('I am joining as', style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F2333),
                              )),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(child: _RoleCard(
                                  value: 'donor', selected: _role,
                                  icon: Icons.volunteer_activism_outlined,
                                  title: 'Donor', desc: 'Give items to NGOs',
                                  onTap: (v) => setState(() => _role = v),
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _RoleCard(
                                  value: 'ngo_admin', selected: _role,
                                  icon: Icons.business_outlined,
                                  title: 'NGO Admin', desc: 'Receive & manage donations',
                                  onTap: (v) => setState(() => _role = v),
                                )),
                              ]),

                              const SizedBox(height: 20),
                              if (_error != null) ...[
                                AuthErrorBox(_error!),
                                const SizedBox(height: 16),
                              ],

                              // Google button
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _googleLoading ? null : _googleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF0F2333),
                                  ),
                                  child: _googleLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          _GoogleLogo(),
                                          const SizedBox(width: 10),
                                          Text('Continue with Google', style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F2333),
                                          )),
                                        ]),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // OR divider
                              Row(children: [
                                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text('or', style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, color: const Color(0xFF94A3B8),
                                  )),
                                ),
                                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              ]),
                              const SizedBox(height: 20),

                              AuthField(controller: _nameCtrl, label: 'Full name', icon: Icons.person_outline_rounded),
                              const SizedBox(height: 14),
                              AuthField(
                                controller: _emailCtrl, label: 'Email address',
                                icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, autocorrect: false,
                              ),
                              const SizedBox(height: 14),
                              AuthField(controller: _phoneCtrl, label: 'Phone (optional)', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                              const SizedBox(height: 14),
                              AuthField(
                                controller: _passCtrl, label: 'Password',
                                icon: Icons.lock_outline_rounded, obscureText: !_showPass,
                                suffix: GestureDetector(
                                  onTap: () => setState(() => _showPass = !_showPass),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20, color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ),

                              AnimatedSize(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                child: _role == 'ngo_admin'
                                    ? _NgoSection(nameCtrl: _ngoNameCtrl, locCtrl: _ngoLocCtrl)
                                    : const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 24),
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kAccent, foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    disabledBackgroundColor: kAccent.withValues(alpha: 0.5),
                                  ),
                                  child: _loading
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                      : Text('Create account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),

                              const SizedBox(height: 20),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('Have an account? ', style: GoogleFonts.plusJakartaSans(color: kMutedFg, fontSize: 14)),
                                GestureDetector(
                                  onTap: () => context.go('/login'),
                                  child: Text('Sign in', style: GoogleFonts.plusJakartaSans(
                                    color: kPrimary, fontWeight: FontWeight.w600, fontSize: 14,
                                  )),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String value, selected, title, desc;
  final IconData icon;
  final void Function(String) onTap;

  const _RoleCard({
    required this.value, required this.selected, required this.icon,
    required this.title, required this.desc, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF0FAFE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? kPrimary : const Color(0xFFE8EDF2), width: 2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: active ? kPrimary : const Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF0F2333) : kMutedFg,
          )),
          const SizedBox(height: 2),
          Text(desc, style: GoogleFonts.plusJakartaSans(
            fontSize: 11, color: const Color(0xFF94A3B8), height: 1.3,
          )),
        ]),
      ),
    );
  }
}

// ── NGO section ───────────────────────────────────────────────────────────────

class _NgoSection extends StatelessWidget {
  final TextEditingController nameCtrl, locCtrl;
  const _NgoSection({required this.nameCtrl, required this.locCtrl});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 1, color: const Color(0xFFE8EDF2), margin: const EdgeInsets.only(bottom: 16)),
      Text('NGO DETAILS', style: GoogleFonts.jetBrainsMono(
        fontSize: 10, fontWeight: FontWeight.bold, color: kPrimary, letterSpacing: 1.5,
      )),
      const SizedBox(height: 14),
      AuthField(controller: nameCtrl, label: 'NGO name', icon: Icons.business_outlined),
      const SizedBox(height: 14),
      AuthField(controller: locCtrl, label: 'District / location', icon: Icons.location_on_outlined),
    ]),
  );
}

// ── Google logo ───────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20, height: 20,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.65);

    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.5, 1.57, false, arcPaint);
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.07, 1.57, false, arcPaint);
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.64, 0.79, false, arcPaint);
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.43, 1.0, false, arcPaint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.65, cy), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
