import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import '../../services/storage_service.dart';

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
                              Stack(alignment: Alignment.center, children: [
                              IconButton(
                                icon: const Icon(HugeIcons.strokeRoundedNotification01, color: Colors.white, size: 22),
                                onPressed: () => context.push('/donor/notifications'),
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                              ),
                              Consumer(builder: (_, profileConsumerRef, child) {
                                final count = profileConsumerRef.watch(unreadNotificationCountProvider);
                                if (count == 0) return const SizedBox.shrink();
                                return Positioned(
                                  top: 0, right: 0,
                                  child: Container(
                                    width: 14, height: 14,
                                    decoration: const BoxDecoration(color: kUrgent, shape: BoxShape.circle),
                                    child: Center(child: Text('$count', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white))),
                                  ),
                                );
                              }),
                            ]),
                            ]),
                            const SizedBox(height: 20),
                            Stack(children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withAlpha(60), width: 2),
                                ),
                                child: UserAvatar(
                                  seed: profile?.id ?? 'default',
                                  initials: profile?.fullName.isNotEmpty == true ? profile!.fullName[0] : '?',
                                  avatarUrl: profile?.avatarUrl,
                                  radius: 36,
                                ),
                              ),
                              Positioned(bottom: 2, right: 2, child: Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(color: kMatched, shape: BoxShape.circle),
                                child: const Icon(HugeIcons.strokeRoundedCheckmarkBadge01, size: 13, color: Colors.white),
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
                              onPressed: profile != null ? () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _EditProfileSheet(
                                  profile: profile,
                                  onSaved: () => ref.invalidate(profileProvider),
                                ),
                              ) : null,
                              icon: const Icon(HugeIcons.strokeRoundedPencilEdit01, size: 15, color: Colors.white),
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
                      _StatTile('${pledges.length}', 'Total\nPledges', HugeIcons.strokeRoundedCharity, kPrimary),
                      const SizedBox(width: 10),
                      _StatTile('$totalItems', 'Items\nGiven', HugeIcons.strokeRoundedPackage, kAccent),
                      const SizedBox(width: 10),
                      _StatTile('$ngoIds', 'NGOs\nSupported', HugeIcons.strokeRoundedBuilding02, kMatched),
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

                    // Quick links
                    Text('QUICK LINKS', style: GoogleFonts.sora(
                      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 10),
                    _SettingsGroup(shadow: _shadow, items: [
                      _SettingsTile(HugeIcons.strokeRoundedFavourite, 'Saved Needs', () => context.push('/donor/saved')),
                      _SettingsTile(HugeIcons.strokeRoundedNotification01, 'Notifications', () => context.push('/donor/notifications')),
                      _SettingsTile(HugeIcons.strokeRoundedMaps, 'NGO Map', () => context.push('/donor/map')),
                    ]),
                    const SizedBox(height: 12),

                    // Settings section
                    Text('SETTINGS', style: GoogleFonts.sora(
                      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 10),
                    _SettingsGroup(shadow: _shadow, items: [
                      _SettingsTile(HugeIcons.strokeRoundedNotification01, 'Notification Preferences', () {
                        showModalBottomSheet(
                          context: context, isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const _NotifPrefsSheet(),
                        );
                      }),
                      _SettingsTile(HugeIcons.strokeRoundedView, 'Profile Visibility', () {
                        showModalBottomSheet(
                          context: context, backgroundColor: Colors.transparent,
                          builder: (_) => const _VisibilitySheet(),
                        );
                      }),
                      _SettingsTile(HugeIcons.strokeRoundedLock, 'Privacy & Safety', () {
                        showModalBottomSheet(
                          context: context, backgroundColor: Colors.transparent,
                          builder: (_) => const _PrivacySheet(),
                        );
                      }),
                    ]),
                    const SizedBox(height: 12),
                    _SettingsGroup(shadow: _shadow, items: [
                      _SettingsTile(HugeIcons.strokeRoundedLogout01, 'Sign Out', () async {
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
          child: const Icon(HugeIcons.strokeRoundedCharity, size: 18, color: kPrimary),
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
    trailing: const Icon(HugeIcons.strokeRoundedArrowRight01, size: 18, color: kMutedFg),
    onTap: onTap,
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}

// ── Edit Profile sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final Profile profile;
  final VoidCallback onSaved;
  const _EditProfileSheet({required this.profile, required this.onSaved});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.fullName);
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
    _newAvatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _pickAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      final url = await StorageService.uploadAvatar(widget.profile.id);
      if (url != null) setState(() => _newAvatarUrl = url);
    } catch (e) {
      setState(() => _error = 'Avatar upload failed: $e');
    } finally {
      setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) { setState(() => _error = 'Name cannot be empty'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        'avatar_url': _newAvatarUrl,
      }).eq('id', widget.profile.id);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Edit Profile', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
        const SizedBox(height: 20),
        // Avatar picker
        Center(
          child: GestureDetector(
            onTap: _uploadingAvatar ? null : _pickAvatar,
            child: Stack(
              children: [
                _uploadingAvatar
                    ? Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0)),
                        child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))),
                      )
                    : UserAvatar(
                        seed: widget.profile.id,
                        initials: widget.profile.fullName.isNotEmpty ? widget.profile.fullName[0] : '?',
                        avatarUrl: _newAvatarUrl,
                        radius: 36,
                        showEditBadge: true,
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(child: Text('Tap to change photo', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kMutedFg))),
        const SizedBox(height: 18),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(HugeIcons.strokeRoundedUser)),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(HugeIcons.strokeRoundedCall)),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: kPrimary.withValues(alpha: 0.5),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Save Changes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ── Notification preferences sheet ───────────────────────────────────────────

class _NotifPrefsSheet extends StatefulWidget {
  const _NotifPrefsSheet();
  @override
  State<_NotifPrefsSheet> createState() => _NotifPrefsSheetState();
}

class _NotifPrefsSheetState extends State<_NotifPrefsSheet> {
  bool _newNeeds = true;
  bool _pledgeUpdates = true;
  bool _ngoAnnouncements = false;
  bool _loaded = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _newNeeds = prefs.getBool('notif_new_needs') ?? true;
      _pledgeUpdates = prefs.getBool('notif_pledge_updates') ?? true;
      _ngoAnnouncements = prefs.getBool('notif_ngo_announcements') ?? false;
      _loaded = true;
    });
  }

  Future<void> _set(String key, bool v) async => (await SharedPreferences.getInstance()).setBool(key, v);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Notification Preferences', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
        const SizedBox(height: 4),
        Text('Choose what you want to be notified about', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg)),
        const SizedBox(height: 20),
        if (!_loaded)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
          ))
        else
          Container(
            decoration: BoxDecoration(
              color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
            ),
            child: Column(children: [
              _NotifToggle(icon: HugeIcons.strokeRoundedPackage, title: 'New Donation Needs',
                subtitle: 'When NGOs post items you can give', value: _newNeeds,
                onChanged: (v) { setState(() => _newNeeds = v); _set('notif_new_needs', v); }),
              const Divider(height: 1, color: kBorder),
              _NotifToggle(icon: HugeIcons.strokeRoundedCharity, title: 'Pledge Updates',
                subtitle: 'When your pledges are confirmed or rejected', value: _pledgeUpdates,
                onChanged: (v) { setState(() => _pledgeUpdates = v); _set('notif_pledge_updates', v); }),
              const Divider(height: 1, color: kBorder),
              _NotifToggle(icon: HugeIcons.strokeRoundedMegaphone01, title: 'NGO Announcements',
                subtitle: 'Updates from organisations you support', value: _ngoAnnouncements,
                onChanged: (v) { setState(() => _ngoAnnouncements = v); _set('notif_ngo_announcements', v); }),
            ]),
          ),
      ]),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifToggle({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Icon(icon, size: 18, color: kMutedFg),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground)),
        Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kMutedFg)),
      ])),
      Switch(value: value, onChanged: onChanged, activeThumbColor: kPrimary, activeTrackColor: kPrimary.withValues(alpha: 0.4)),
    ]),
  );
}

// ── Profile visibility sheet ──────────────────────────────────────────────────

class _VisibilitySheet extends StatefulWidget {
  const _VisibilitySheet();
  @override
  State<_VisibilitySheet> createState() => _VisibilitySheetState();
}

class _VisibilitySheetState extends State<_VisibilitySheet> {
  bool _publicProfile = true;
  bool _showDonations = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _publicProfile = prefs.getBool('visibility_public') ?? true;
      _showDonations = prefs.getBool('visibility_donations') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Profile Visibility', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
        const SizedBox(height: 4),
        Text('Control what others can see about you', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
          ),
          child: Column(children: [
            SwitchListTile(
              title: Text('Public Profile', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground)),
              subtitle: const Text('NGOs can see your name and contact info', style: TextStyle(fontSize: 12, color: kMutedFg)),
              value: _publicProfile, activeThumbColor: kPrimary, activeTrackColor: kPrimary.withValues(alpha: 0.4), dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onChanged: (v) async {
                setState(() => _publicProfile = v);
                (await SharedPreferences.getInstance()).setBool('visibility_public', v);
              },
            ),
            const Divider(height: 1, color: kBorder),
            SwitchListTile(
              title: Text('Show My Donations', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground)),
              subtitle: const Text('Display your contribution history publicly', style: TextStyle(fontSize: 12, color: kMutedFg)),
              value: _showDonations, activeThumbColor: kPrimary, activeTrackColor: kPrimary.withValues(alpha: 0.4), dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onChanged: (v) async {
                setState(() => _showDonations = v);
                (await SharedPreferences.getInstance()).setBool('visibility_donations', v);
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Privacy & Safety sheet ────────────────────────────────────────────────────

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Privacy & Safety', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
        const SizedBox(height: 20),
        _PrivacyItem(icon: HugeIcons.strokeRoundedShield01, iconColor: kMatched,
          title: 'Encryption',
          body: 'All personal data is encrypted in transit and at rest using industry-standard TLS.'),
        const SizedBox(height: 10),
        _PrivacyItem(icon: HugeIcons.strokeRoundedLock, iconColor: kPrimary,
          title: 'Data We Collect',
          body: 'Name, email, phone, and donation history only. We never sell your data or share it outside NeedLink operations.'),
        const SizedBox(height: 10),
        _PrivacyItem(icon: HugeIcons.strokeRoundedDelete02, iconColor: const Color(0xFFDC2626),
          title: 'Delete My Data',
          body: 'To request full account deletion and data removal, contact support@needlink.app.'),
      ]),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, body;
  const _PrivacyItem({required this.icon, required this.iconColor, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kForeground)),
        const SizedBox(height: 3),
        Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kMutedFg, height: 1.5)),
      ])),
    ]),
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
