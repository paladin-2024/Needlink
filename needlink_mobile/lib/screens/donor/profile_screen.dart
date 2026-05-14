import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers.dart';
import '../../theme.dart';

class DonorProfileScreen extends ConsumerWidget {
  const DonorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final pledgesAsync = ref.watch(myPledgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeedLink'),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
      ),
      body: profileAsync.when(
        data: (profile) => pledgesAsync.when(
          data: (pledges) {
            final totalItems = pledges.fold<int>(0, (s, p) => s + p.quantity);
            final ngoIds = pledges.map((p) => p.donationNeed?.ngoId).whereType<String>().toSet().length;
            final recent = pledges.take(3).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder),
                  ),
                  child: Column(children: [
                    Stack(children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: kPrimary,
                        child: Text(
                          profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Positioned(bottom: 0, right: 0, child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(color: kMatched, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Text(profile?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kForeground)),
                    const SizedBox(height: 2),
                    Text(Supabase.instance.client.auth.currentUser?.email ?? '',
                      style: const TextStyle(fontSize: 13, color: kMutedFg)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Text(
                        pledges.length >= 10 ? 'Platinum Donor' : pledges.length >= 5 ? 'Gold Donor' : 'Donor',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFC2410C)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(foregroundColor: kPrimary, side: const BorderSide(color: kPrimary)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(children: [
                  _StatCard('${pledges.length}', 'Total\nPledges', Icons.volunteer_activism, kPrimary),
                  const SizedBox(width: 10),
                  _StatCard('$totalItems', 'Items\nDonated', Icons.inventory_2_rounded, kAccent),
                  const SizedBox(width: 10),
                  _StatCard('$ngoIds', 'NGOs\nSupported', Icons.corporate_fare_rounded, kMatched),
                ]),
                const SizedBox(height: 20),

                // Recent contributions
                if (recent.isNotEmpty) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Recent Contributions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kForeground)),
                    TextButton(onPressed: () => context.go('/donor/pledges'), child: const Text('View All')),
                  ]),
                  const SizedBox(height: 8),
                  ...recent.map((p) => _ContributionTile(pledge: p)),
                  const SizedBox(height: 20),
                ],

                // Settings
                const Text('Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kForeground)),
                const SizedBox(height: 8),
                _SettingsGroup(items: [
                  _SettingsTile(Icons.notifications_outlined, 'Notification Preferences', () {}),
                  _SettingsTile(Icons.visibility_outlined, 'Profile Visibility', () {}),
                  _SettingsTile(Icons.lock_outline_rounded, 'Privacy & Safety', () {}),
                ]),
                const SizedBox(height: 16),
                _SettingsGroup(items: [
                  _SettingsTile(Icons.logout_rounded, 'Sign Out', () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go('/login');
                  }, danger: true),
                ]),
                const SizedBox(height: 30),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: kMutedFg, height: 1.3), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ContributionTile extends StatelessWidget {
  final dynamic pledge;
  const _ContributionTile({required this.pledge});

  @override
  Widget build(BuildContext context) {
    final status = pledge.status as String;
    final (bgColor, fgColor) = switch (status) {
      'confirmed' => (const Color(0xFFF0FDF4), kMatched),
      'rejected' => (const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
      _ => (const Color(0xFFFFFBEB), const Color(0xFFD97706)),
    };
    final label = switch (status) {
      'confirmed' => 'COMPLETED',
      'rejected' => 'REJECTED',
      _ => 'PENDING',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.volunteer_activism, size: 18, color: kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pledge.donationNeed?.itemName ?? 'Donation',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${pledge.donationNeed?.ngo?.name ?? ''} · ${pledge.quantity} units',
            style: const TextStyle(fontSize: 11, color: kMutedFg)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fgColor)),
        ),
      ]),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
    ),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      e.value,
      if (e.key < items.length - 1) const Divider(height: 1),
    ])).toList()),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _SettingsTile(this.icon, this.label, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 20, color: danger ? const Color(0xFFDC2626) : kMutedFg),
    title: Text(label, style: TextStyle(fontSize: 14, color: danger ? const Color(0xFFDC2626) : kForeground)),
    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: kMutedFg),
    onTap: onTap,
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}
