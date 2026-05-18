import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';

class NgoAnalyticsScreen extends ConsumerStatefulWidget {
  const NgoAnalyticsScreen({super.key});
  @override
  ConsumerState<NgoAnalyticsScreen> createState() => _NgoAnalyticsScreenState();
}

class _NgoAnalyticsScreenState extends ConsumerState<NgoAnalyticsScreen> {
  List<Map<String, dynamic>> _pledges = [];
  bool _loadingPledges = true;

  static const _shadow = [
    BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  @override
  void initState() { super.initState(); _loadPledges(); }

  Future<void> _loadPledges() async {
    final ngo = await ref.read(myNgoProvider.future);
    if (ngo == null) { if (mounted) setState(() => _loadingPledges = false); return; }
    try {
      final data = await Supabase.instance.client
          .from('pledges')
          .select('id, quantity, status, created_at, donation_need:donation_needs!inner(ngo_id, item_name), donor:profiles!donor_id(id, full_name, avatar_url)')
          .eq('donation_need.ngo_id', ngo.id)
          .order('created_at', ascending: false);
      if (mounted) setState(() { _pledges = List<Map<String, dynamic>>.from(data); _loadingPledges = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPledges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Monthly pledge trend — last 6 months
          final monthlyData = _buildMonthlyData(_pledges);

          // Top donors
          final donorMap = <String, _DonorStat>{};
          for (final p in _pledges) {
            final donor = p['donor'] as Map<String, dynamic>?;
            if (donor == null) continue;
            final id = donor['id'] as String? ?? '';
            final name = donor['full_name'] as String? ?? 'Donor';
            final avatar = donor['avatar_url'] as String?;
            final qty = (p['quantity'] as int?) ?? 0;
            donorMap[id] = _DonorStat(
              id: id, name: name, avatarUrl: avatar,
              pledges: (donorMap[id]?.pledges ?? 0) + 1,
              items: (donorMap[id]?.items ?? 0) + qty,
            );
          }
          final topDonors = donorMap.values.toList()
            ..sort((a, b) => b.items.compareTo(a.items));

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () async {
              ref.invalidate(myNgoNeedsProvider);
              await _loadPledges();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: kSurface,
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Text('Analytics', style: GoogleFonts.sora(
                      fontSize: 22, fontWeight: FontWeight.w800, color: kForeground,
                    )),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(delegate: SliverChildListDelegate([

                    // ── Key metrics ──────────────────────────────────────────
                    _Label('KEY METRICS'),
                    const SizedBox(height: 10),
                    Row(children: [
                      _MetricTile('$totalPledged', 'Items Pledged', kPrimary, _shadow),
                      const SizedBox(width: 8),
                      _MetricTile('$totalNeeds', 'Total Needs', kAccent, _shadow),
                      const SizedBox(width: 8),
                      _MetricTile('$matchedPct%', 'Match Rate', kMatched, _shadow),
                    ]),
                    const SizedBox(height: 24),

                    // ── Pledge trend bar chart ───────────────────────────────
                    if (!_loadingPledges && monthlyData.isNotEmpty) ...[
                      _Label('PLEDGE TREND (LAST 6 MONTHS)'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                        decoration: BoxDecoration(
                          color: kSurface, borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder), boxShadow: _shadow,
                        ),
                        child: SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (monthlyData.map((d) => d.count).reduce((a, b) => a > b ? a : b) * 1.3).ceilToDouble(),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: kBorder, strokeWidth: 1, dashArray: [4, 4],
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 28,
                                  getTitlesWidget: (v, _) => Text(
                                    v == 0 ? '' : v.toInt().toString(),
                                    style: const TextStyle(fontSize: 10, color: kMutedFg),
                                  ),
                                )),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 22,
                                  getTitlesWidget: (v, _) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= monthlyData.length) return const SizedBox.shrink();
                                    return Text(monthlyData[i].month, style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9, color: kMutedFg,
                                    ));
                                  },
                                )),
                              ),
                              barGroups: monthlyData.asMap().entries.map((e) => BarChartGroupData(
                                x: e.key,
                                barRods: [BarChartRodData(
                                  toY: e.value.count.toDouble(),
                                  color: kPrimary,
                                  width: 22,
                                  borderRadius: BorderRadius.circular(5),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: (monthlyData.map((d) => d.count).reduce((a, b) => a > b ? a : b) * 1.3).ceilToDouble(),
                                    color: kPrimary.withAlpha(12),
                                  ),
                                )],
                              )).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Category breakdown ───────────────────────────────────
                    if (cats.isNotEmpty) ...[
                      _Label('BY CATEGORY'),
                      const SizedBox(height: 10),
                      ...cats.entries.map((e) => _CategoryRow(
                        category: e.key, count: e.value, total: totalNeeds, shadow: _shadow,
                      )),
                      const SizedBox(height: 24),
                    ],

                    // ── Top donors ───────────────────────────────────────────
                    if (topDonors.isNotEmpty) ...[
                      _Label('TOP DONORS'),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: kSurface, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kBorder), boxShadow: _shadow,
                        ),
                        child: Column(children: topDonors.take(5).toList().asMap().entries.map((e) {
                          final donor = e.value;
                          return Column(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(children: [
                                Text('${e.key + 1}', style: GoogleFonts.sora(
                                  fontSize: 13, fontWeight: FontWeight.w900,
                                  color: e.key == 0 ? const Color(0xFFD97706) : kMutedFg,
                                )),
                                const SizedBox(width: 10),
                                UserAvatar(
                                  seed: donor.id, initials: donor.name[0].toUpperCase(),
                                  avatarUrl: donor.avatarUrl, radius: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(donor.name, style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: kForeground,
                                  )),
                                  Text('${donor.pledges} pledge${donor.pledges == 1 ? '' : 's'} · ${donor.items} items',
                                    style: const TextStyle(fontSize: 11, color: kMutedFg)),
                                ])),
                                if (e.key == 0)
                                  const Icon(HugeIcons.strokeRoundedAward01, size: 18, color: Color(0xFFD97706)),
                              ]),
                            ),
                            if (e.key < topDonors.take(5).length - 1)
                              const Divider(height: 1, color: kBorder),
                          ]);
                        }).toList()),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Fulfillment stats ────────────────────────────────────
                    _Label('FULFILLMENT'),
                    const SizedBox(height: 10),
                    _FulfillmentCard(needs: needs, shadow: _shadow),
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

  List<_MonthData> _buildMonthlyData(List<Map<String, dynamic>> pledges) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i);
      return _MonthData(month: DateFormat('MMM').format(m), year: m.year, monthNum: m.month, count: 0);
    });
    for (final p in pledges) {
      final createdAt = DateTime.tryParse(p['created_at'] as String? ?? '');
      if (createdAt == null) continue;
      for (final m in months) {
        if (createdAt.year == m.year && createdAt.month == m.monthNum) {
          m.count++;
          break;
        }
      }
    }
    return months;
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class _MonthData {
  final String month;
  final int year, monthNum;
  int count;
  _MonthData({required this.month, required this.year, required this.monthNum, required this.count});
}

class _DonorStat {
  final String id, name;
  final String? avatarUrl;
  final int pledges, items;
  const _DonorStat({required this.id, required this.name, this.avatarUrl, required this.pledges, required this.items});
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.sora(
    fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
  ));
}

class _MetricTile extends StatelessWidget {
  final String value, label;
  final Color color;
  final List<BoxShadow> shadow;
  const _MetricTile(this.value, this.label, this.color, this.shadow);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFF), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder), boxShadow: shadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kMutedFg)),
      ]),
    ),
  );
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final int count, total;
  final List<BoxShadow> shadow;
  const _CategoryRow({required this.category, required this.count, required this.total, required this.shadow});

  static const _catColors = {
    'food': Color(0xFFEA580C), 'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFF16A34A), 'supplies': Color(0xFF0891B2),
  };
  static const _catIcons = {
    'food': HugeIcons.strokeRoundedRestaurant01, 'clothing': HugeIcons.strokeRoundedTShirt,
    'medicine': HugeIcons.strokeRoundedMedicine01, 'supplies': HugeIcons.strokeRoundedSchool,
  };

  @override
  Widget build(BuildContext context) {
    final color = _catColors[category] ?? kPrimary;
    final icon = _catIcons[category] ?? HugeIcons.strokeRoundedPackage;
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

class _FulfillmentCard extends StatelessWidget {
  final List<DonationNeed> needs;
  final List<BoxShadow> shadow;
  const _FulfillmentCard({required this.needs, required this.shadow});

  @override
  Widget build(BuildContext context) {
    final open = needs.where((n) => n.status == 'open').length;
    final matched = needs.where((n) => n.status == 'matched').length;
    final closed = needs.where((n) => n.status == 'closed').length;
    final total = needs.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder), boxShadow: shadow,
      ),
      child: Column(children: [
        _FulfillRow('Open', open, total, kPrimary),
        const SizedBox(height: 8),
        _FulfillRow('Fully Matched', matched, total, kMatched),
        const SizedBox(height: 8),
        _FulfillRow('Closed', closed, total, kMutedFg),
      ]),
    );
  }
}

class _FulfillRow extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _FulfillRow(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(children: [
      SizedBox(width: 90, child: Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 12, color: kMutedFg,
      ))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct, backgroundColor: kMuted,
          valueColor: AlwaysStoppedAnimation(color), minHeight: 6,
        ),
      )),
      const SizedBox(width: 10),
      Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}
