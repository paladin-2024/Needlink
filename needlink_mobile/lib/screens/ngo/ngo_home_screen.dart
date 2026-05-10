import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers.dart';
import '../../theme.dart';

class NgoHomeScreen extends ConsumerWidget {
  const NgoHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final ngoAsync = ref.watch(myNgoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ngo/needs/new'),
        backgroundColor: kAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Need', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // NGO name
          ngoAsync.when(
            data: (ngo) => ngo != null ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kForeground, kPrimaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(ngo.name, style: const TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${ngo.location} · ${ngo.contactEmail}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                if (!ngo.verified) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Pending verification', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ),
                ],
              ]),
            ) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),

          // Quick actions
          const Text('Quick Actions', style: TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 16, color: kForeground)),
          const SizedBox(height: 12),
          Row(children: [
            _ActionCard(icon: Icons.add_circle_outline, label: 'Post Need', color: kAccent, onTap: () => context.go('/ngo/needs/new')),
            const SizedBox(width: 12),
            _ActionCard(icon: Icons.checklist_outlined, label: 'Pledges', color: kPrimary, onTap: () => context.go('/ngo/pledges')),
          ]),

          const SizedBox(height: 20),

          // Profile
          profileAsync.when(
            data: (profile) => profile != null ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(22)),
                  child: Center(child: Text(
                    profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: kForeground)),
                  Text(profile.role, style: const TextStyle(fontSize: 12, color: kMutedFg, fontFamily: 'FiraCode')),
                ])),
              ]),
            ) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ]),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground)),
        ]),
      ),
    ),
  );
}
