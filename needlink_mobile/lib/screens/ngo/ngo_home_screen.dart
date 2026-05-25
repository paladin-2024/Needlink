import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/skeleton.dart';

class NgoHomeScreen extends ConsumerWidget {
  const NgoHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ngoAsync = ref.watch(myNgoProvider);
    final profileAsync = ref.watch(profileProvider);
    final needsAsync = ref.watch(myNgoNeedsProvider);
    final pledgesAsync = ref.watch(myNgoPendingPledgesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
          onRefresh: () async {
            ref.invalidate(myNgoProvider);
            ref.invalidate(myNgoNeedsProvider);
            ref.invalidate(myNgoPendingPledgesProvider);
            ref.invalidate(profileProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: kSurface,
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ngoAsync.when(
                                  data: (ngo) => Text(
                                    ngo?.name ?? 'Organisation',
                                    style: GoogleFonts.sora(
                                      fontSize: 13, fontWeight: FontWeight.w900, color: kForeground,
                                    ),
                                  ),
                                  loading: () => Container(height: 16, width: 140, color: kMuted),
                                  error: (_, _) => const SizedBox.shrink(),
                                ),
                                const SizedBox(height: 3),
                                profileAsync.when(
                                  data: (p) => Text(
                                    '${p?.fullName ?? 'Admin'} · NGO Admin',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kMutedFg),
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, _) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/ngo/needs/new'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 15, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text('Post Need', style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
                                    )),
                                  ]),
                                ),
                              ),
                              Lottie.asset(
                                'assets/lottie/ngo_welcome.json',
                                width: 72, height: 60,
                                repeat: true,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Stats row
                      needsAsync.when(
                        data: (needs) => pledgesAsync.when(
                          data: (pledges) => _StatsRow(needs: needs, pledges: pledges),
                          loading: () => const StatsRowSkeleton(),
                          error: (_, _) => const SizedBox(height: 64),
                        ),
                        loading: () => const StatsRowSkeleton(),
                        error: (_, _) => const SizedBox(height: 64),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Needs Confirming ─────────────────────────────────────────
              pledgesAsync.when(
                data: (pledges) {
                  if (pledges.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('Needs Confirming', style: GoogleFonts.sora(
                              fontSize: 12, fontWeight: FontWeight.w800, color: kForeground,
                            )),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kUrgent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${pledges.length}', style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white,
                              )),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          ...pledges.map((p) => _IncomingPledgeCard(
                            pledge: p,
                            onRefresh: () {
                              ref.invalidate(myNgoPendingPledgesProvider);
                              ref.invalidate(myNgoNeedsProvider);
                              ref.invalidate(donationNeedsProvider);
                            },
                          )),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // ── Active Needs ─────────────────────────────────────────────
              needsAsync.when(
                data: (needs) {
                  final active = needs.where((n) => n.status == 'open').toList();
                  if (active.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Active Needs', style: GoogleFonts.sora(
                                fontSize: 12, fontWeight: FontWeight.w800, color: kForeground,
                              )),
                              TextButton(
                                onPressed: () => context.go('/ngo/pledges'),
                                child: Text('View All', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600,
                                )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...active.take(5).map((n) => _ActiveNeedTile(need: n)),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
                  )),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error: $e', style: const TextStyle(color: kUrgent, fontSize: 13)),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<DonationNeed> needs;
  final List<Pledge> pledges;
  const _StatsRow({required this.needs, required this.pledges});

  @override
  Widget build(BuildContext context) {
    final activeNeeds = needs.where((n) => n.status == 'open').length;
    final toConfirm = pledges.length;
    final totalPledged = needs.fold<int>(0, (s, n) => s + n.quantityPledged);
    final totalNeeded = needs.fold<int>(0, (s, n) => s + n.quantityNeeded);
    final fulfilledPct = totalNeeded > 0 ? ((totalPledged / totalNeeded) * 100).round() : 0;

    return Row(children: [
      _StatTile(value: '$activeNeeds', label: 'Active Needs', color: kPrimary),
      const SizedBox(width: 8),
      _StatTile(
        value: '$toConfirm', label: 'To Confirm',
        color: toConfirm > 0 ? kUrgent : kMutedFg,
      ),
      const SizedBox(width: 8),
      _StatTile(value: '$fulfilledPct%', label: 'Fulfilled', color: kMatched),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.sora(
            fontSize: 20, fontWeight: FontWeight.w900, color: color,
          )),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 9, color: kMutedFg,
          )),
        ],
      ),
    ),
  );
}

// ── Incoming pledge card (Needs Confirming) ──────────────────────────────────

class _IncomingPledgeCard extends ConsumerStatefulWidget {
  final Pledge pledge;
  final VoidCallback onRefresh;
  const _IncomingPledgeCard({required this.pledge, required this.onRefresh});

  @override
  ConsumerState<_IncomingPledgeCard> createState() => _IncomingPledgeCardState();
}

class _IncomingPledgeCardState extends ConsumerState<_IncomingPledgeCard> {
  bool _acting = false;

  Future<void> _confirm() async {
    setState(() => _acting = true);
    try {
      final client = ref.read(supabaseProvider);
      final userId = client.auth.currentUser?.id ?? '';
      await client.from('pledges').update({'status': 'confirmed'}).eq('id', widget.pledge.id);
      await client.from('deliveries').insert({'pledge_id': widget.pledge.id, 'confirmed_by': userId});
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to confirm: $e'),
          backgroundColor: kUrgent,
        ));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _acting = true);
    try {
      await ref.read(supabaseProvider)
          .from('pledges')
          .update({'status': 'rejected'})
          .eq('id', widget.pledge.id);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to reject: $e'),
          backgroundColor: kUrgent,
        ));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donor = widget.pledge.donor;
    final need = widget.pledge.donationNeed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            UserAvatar(
              seed: donor?.id ?? widget.pledge.donorId,
              initials: donor?.fullName.isNotEmpty == true ? donor!.fullName[0] : '?',
              avatarUrl: donor?.avatarUrl,
              radius: 19,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(donor?.fullName ?? 'Donor', style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 13, color: kForeground,
              )),
              Text(
                '${widget.pledge.quantity} units · By ${widget.pledge.deliveryDate}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kMutedFg),
              ),
            ])),
          ]),
          if (need != null) ...[
            const SizedBox(height: 8),
            Text(need.itemName, style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary,
            )),
          ],
          const SizedBox(height: 12),
          _acting
              ? const Center(child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                ))
              : Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _reject,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          border: Border.all(color: kUrgent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text('Reject', style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700, color: kUrgent,
                        ))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _confirm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text('Confirm Pledge', style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                        ))),
                      ),
                    ),
                  ),
                ]),
        ],
      ),
    );
  }
}

// ── Active need tile (compact with left stripe) ───────────────────────────────

class _ActiveNeedTile extends StatelessWidget {
  final DonationNeed need;
  const _ActiveNeedTile({required this.need});

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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(need.itemName, style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w700, color: kForeground,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('$pct%', style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, fontWeight: FontWeight.w700, color: catColor,
                      )),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/ngo/needs/new/${need.id}'),
                        child: Tooltip(
                          message: 'Reuse as template',
                          child: HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 14, color: kMutedFg),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: need.progress,
                        backgroundColor: kMuted,
                        valueColor: AlwaysStoppedAnimation(catColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
