import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _searchCtrl = TextEditingController();

  static const _categories = [
    ('', Icons.grid_view_rounded, 'All'),
    ('food', Icons.restaurant_rounded, 'Food'),
    ('clothing', Icons.checkroom_rounded, 'Clothing'),
    ('medicine', Icons.medication_rounded, 'Medicine'),
    ('supplies', Icons.school_rounded, 'Supplies'),
  ];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final needsAsync = ref.watch(donationNeedsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: profileAsync.when(
              data: (p) {
                final name = p?.fullName.split(' ').first ?? 'there';
                return Text('Hello, $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700));
              },
              loading: () => const Text('NeedLink'),
              error: (_, __) => const Text('NeedLink'),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: profileAsync.when(
                  data: (p) => CircleAvatar(
                    radius: 16, backgroundColor: kPrimary,
                    child: Text(
                      p?.fullName.isNotEmpty == true ? p!.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  loading: () => const SizedBox(width: 32),
                  error: (_, __) => const SizedBox(width: 32),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Container(
                color: kSurface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(children: [
                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search by item or NGO…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter chips
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._categories.map((c) => _FilterChip(
                          icon: c.$2, label: c.$3,
                          selected: _category == c.$1,
                          onTap: () => setState(() =>
                            _category = (_category == c.$1 && c.$1.isNotEmpty) ? '' : c.$1),
                        )),
                        const SizedBox(width: 4),
                        _FilterChip(
                          icon: Icons.priority_high_rounded,
                          label: 'Urgent',
                          selected: _urgentOnly,
                          onTap: () => setState(() => _urgentOnly = !_urgentOnly),
                          urgent: true,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
        body: needsAsync.when(
          data: (needs) {
            final filtered = needs.where((n) {
              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                if (!n.itemName.toLowerCase().contains(q) &&
                    !(n.ngo?.name.toLowerCase().contains(q) ?? false)) return false;
              }
              if (_category.isNotEmpty && n.category != _category) return false;
              if (_urgentOnly && !n.isUrgent) return false;
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return _EmptyState(isFiltered: _search.isNotEmpty || _category.isNotEmpty || _urgentOnly);
            }

            return RefreshIndicator(
              color: kPrimary,
              onRefresh: () => ref.refresh(donationNeedsProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) => NeedCard(
                  need: filtered[i],
                  onTap: () => context.go('/donor/need/${filtered[i].id}'),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: kUrgent))),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool urgent;
  final VoidCallback onTap;
  const _FilterChip({required this.icon, required this.label, required this.selected, required this.onTap, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    final activeColor = urgent ? kUrgent : kPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? activeColor : kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: selected ? Colors.white : kMutedFg),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : kMutedFg,
          )),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(isFiltered ? Icons.search_off_rounded : Icons.inventory_2_outlined, size: 52, color: kMuted),
      const SizedBox(height: 14),
      Text(
        isFiltered ? 'No needs match your filter' : 'No donation needs yet',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kForeground),
      ),
      const SizedBox(height: 6),
      Text(
        isFiltered ? 'Try clearing the filter' : 'Check back soon',
        style: const TextStyle(fontSize: 13, color: kMutedFg),
      ),
    ]),
  );
}
