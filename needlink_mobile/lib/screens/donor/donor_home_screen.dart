import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/need_card.dart';

class DonorHomeScreen extends ConsumerStatefulWidget {
  const DonorHomeScreen({super.key});
  @override
  ConsumerState<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends ConsumerState<DonorHomeScreen> {
  String _search = '';
  String _category = '';
  bool _urgentOnly = false;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final needsAsync = ref.watch(donationNeedsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeedLink'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(children: [
              profileAsync.when(
                data: (p) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Hello, ${p?.fullName.split(' ').first ?? 'Donor'} 👋',
                    style: const TextStyle(fontSize: 15, color: kMutedFg)),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              // Search
              TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by item or NGO…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = ''))
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(label: 'All', selected: _category.isEmpty, onTap: () => setState(() => _category = '')),
                  ...['food', 'clothing', 'medicine', 'supplies'].map((c) =>
                    _FilterChip(label: '${_emoji(c)} $c', selected: _category == c, onTap: () => setState(() => _category = _category == c ? '' : c))),
                  const SizedBox(width: 4),
                  _FilterChip(label: '⚡ Urgent', selected: _urgentOnly, onTap: () => setState(() => _urgentOnly = !_urgentOnly), accent: true),
                ]),
              ),
            ]),
          ),

          // Bottom nav tabs
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
            child: Row(children: [
              _Tab(label: 'Browse', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
              _Tab(label: 'My Pledges', selected: _selectedTab == 1, onTap: () => context.go('/donor/pledges')),
            ]),
          ),

          Expanded(
            child: needsAsync.when(
              data: (needs) {
                var filtered = needs.where((n) {
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    if (!n.itemName.toLowerCase().contains(q) && !(n.ngo?.name.toLowerCase().contains(q) ?? false)) return false;
                  }
                  if (_category.isNotEmpty && n.category != _category) return false;
                  if (_urgentOnly && !n.isUrgent) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) return _empty();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => NeedCard(
                    need: filtered[i],
                    onTap: () => context.go('/donor/need/${filtered[i].id}'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: kUrgent))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inventory_2_outlined, size: 48, color: kMuted),
      SizedBox(height: 12),
      Text('No needs found', style: TextStyle(fontFamily: 'FiraCode', color: kMutedFg)),
    ]),
  );

  String _emoji(String c) => const {'food': '🌾', 'clothing': '👕', 'medicine': '💊', 'supplies': '📦'}[c] ?? '📦';
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? (accent ? kUrgent : kPrimary) : kSurface;
    final fg = selected ? Colors.white : kMutedFg;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? bg : kBorder),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: selected ? kPrimary : Colors.transparent, width: 2)),
      ),
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
        color: selected ? kPrimary : kMutedFg, fontFamily: 'FiraCode')),
    ),
  );
}
