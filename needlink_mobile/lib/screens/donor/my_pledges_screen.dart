import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';

class MyPledgesScreen extends ConsumerStatefulWidget {
  const MyPledgesScreen({super.key});
  @override
  ConsumerState<MyPledgesScreen> createState() => _MyPledgesScreenState();
}

class _MyPledgesScreenState extends ConsumerState<MyPledgesScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'Pending', 'Confirmed', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final pledgesAsync = ref.watch(myPledgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Donations'),
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {})],
      ),
      body: pledgesAsync.when(
        data: (pledges) {
          final filtered = _filter == 'All'
              ? pledges
              : pledges.where((p) => p.status.toLowerCase() == _filter.toLowerCase()).toList();

          final totalItems = pledges.fold<int>(0, (s, p) => s + p.quantity);
          final confirmed = pledges.where((p) => p.status == 'confirmed').length;

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () => ref.refresh(myPledgesProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards
                Row(children: [
                  _SummaryCard('${pledges.length}', 'Total Pledges', kPrimary),
                  const SizedBox(width: 10),
                  _SummaryCard('$totalItems', 'Items Donated', kAccent),
                  const SizedBox(width: 10),
                  _SummaryCard('$confirmed', 'Delivered', kMatched),
                ]),
                const SizedBox(height: 20),

                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((f) {
                      final active = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: active,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: kPrimary.withAlpha(30),
                          checkmarkColor: kPrimary,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: active ? kPrimary : kMutedFg,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          ),
                          side: BorderSide(color: active ? kPrimary : kBorder),
                          backgroundColor: kSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  _EmptyState(filter: _filter)
                else
                  ...filtered.map((p) => _PledgeCard(
                    pledge: p,
                    onTap: () => context.go('/donor/tracking/${p.id}'),
                  )),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SummaryCard(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: kMutedFg, height: 1.3), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _PledgeCard extends StatelessWidget {
  final Pledge pledge;
  final VoidCallback onTap;
  const _PledgeCard({required this.pledge, required this.onTap});

  static const _statusConfig = {
    'pending': (Color(0xFFFFFBEB), Color(0xFFD97706), 'Pending', Icons.schedule_rounded),
    'confirmed': (Color(0xFFF0FDF4), Color(0xFF15803D), 'Delivered', Icons.check_circle_rounded),
    'rejected': (Color(0xFFFEF2F2), Color(0xFFDC2626), 'Rejected', Icons.cancel_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig[pledge.status] ??
        (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), 'In Transit', Icons.local_shipping_rounded);
    final need = pledge.donationNeed;
    DateTime? created;
    try { created = DateTime.parse(pledge.createdAt); } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cfg.$1, borderRadius: BorderRadius.circular(10)),
              child: Icon(cfg.$4, color: cfg.$2, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(need?.itemName ?? 'Donation',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kForeground),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(need?.ngo?.name ?? '', style: const TextStyle(fontSize: 12, color: kMutedFg)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: cfg.$1, borderRadius: BorderRadius.circular(20)),
              child: Text(cfg.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg.$2)),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.inventory_2_outlined, size: 14, color: kMutedFg),
            const SizedBox(width: 6),
            Text('${pledge.quantity} units', style: const TextStyle(fontSize: 12, color: kForeground, fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            const Icon(Icons.calendar_today_outlined, size: 14, color: kMutedFg),
            const SizedBox(width: 6),
            Text('By ${pledge.deliveryDate}', style: const TextStyle(fontSize: 12, color: kMutedFg)),
            const Spacer(),
            if (created != null)
              Text(DateFormat('MMM d, yyyy').format(created),
                style: const TextStyle(fontSize: 11, color: kMutedFg)),
          ]),
          if (pledge.notes != null && pledge.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.notes_rounded, size: 13, color: kMutedFg),
                const SizedBox(width: 6),
                Expanded(child: Text(pledge.notes!, style: const TextStyle(fontSize: 12, color: kMutedFg))),
              ]),
            ),
          ],
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.local_shipping_outlined, size: 14),
              label: const Text('Track'),
              style: TextButton.styleFrom(
                foregroundColor: kPrimary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.volunteer_activism_outlined, size: 52, color: kMuted),
      const SizedBox(height: 14),
      Text(
        filter == 'All' ? 'No donations yet' : 'No $filter donations',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kForeground),
      ),
      const SizedBox(height: 6),
      const Text('Browse needs and make your first pledge', style: TextStyle(fontSize: 13, color: kMutedFg)),
    ]),
  );
}
