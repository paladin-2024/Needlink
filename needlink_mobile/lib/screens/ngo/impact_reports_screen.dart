import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers.dart';
import '../../theme.dart';

class ImpactReportsScreen extends ConsumerWidget {
  const ImpactReportsScreen({super.key});

  static const _catColors = {
    'food': Color(0xFFEA580C), 'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFF16A34A), 'supplies': Color(0xFF0891B2),
  };
  static const _catIcons = {
    'food': HugeIcons.strokeRoundedRestaurant01, 'clothing': HugeIcons.strokeRoundedTShirt,
    'medicine': HugeIcons.strokeRoundedMedicine01, 'supplies': HugeIcons.strokeRoundedSchool,
  };

  static const _shadow = [
    BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const _stories = [
    ('Amina\'s Journey', 'Community support made it possible for 40 families to access staple food items.'),
    ('School Kits Drive', 'Back-to-school packs reached 200 students in rural districts.'),
    ('Medical Outreach Q3', 'Over 500 first aid kits distributed across 3 districts.'),
  ];

  static const _reports = [
    (HugeIcons.strokeRoundedFile01, 'Q3 Donation Summary', 'Oct 2024', '2.4 MB'),
    (HugeIcons.strokeRoundedSchool, 'Education Impact Report', 'Sep 2024', '1.8 MB'),
    (HugeIcons.strokeRoundedFirstAidKit, 'Health Outreach Data', 'Aug 2024', '3.1 MB'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAsync = ref.watch(myNgoNeedsProvider);

    return Scaffold(
      body: needsAsync.when(
        data: (needs) {
          final totalNeeds = needs.length;
          final totalPledged = needs.fold<int>(0, (s, n) => s + n.quantityPledged);
          final matched = needs.where((n) => n.status == 'matched').length;
          final matchedPct = totalNeeds > 0 ? ((matched / totalNeeds) * 100).round() : 0;
          final cats = <String, int>{};
          for (final n in needs) { cats[n.category] = (cats[n.category] ?? 0) + 1; }

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () async { ref.invalidate(myNgoNeedsProvider); },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: kSurface,
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Text('Impact Reports', style: GoogleFonts.sora(
                      fontSize: 22, fontWeight: FontWeight.w800, color: kForeground,
                    )),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(delegate: SliverChildListDelegate([

                    // Key Metrics
                    Text('KEY METRICS', style: GoogleFonts.sora(
                      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 10),
                    Row(children: [
                      _MetricTile('$totalPledged', 'Items Pledged', 'Across all needs', kPrimary),
                      const SizedBox(width: 8),
                      _MetricTile('$totalNeeds', 'Total Needs', 'Posted by your NGO', kAccent),
                      const SizedBox(width: 8),
                      _MetricTile('$matchedPct%', 'Match Rate', '$matched fully matched', kMatched),
                    ]),
                    const SizedBox(height: 24),

                    // Category breakdown
                    if (cats.isNotEmpty) ...[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('BY CATEGORY', style: GoogleFonts.sora(
                          fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
                        )),
                      ]),
                      const SizedBox(height: 10),
                      ...cats.entries.map((e) => _CategoryRow(
                        category: e.key, count: e.value, total: totalNeeds,
                        color: _catColors[e.key] ?? kPrimary,
                        icon: _catIcons[e.key] ?? HugeIcons.strokeRoundedPackage,
                        shadow: _shadow,
                      )),
                      const SizedBox(height: 24),
                    ],

                    // Success stories
                    Text('SUCCESS STORIES', style: GoogleFonts.sora(
                      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 10),
                    ..._stories.map((s) => _StoryCard(story: s, shadow: _shadow)),
                    const SizedBox(height: 24),

                    // Recent reports
                    Text('RECENT REPORTS', style: GoogleFonts.sora(
                      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 10),
                    ..._reports.map((r) => _ReportTile(report: r, shadow: _shadow)),
                    const SizedBox(height: 12),

                    Center(child: TextButton(
                      onPressed: () {},
                      child: Text('View All Archive →', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600,
                      )),
                    )),
                    const SizedBox(height: 20),
                  ])),
                ),
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

// ── Metric tile ───────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final String value, label, sub;
  final Color color;
  const _MetricTile(this.value, this.label, this.sub, this.color);

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: kForeground)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: kMutedFg), maxLines: 2),
      ]),
    ),
  );
}

// ── Category row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String category;
  final int count, total;
  final Color color;
  final IconData icon;
  final List<BoxShadow> shadow;
  const _CategoryRow({
    required this.category, required this.count, required this.total,
    required this.color, required this.icon, required this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder), boxShadow: shadow,
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              category[0].toUpperCase() + category.substring(1),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground),
            ),
            Text('$count needs', style: const TextStyle(fontSize: 12, color: kMutedFg)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, backgroundColor: kMuted,
              valueColor: AlwaysStoppedAnimation(color), minHeight: 5,
            ),
          ),
        ])),
      ]),
    );
  }
}

// ── Story card ────────────────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  final (String, String) story;
  final List<BoxShadow> shadow;
  const _StoryCard({required this.story, required this.shadow});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kBackground, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder), boxShadow: shadow,
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: kPrimary.withAlpha(20), shape: BoxShape.circle),
        child: const Icon(HugeIcons.strokeRoundedQuoteDown, size: 16, color: kPrimary),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(story.$1, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground)),
        const SizedBox(height: 4),
        Text(story.$2, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kMutedFg, height: 1.55)),
      ])),
    ]),
  );
}

// ── Report tile ───────────────────────────────────────────────────────────────

class _ReportTile extends StatelessWidget {
  final (IconData, String, String, String) report;
  final List<BoxShadow> shadow;
  const _ReportTile({required this.report, required this.shadow});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder), boxShadow: shadow,
    ),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(report.$1, size: 18, color: kPrimary),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(report.$2, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: kForeground,
        )),
        Text('${report.$3} · ${report.$4}', style: const TextStyle(fontSize: 11, color: kMutedFg)),
      ])),
      TextButton(
        onPressed: () {},
        child: Text('Download', style: GoogleFonts.plusJakartaSans(
          fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600,
        )),
      ),
    ]),
  );
}
