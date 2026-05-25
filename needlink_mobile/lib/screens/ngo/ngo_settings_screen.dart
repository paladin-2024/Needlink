import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import '../../services/storage_service.dart';

class NgoSettingsScreen extends ConsumerStatefulWidget {
  const NgoSettingsScreen({super.key});
  @override
  ConsumerState<NgoSettingsScreen> createState() => _NgoSettingsScreenState();
}

class _NgoSettingsScreenState extends ConsumerState<NgoSettingsScreen> {
  bool _notifyPledges = true;
  bool _notifyDelivery = true;
  bool _notifySystem = false;
  bool _saving = false;
  bool _uploadingLogo = false;
  String? _newLogoUrl;

  late final _nameCtrl = TextEditingController();
  late final _regCtrl = TextEditingController();

  static const _shadow = [
    BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  @override
  void dispose() { _nameCtrl.dispose(); _regCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ngoAsync = ref.watch(myNgoProvider);

    return Scaffold(
      body: ngoAsync.when(
        data: (ngo) {
          if (ngo != null) {
            if (_nameCtrl.text.isEmpty) _nameCtrl.text = ngo.name;
            if (_regCtrl.text.isEmpty) _regCtrl.text = ngo.registrationNumber ?? '';
          }
          final initial = ngo?.name.isNotEmpty == true ? ngo!.name[0].toUpperCase() : 'N';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: kSurface,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('Settings', style: GoogleFonts.sora(
                        fontSize: 22, fontWeight: FontWeight.w800, color: kForeground,
                      ))),
                      TextButton.icon(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('cached_role');
                          await prefs.remove('pending_oauth_role');
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(HugeIcons.strokeRoundedLogout01, size: 15),
                        label: const Text('Logout'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                      ),
                    ]),
                    Text(
                      'Manage your organization\'s preferences.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
                    ),
                  ]),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // Org profile card
                  _SectionLabel(HugeIcons.strokeRoundedBuilding02, 'Organization Profile'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kSurface, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder), boxShadow: _shadow,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        GestureDetector(
                          onTap: _uploadingLogo || ngo == null ? null : () async {
                            setState(() => _uploadingLogo = true);
                            try {
                              final url = await StorageService.uploadNgoLogo(ngo.id);
                              if (url != null) {
                                setState(() => _newLogoUrl = url);
                                await Supabase.instance.client.from('ngos')
                                    .update({'logo_url': url}).eq('id', ngo.id);
                                ref.invalidate(myNgoProvider);
                              }
                            } catch (_) {} finally {
                              if (mounted) setState(() => _uploadingLogo = false);
                            }
                          },
                          child: _uploadingLogo
                              ? Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(child: SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: UserAvatar(
                                    seed: ngo?.id ?? 'ngo',
                                    initials: initial,
                                    avatarUrl: _newLogoUrl ?? ngo?.logoUrl,
                                    radius: 28,
                                    isOrg: true,
                                    showEditBadge: true,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ngo?.name ?? '', style: GoogleFonts.sora(
                            fontWeight: FontWeight.w800, fontSize: 15, color: kForeground,
                          )),
                          if (ngo?.verified == true)
                            Row(children: [
                              const Icon(HugeIcons.strokeRoundedCheckmarkBadge01, size: 13, color: kMatched),
                              const SizedBox(width: 4),
                              Text('Verified', style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: kMatched, fontWeight: FontWeight.w600,
                              )),
                            ]),
                          const SizedBox(height: 2),
                          Text('Tap logo to update', style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: kMutedFg,
                          )),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: const InputDecoration(labelText: 'Organization Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _regCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: const InputDecoration(labelText: 'Registration Number'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 46,
                        child: ElevatedButton(
                          onPressed: _saving ? null : () async {
                            if (ngo == null) return;
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _saving = true);
                            await Supabase.instance.client.from('ngos').update({
                              'name': _nameCtrl.text.trim(),
                              'registration_number': _regCtrl.text.trim().isNotEmpty ? _regCtrl.text.trim() : null,
                            }).eq('id', ngo.id);
                            ref.invalidate(myNgoProvider);
                            setState(() => _saving = false);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Changes saved'), backgroundColor: kMatched),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Save Changes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 22),

                  // Notifications
                  _SectionLabel(HugeIcons.strokeRoundedNotification01, 'Notification Preferences'),
                  const SizedBox(height: 10),
                  _ToggleCard(shadow: _shadow, items: [
                    _ToggleItem('New Donation Pledges', 'Alerts when a donor commits', _notifyPledges, (v) => setState(() => _notifyPledges = v)),
                    _ToggleItem('Delivery Updates', 'Status changes for in-transit items', _notifyDelivery, (v) => setState(() => _notifyDelivery = v)),
                    _ToggleItem('System Alerts', 'Critical security messages', _notifySystem, (v) => setState(() => _notifySystem = v)),
                  ]),
                  const SizedBox(height: 22),

                  // Security
                  _SectionLabel(HugeIcons.strokeRoundedSecurity, 'Transparency & Security'),
                  const SizedBox(height: 10),
                  _ListCard(shadow: _shadow, items: [
                    _ListItem(HugeIcons.strokeRoundedCheckmarkBadge01, 'Request Verification', ngo?.verified == true ? 'Verified' : null, () {
                      HapticFeedback.selectionClick();
                      if (ngo?.verified != true) context.push('/ngo/verification');
                    }),
                    _ListItem(HugeIcons.strokeRoundedLock, 'Update Password', null, () {}),
                    _ListItem(HugeIcons.strokeRoundedShield01, 'Two-Factor Authentication', 'Enabled', () {}),
                    _ListItem(HugeIcons.strokeRoundedView, 'Privacy Settings', null, () {}),
                  ]),
                  const SizedBox(height: 22),

                  // Support
                  _SectionLabel(HugeIcons.strokeRoundedInformationCircle, 'Support & Legal'),
                  const SizedBox(height: 10),
                  _ListCard(shadow: _shadow, items: [
                    _ListItem(HugeIcons.strokeRoundedHelpCircle, 'Help Center', null, () {}),
                    _ListItem(HugeIcons.strokeRoundedCourtLaw, 'Terms of Service', null, () {}),
                    _ListItem(HugeIcons.strokeRoundedFile01, 'Privacy Policy', null, () {}),
                  ]),
                  const SizedBox(height: 22),

                  // Danger zone
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Danger Zone', style: GoogleFonts.sora(
                        fontWeight: FontWeight.w800, color: const Color(0xFFDC2626),
                      )),
                      const SizedBox(height: 4),
                      Text('These actions are irreversible.', style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: kMutedFg,
                      )),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('cached_role');
                          await prefs.remove('pending_oauth_role');
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                        ),
                        child: const Text('Sign Out'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        child: const Text('Deactivate Account'),
                      ),
                    ]),
                  ),
                ])),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionLabel(this.icon, this.title);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: kPrimary),
    const SizedBox(width: 7),
    Text(title.toUpperCase(), style: GoogleFonts.sora(
      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
    )),
  ]);
}

// ── Toggle item / card ────────────────────────────────────────────────────────

class _ToggleItem {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleItem(this.title, this.subtitle, this.value, this.onChanged);
}

class _ToggleCard extends StatelessWidget {
  final List<_ToggleItem> items;
  final List<BoxShadow> shadow;
  const _ToggleCard({required this.items, required this.shadow});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder), boxShadow: shadow,
    ),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      SwitchListTile(
        title: Text(e.value.title, style: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: kForeground,
        )),
        subtitle: Text(e.value.subtitle, style: const TextStyle(fontSize: 12, color: kMutedFg)),
        value: e.value.value,
        onChanged: e.value.onChanged,
        activeThumbColor: kPrimary,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      if (e.key < items.length - 1) const Divider(height: 1, color: kBorder),
    ])).toList()),
  );
}

// ── List item / card ──────────────────────────────────────────────────────────

class _ListItem {
  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;
  const _ListItem(this.icon, this.title, this.badge, this.onTap);
}

class _ListCard extends StatelessWidget {
  final List<_ListItem> items;
  final List<BoxShadow> shadow;
  const _ListCard({required this.items, required this.shadow});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder), boxShadow: shadow,
    ),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      ListTile(
        leading: Icon(e.value.icon, size: 20, color: kMutedFg),
        title: Text(e.value.title, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: kForeground)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (e.value.badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: kMatched.withAlpha(25), borderRadius: BorderRadius.circular(20)),
              child: Text(e.value.badge!, style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: kMatched,
              )),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(HugeIcons.strokeRoundedArrowRight01, size: 18, color: kMutedFg),
        ]),
        onTap: e.value.onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      if (e.key < items.length - 1) const Divider(height: 1, color: kBorder),
    ])).toList()),
  );
}
