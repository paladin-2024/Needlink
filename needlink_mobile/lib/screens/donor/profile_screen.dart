import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers.dart';
import '../../theme.dart';

class DonorProfileScreen extends ConsumerWidget {
  const DonorProfileScreen({super.key});

  static const _shadow = [
    BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final pledgesAsync = ref.watch(myPledgesProvider);

    return Scaffold(
      body: profileAsync.when(
        data: (profile) => pledgesAsync.when(
          data: (pledges) {
            final totalItems = pledges.fold<int>(0, (s, p) => s + p.quantity);
            final ngoIds = pledges.map((p) => p.donationNeed?.ngoId).whereType<String>().toSet().length;
            final recent = pledges.take(3).toList();
            final initial = profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : '?';
            final tier = pledges.length >= 10 ? 'Platinum Donor' : pledges.length >= 5 ? 'Gold Donor' : 'Active Donor';

            return CustomScrollView(
              slivers: [
                // ── Gradient hero header ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-0.4, -1), end: Alignment(1, 0.6),
                        colors: [Color(0xFF0C4A6E), Color(0xFF0891B2)],
                      ),
                    ),
                    child: Stack(children: [
                      Positioned.fill(child: CustomPaint(painter: _DotPainter())),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          child: Column(children: [
                            Row(children: [
                              Text('Profile', style: GoogleFonts.sora(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
                              )),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                                onPressed: () {},
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                              ),
                            ]),
                            const SizedBox(height: 20),
                            Stack(children: [
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF164E63), Color(0xFF0891B2)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: Colors.white.withAlpha(60), width: 2),
                                ),
                                child: Center(child: Text(initial, style: GoogleFonts.sora(
                                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900,
                                ))),
                              ),
                              Positioned(bottom: 0, right: 0, child: Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(color: kMatched, shape: BoxShape.circle),
                                child: const Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                              )),
                            ]),
                            const SizedBox(height: 10),
                            Text(profile?.fullName ?? '', style: GoogleFonts.sora(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
                            )),
                            const SizedBox(height: 2),
                            Text(
                              Supabase.instance.client.auth.currentUser?.email ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.6), fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withAlpha(50)),
                              ),
                              child: Text(tier, style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                              )),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit_outlined, size: 15, color: Colors.white),
                              label: Text('Edit Profile', style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: Colors.white,
                              )),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withAlpha(80)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList(delegate: SliverChildListDelegate([

                    // Stats tiles
                    Row(children: [
                      _StatTile('${pledges.length}', 'Total\nPledges', Icons.volunteer_activism, kPrimary),
                      const SizedBox(width: 10),
                      _StatTile('$totalItems', 'Items\nGiven', Icons.inventory_2_rounded, kAccent),
                      const SizedBox(width: 10),
                      _StatTile('$ngoIds', 'NGOs\nSupported', Icons.corporate_fare_rounded, kMatched),
                    ]),
                    const SizedBox(height: 22),

                    // Recent contributions
                    if (recent.isNotEmpty) ...[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('RECENT CONTRIBUTIONS', style: GoogleFonts.sora(
                          fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
                        )),
                        GestureDetector(
                          onTap: () => context.go('/donor/pledges'),
                          child: Text('View All', style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600,
                          )),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      ...recent.map((p) => _ContributionTile(pledge: p)),
                      const SizedBox(height: 22),
                    ],

                    // Settings section
                    Text('SETTINGS', style: GoogleFonts.sora(
                      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 10),
                    _SettingsGroup(shadow: _shadow, items: [
                      _SettingsTile(Icons.notifications_outlined, 'Notification Preferences', () {}),
                      _SettingsTile(Icons.visibility_outlined, 'Profile Visibility', () {}),
                      _SettingsTile(Icons.lock_outline_rounded, 'Privacy & Safety', () {}),
                    ]),
                    const SizedBox(height: 12),
                    _SettingsGroup(shadow: _shadow, items: [
                      _SettingsTile(Icons.logout_rounded, 'Sign Out', () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) context.go('/login');
                      }, danger: true),
                    ]),
                  ])),
                ),
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

// ── Stat tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatTile(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFF), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: kMutedFg, height: 1.3), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Contribution tile ─────────────────────────────────────────────────────────

class _ContributionTile extends StatelessWidget {
  final dynamic pledge;
  const _ContributionTile({required this.pledge});

  @override
  Widget build(BuildContext context) {
    final status = pledge.status as String;
    final (bgColor, fgColor, label) = switch (status) {
      'confirmed' => (const Color(0xFFF0FDF4), kMatched, 'COMPLETED'),
      'rejected' => (const Color(0xFFFEF2F2), const Color(0xFFDC2626), 'REJECTED'),
      _ => (const Color(0xFFFFFBEB), const Color(0xFFD97706), 'PENDING'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.volunteer_activism, size: 18, color: kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            pledge.donationNeed?.itemName ?? 'Donation',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${pledge.donationNeed?.ngo?.name ?? ''} · ${pledge.quantity} units',
            style: const TextStyle(fontSize: 11, color: kMutedFg),
          ),
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

// ── Settings group ────────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> items;
  final List<BoxShadow> shadow;
  const _SettingsGroup({required this.items, required this.shadow});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder), boxShadow: shadow,
    ),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      e.value,
      if (e.key < items.length - 1) const Divider(height: 1, color: kBorder),
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

// ── Dot pattern painter ───────────────────────────────────────────────────────

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(12);
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
