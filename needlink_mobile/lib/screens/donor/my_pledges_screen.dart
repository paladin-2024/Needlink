import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/skeleton.dart';

class MyPledgesScreen extends ConsumerStatefulWidget {
  const MyPledgesScreen({super.key});
  @override
  ConsumerState<MyPledgesScreen> createState() => _MyPledgesScreenState();
}

class _MyPledgesScreenState extends ConsumerState<MyPledgesScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'Active', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final pledgesAsync = ref.watch(myPledgesProvider);

    return Scaffold(
      body: pledgesAsync.when(
        data: (pledges) {
          final filtered = pledges.where((p) {
            if (_filter == 'Active') return p.status == 'pending';
            if (_filter == 'Delivered') return p.status == 'confirmed';
            return true;
          }).toList();

          final activeCount = pledges.where((p) => p.status == 'pending').length;

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () => ref.refresh(myPledgesProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: kSurface,
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Pledges', style: GoogleFonts.sora(
                          fontSize: 22, fontWeight: FontWeight.w800, color: kForeground,
                        )),
                        const SizedBox(height: 2),
                        Text(
                          activeCount > 0
                              ? '$activeCount active donation${activeCount == 1 ? '' : 's'}'
                              : 'No active donations',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _filters.map((f) {
                            final isActive = _filter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _filter = f),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isActive ? kPrimary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isActive ? kPrimary : kBorder),
                                  ),
                                  child: Text(f, style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.white : kMutedFg,
                                  )),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(child: _EmptyState(filter: _filter))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _PledgeCard(pledge: filtered[i]),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 76, 16, 16),
          itemCount: 4,
          itemBuilder: (_, _) => const PledgeCardSkeleton(),
        ),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: kUrgent))),
      ),
    );
  }
}

// ── Expandable pledge card ───────────────────────────────────────────────────

class _PledgeCard extends StatefulWidget {
  final Pledge pledge;
  const _PledgeCard({required this.pledge});

  @override
  State<_PledgeCard> createState() => _PledgeCardState();
}

class _PledgeCardState extends State<_PledgeCard> {
  bool _expanded = false;

  static const _statusConfig = {
    'pending':   _StatusCfg(Color(0xFFFFFBEB), Color(0xFFD97706), 'Pending'),
    'confirmed': _StatusCfg(Color(0xFFF0FDF4), Color(0xFF15803D), 'Delivered'),
    'rejected':  _StatusCfg(Color(0xFFFEF2F2), Color(0xFFDC2626), 'Rejected'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig[widget.pledge.status] ?? _statusConfig['pending']!;
    final need = widget.pledge.donationNeed;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(
            color: const Color(0xFF0891B2).withAlpha(14),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Column(
          children: [
            // Collapsed header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      need?.itemName ?? 'Donation',
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w900, fontSize: 11, color: kForeground,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${need?.ngo?.name ?? ''} · ${widget.pledge.quantity} units',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kMutedFg),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: cfg.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(cfg.label, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: cfg.fg,
                  )),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: const Icon(HugeIcons.strokeRoundedArrowRight01, size: 20, color: Color(0xFF94A3B8)),
                ),
              ]),
            ),

            // Expanded timeline
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? _TimelineSection(status: widget.pledge.status)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCfg {
  final Color bg, fg;
  final String label;
  const _StatusCfg(this.bg, this.fg, this.label);
}

// ── Timeline ────────────────────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  final String status;
  const _TimelineSection({required this.status});

  static const _steps = [
    'Pledge Submitted',
    'Confirmed by NGO',
    'In Transit',
    'Delivered',
  ];

  int get _stepsDone {
    if (status == 'confirmed') return 2;
    if (status == 'rejected') return 0;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final done = _stepsDone;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDFF),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          const SizedBox(height: 14),
          Text('DELIVERY TIMELINE', style: GoogleFonts.jetBrainsMono(
            fontSize: 7, fontWeight: FontWeight.w700,
            color: kMutedFg, letterSpacing: 1.5,
          )),
          const SizedBox(height: 12),
          if (status == 'rejected')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kUrgent,
                  ),
                ),
                const SizedBox(width: 10),
                Text('Pledge Rejected', style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: kUrgent,
                )),
              ]),
            )
          else
            ...List.generate(_steps.length, (i) {
              final isDone = i < done;
              final isLast = i == _steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? kPrimary : Colors.transparent,
                        border: Border.all(
                          color: isDone ? kPrimary : kBorder, width: 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(width: 2, height: 28, color: isDone ? kPrimary : kBorder),
                  ]),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: Text(
                      _steps[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                        color: isDone ? kForeground : kMutedFg,
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

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
        filter == 'All' ? 'No donations yet' : 'No $filter donations',
        style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: kForeground),
      ),
      const SizedBox(height: 6),
      Text(
        filter == 'All' ? 'Browse needs and make your first pledge' : 'Check back later',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
      ),
    ]),
  );
}
