import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';

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
                return Text('Hello, $name', style: GoogleFonts.sora(
                  fontSize: 18, fontWeight: FontWeight.w800, color: kForeground,
                ));
              },
              loading: () => Text('NeedLink', style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w800, color: kForeground,
              )),
              error: (_, _) => Text('NeedLink', style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w800, color: kForeground,
              )),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: profileAsync.when(
                  data: (p) => CircleAvatar(
                    radius: 16,
                    backgroundColor: kPrimary,
                    child: Text(
                      p?.fullName.isNotEmpty == true ? p!.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  loading: () => const SizedBox(width: 32),
                  error: (_, _) => const SizedBox(width: 32),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Container(
                color: kSurface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(children: [
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
                    !(n.ngo?.name.toLowerCase().contains(q) ?? false)) { return false; }
              }
              if (_category.isNotEmpty && n.category != _category) { return false; }
              if (_urgentOnly && !n.isUrgent) { return false; }
              return true;
            }).toList();

            final isFiltered = _search.isNotEmpty || _category.isNotEmpty || _urgentOnly;

            if (filtered.isEmpty) {
              return _EmptyState(isFiltered: isFiltered);
            }

            return RefreshIndicator(
              color: kPrimary,
              onRefresh: () => ref.refresh(donationNeedsProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: filtered.length + (isFiltered ? 0 : 1),
                itemBuilder: (_, i) {
                  if (!isFiltered && i == 0) return const _WelcomeBanner();
                  final ni = isFiltered ? i : i - 1;
                  final need = filtered[ni];
                  if (ni == 0 && need.isUrgent) {
                    return _HeroCard(
                      need: need,
                      onTap: () => context.go('/donor/need/${need.id}'),
                    );
                  }
                  return _CompactCard(
                    need: need,
                    onTap: () => context.go('/donor/need/${need.id}'),
                  );
                },
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

// ── Hero card (first urgent need) ───────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final DonationNeed need;
  final VoidCallback onTap;
  const _HeroCard({required this.need, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (need.progress * 100).round();
    final remaining = need.quantityNeeded - need.quantityPledged;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment(-0.4, -1),
            end: Alignment(1, 0.6),
            colors: [Color(0xFF0C4A6E), Color(0xFF0891B2)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0891B2).withAlpha(55),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgent pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: kUrgent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('URGENT', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white,
                    )),
                  ),
                  const SizedBox(height: 12),
                  Text(need.itemName, style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  )),
                  if (need.ngo != null) ...[
                    const SizedBox(height: 4),
                    Text(need.ngo!.name, style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 9,
                    )),
                  ],
                  const SizedBox(height: 18),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$pct%', style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    )),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '$remaining remaining',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.7), fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Pledge', style: GoogleFonts.plusJakartaSans(
                          color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700,
                        )),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: need.progress,
                      backgroundColor: Colors.white.withAlpha(38),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Compact list card ────────────────────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  final DonationNeed need;
  final VoidCallback onTap;
  const _CompactCard({required this.need, required this.onTap});

  static const _categoryColors = {
    'food':     Color(0xFFEA580C),
    'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFF16A34A),
    'supplies': Color(0xFF0891B2),
  };

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColors[need.category] ?? kPrimary;
    final pct = (need.progress * 100).round();
    final remaining = need.quantityNeeded - need.quantityPledged;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(need.itemName, style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, fontWeight: FontWeight.w800, color: kForeground, height: 1.3,
                          ), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        if (need.isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kUrgent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('URGENT', style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white,
                            )),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        '${need.ngo?.name ?? ''} · ${need.category}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 8, color: kMutedFg),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: need.progress,
                          backgroundColor: kMuted,
                          valueColor: AlwaysStoppedAnimation(catColor),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(children: [
                        Text(
                          '$pct% · $remaining remaining',
                          style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMutedFg),
                        ),
                        const Spacer(),
                        Text(
                          'By ${need.deadline}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMutedFg),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool urgent;
  final VoidCallback onTap;
  const _FilterChip({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
    this.urgent = false,
  });

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

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Together we can make a difference',
                    style: GoogleFonts.sora(
                      fontSize: 13, fontWeight: FontWeight.w700, color: kForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse needs below and pledge what you can',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kMutedFg),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
            child: Lottie.asset(
              'assets/lottie/community_wave.json',
              width: 90, height: 80,
              repeat: true,
              fit: BoxFit.cover,
            ),
          ),
        ],
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
      Lottie.asset(
        'assets/lottie/empty_state.json',
        width: 160, height: 160,
        repeat: true,
      ),
      const SizedBox(height: 4),
      Text(
        isFiltered ? 'No needs match your filter' : 'No donation needs yet',
        style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: kForeground),
      ),
      const SizedBox(height: 6),
      Text(
        isFiltered ? 'Try clearing the filter' : 'Check back soon',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
      ),
    ]),
  );
}

class _DotPatternPainter extends CustomPainter {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
