import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers.dart';
import '../../theme.dart';

class ImpactReportsScreen extends ConsumerWidget {
  const ImpactReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAsync = ref.watch(myNgoNeedsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact Reports'),
        actions: [IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {})],
      ),
      body: needsAsync.when(
        data: (needs) {
          final totalNeeds = needs.length;
          final totalPledged = needs.fold<int>(0, (s, n) => s + n.quantityPledged);
          final matched = needs.where((n) => n.status == 'matched').length;

          // Category breakdown
          final cats = <String, int>{};
          for (final n in needs) cats[n.category] = (cats[n.category] ?? 0) + 1;

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () async {
              ref.invalidate(myNgoNeedsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Key metrics
                const Text('Key Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kForeground)),
                const SizedBox(height: 12),
                Row(children: [
                  _MetricCard('$totalPledged+', 'Items Pledged', '+12% from last quarter', kPrimary),
                  const SizedBox(width: 10),
                  _MetricCard('$totalNeeds', 'Total Needs', 'Posted by your NGO', kAccent),
                  const SizedBox(width: 10),
                  _MetricCard('$matched', 'Fully Matched', 'Goal reached', kMatched),
                ]),
                const SizedBox(height: 24),

                // Category breakdown
                if (cats.isNotEmpty) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('By Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kForeground)),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ]),
                  const SizedBox(height: 12),
                  ...cats.entries.map((e) => _CategoryRow(category: e.key, count: e.value, total: totalNeeds)),
                  const SizedBox(height: 24),
                ],

                // Success stories placeholder
                const Text('Success Stories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kForeground)),
                const SizedBox(height: 12),
                ..._stories.map((s) => _StoryCard(story: s)),
                const SizedBox(height: 24),

                // Recent activity
                const Text('Recent Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kForeground)),
                const SizedBox(height: 12),
                ..._reports.map((r) => _ReportTile(report: r)),
                const SizedBox(height: 20),

                TextButton(onPressed: () {}, child: const Text('View All Archive →')),
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

  static const _stories = [
    ('Amina\'s Journey', 'Community support made it possible for 40 families to access staple food items.'),
    ('School Kits Drive', 'Back-to-school packs reached 200 students in rural districts.'),
    ('Medical Outreach Q3', 'Over 500 first aid kits distributed across 3 districts.'),
  ];

  static const _reports = [
    (Icons.description_rounded, 'Q3 Donation Summary', 'Oct 2024', '2.4 MB'),
    (Icons.school_rounded, 'Education Impact Report', 'Sep 2024', '1.8 MB'),
    (Icons.health_and_safety_rounded, 'Health Outreach Data', 'Aug 2024', '3.1 MB'),
  ];
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final String sub;
  final Color color;
  const _MetricCard(this.value, this.label, this.sub, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kForeground)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: kMutedFg), maxLines: 2),
      ]),
    ),
  );
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final int count;
  final int total;
  const _CategoryRow({required this.category, required this.count, required this.total});

  static const _icons = {
    'food': Icons.restaurant_rounded,
    'clothing': Icons.checkroom_rounded,
    'medicine': Icons.medication_rounded,
    'supplies': Icons.school_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Icon(_icons[category] ?? Icons.inventory_2_rounded, size: 18, color: kPrimary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(category[0].toUpperCase() + category.substring(1),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground)),
            Text('$count needs', style: const TextStyle(fontSize: 12, color: kMutedFg)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, backgroundColor: kMuted,
              valueColor: const AlwaysStoppedAnimation(kPrimary), minHeight: 5),
          ),
        ])),
      ]),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final (String, String) story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.format_quote_rounded, size: 20, color: kPrimary),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(story.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground)),
        const SizedBox(height: 4),
        Text(story.$2, style: const TextStyle(fontSize: 12, color: kMutedFg, height: 1.5)),
      ])),
    ]),
  );
}

class _ReportTile extends StatelessWidget {
  final (IconData, String, String, String) report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder),
    ),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(report.$1, size: 18, color: kPrimary),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(report.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground)),
        Text('${report.$3} · ${report.$4}', style: const TextStyle(fontSize: 11, color: kMutedFg)),
      ])),
      TextButton(onPressed: () {}, child: const Text('Download', style: TextStyle(fontSize: 12))),
    ]),
  );
}
