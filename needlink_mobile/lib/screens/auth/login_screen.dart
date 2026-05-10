import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      final profile = await Supabase.instance.client
          .from('profiles').select('role').eq('id', res.user!.id).single();
      if (!mounted) return;
      context.go(profile['role'] == 'ngo_admin' ? '/ngo' : '/donor');
    } on AuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
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
            top: 0, left: 0, right: 0, height: 300,
            child: CustomPaint(painter: const NetworkPainter()),
          ),
          Column(
            children: [
              // ── Dark header ──
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
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
                      const SizedBox(height: 28),
                      Text('Welcome back.', style: GoogleFonts.sora(
                        color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, height: 1.15,
                      )),
                      const SizedBox(height: 6),
                      Text('Sign in to your NeedLink account.', style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.5), fontSize: 14,
                      )),
                    ],
                  ),
                ),
              ),

              // ── White form panel ──
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_error != null) ...[
                                AuthErrorBox(_error!),
                                const SizedBox(height: 16),
                              ],

                              AuthField(
                                controller: _emailCtrl,
                                label: 'Email address',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                              ),
                              const SizedBox(height: 16),
                              AuthField(
                                controller: _passCtrl,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: !_showPass,
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
                              const SizedBox(height: 28),

                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    disabledBackgroundColor: kAccent.withOpacity(0.5),
                                  ),
                                  child: _loading
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                      : Text('Sign in', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),

                              const SizedBox(height: 24),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('No account? ', style: GoogleFonts.plusJakartaSans(color: kMutedFg, fontSize: 14)),
                                GestureDetector(
                                  onTap: () => context.go('/register'),
                                  child: Text('Create one', style: GoogleFonts.plusJakartaSans(
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
