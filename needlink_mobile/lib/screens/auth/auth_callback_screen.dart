import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shown when the app is opened via the OAuth deep link
/// (io.needlink.app://login-callback). Has no splash animation — just a
/// spinner — so returning from Google/OAuth doesn't replay the splash screen.
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    final prefs = await SharedPreferences.getInstance();
    var user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      final completer = Completer<void>();
      late StreamSubscription<AuthState> sub;
      sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn && !completer.isCompleted) {
          completer.complete();
          sub.cancel();
        }
      });
      await completer.future
          .timeout(const Duration(seconds: 10), onTimeout: () {})
          .catchError((_) {});
      sub.cancel();
      user = Supabase.instance.client.auth.currentUser;
    }

    if (!mounted) return;

    if (user == null) {
      context.go('/login');
      return;
    }

    // Always fetch fresh role from DB — never trust stale cached_role on OAuth.
    var profileData = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (profileData == null) {
      final pendingRole = prefs.getString('pending_oauth_role') ?? 'donor';
      final name = (user.userMetadata?['full_name'] as String?)
          ?? (user.userMetadata?['name'] as String?)
          ?? '';
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id, 'full_name': name, 'role': pendingRole,
      }, onConflict: 'id', ignoreDuplicates: true);
      await prefs.remove('pending_oauth_role');
      profileData = {'role': pendingRole};
    }

    if (!mounted) return;
    final role = profileData['role'] as String? ?? 'donor';
    await prefs.setString('cached_role', role);
    context.go(role == 'ngo_admin' ? '/ngo' : '/donor');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF071D2C),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0AC8EC),
          strokeWidth: 1.5,
        ),
      ),
    );
  }
}
