import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers.dart';
import '../../theme.dart';

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

  late final _nameCtrl = TextEditingController();
  late final _regCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); _regCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ngoAsync = ref.watch(myNgoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Logout'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
          ),
        ],
      ),
      body: ngoAsync.when(
        data: (ngo) {
          if (ngo != null) {
            if (_nameCtrl.text.isEmpty) _nameCtrl.text = ngo.name;
            if (_regCtrl.text.isEmpty) _regCtrl.text = ngo.registrationNumber ?? '';
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Manage your organization\'s preferences and security.',
                style: const TextStyle(fontSize: 13, color: kMutedFg),
              ),
              const SizedBox(height: 20),

              // Organization profile
              _SectionHeader(Icons.corporate_fare_rounded, 'Organization Profile'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: kPrimary.withAlpha(25), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.corporate_fare_rounded, size: 28, color: kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ngo?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: kForeground)),
                      if (ngo?.verified == true)
                        Row(children: const [
                          Icon(Icons.verified_rounded, size: 13, color: kMatched),
                          SizedBox(width: 4),
                          Text('Verified', style: TextStyle(fontSize: 12, color: kMatched, fontWeight: FontWeight.w600)),
                        ]),
                    ])),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary, side: const BorderSide(color: kPrimary),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Update Logo', style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Organization Name')),
                  const SizedBox(height: 12),
                  TextField(controller: _regCtrl, decoration: const InputDecoration(labelText: 'Registration Number')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : () async {
                      if (ngo == null) return;
                      setState(() => _saving = true);
                      await Supabase.instance.client.from('ngos').update({
                        'name': _nameCtrl.text.trim(),
                        'registration_number': _regCtrl.text.trim().isNotEmpty ? _regCtrl.text.trim() : null,
                      }).eq('id', ngo.id);
                      ref.invalidate(myNgoProvider);
                      setState(() => _saving = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Changes saved'), backgroundColor: kMatched),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary, minimumSize: const Size(double.infinity, 46),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes'),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // Notification preferences
              _SectionHeader(Icons.notifications_active_outlined, 'Notification Preferences'),
              const SizedBox(height: 12),
              _ToggleCard(items: [
                _ToggleItem('New Donation Pledges', 'Alerts when a donor commits', _notifyPledges, (v) => setState(() => _notifyPledges = v)),
                _ToggleItem('Delivery Updates', 'Status changes for in-transit items', _notifyDelivery, (v) => setState(() => _notifyDelivery = v)),
                _ToggleItem('System Alerts', 'Critical security messages', _notifySystem, (v) => setState(() => _notifySystem = v)),
              ]),
              const SizedBox(height: 24),

              // Security
              _SectionHeader(Icons.security_rounded, 'Transparency & Security'),
              const SizedBox(height: 12),
              _ListCard(items: [
                _ListItem(Icons.lock_reset_rounded, 'Update Password', null, () {}),
                _ListItem(Icons.shield_rounded, 'Two-Factor Authentication', 'Enabled', () {}),
                _ListItem(Icons.visibility_outlined, 'Privacy Settings', null, () {}),
              ]),
              const SizedBox(height: 24),

              // Support
              _SectionHeader(Icons.info_outline_rounded, 'Support & Legal'),
              const SizedBox(height: 12),
              _ListCard(items: [
                _ListItem(Icons.help_center_outlined, 'Help Center', null, () {}),
                _ListItem(Icons.gavel_rounded, 'Terms of Service', null, () {}),
                _ListItem(Icons.policy_outlined, 'Privacy Policy', null, () {}),
              ]),
              const SizedBox(height: 24),

              // Danger zone
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                  const SizedBox(height: 4),
                  const Text('These actions are irreversible.', style: TextStyle(fontSize: 12, color: kMutedFg)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
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
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader(this.icon, this.title);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: kPrimary),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kForeground)),
  ]);
}

class _ToggleItem {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleItem(this.title, this.subtitle, this.value, this.onChanged);
}

class _ToggleCard extends StatelessWidget {
  final List<_ToggleItem> items;
  const _ToggleCard({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
    ),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      SwitchListTile(
        title: Text(e.value.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kForeground)),
        subtitle: Text(e.value.subtitle, style: const TextStyle(fontSize: 12, color: kMutedFg)),
        value: e.value.value,
        onChanged: e.value.onChanged,
        activeColor: kPrimary,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      if (e.key < items.length - 1) const Divider(height: 1),
    ])).toList()),
  );
}

class _ListItem {
  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;
  const _ListItem(this.icon, this.title, this.badge, this.onTap);
}

class _ListCard extends StatelessWidget {
  final List<_ListItem> items;
  const _ListCard({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
    ),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      ListTile(
        leading: Icon(e.value.icon, size: 20, color: kMutedFg),
        title: Text(e.value.title, style: const TextStyle(fontSize: 14, color: kForeground)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (e.value.badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: kMatched.withAlpha(25), borderRadius: BorderRadius.circular(20)),
              child: Text(e.value.badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMatched)),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded, size: 18, color: kMutedFg),
        ]),
        onTap: e.value.onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      if (e.key < items.length - 1) const Divider(height: 1),
    ])).toList()),
  );
}
