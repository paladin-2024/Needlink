import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';

class NgoHomeScreen extends ConsumerWidget {
  const NgoHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final needsAsync = ref.watch(myNgoNeedsProvider);
    final pledgesAsync = ref.watch(myNgoPendingPledgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ngo/needs/new'),
        backgroundColor: kAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Post Need', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async {
          ref.invalidate(myNgoNeedsProvider);
          ref.invalidate(myNgoPendingPledgesProvider);
          ref.invalidate(profileProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Greeting
            profileAsync.when(
              data: (p) {
                final first = p?.fullName.split(' ').first ?? 'Admin';
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back, $first',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kForeground)),
                  const SizedBox(height: 2),
                  const Text("Here's your organization overview",
                    style: TextStyle(fontSize: 13, color: kMutedFg)),
                ]);
              },
              loading: () => const SizedBox(height: 32),
              error: (_, __) => const SizedBox(height: 32),
            ),
            const SizedBox(height: 20),

            // Metric cards
            needsAsync.when(
              data: (needs) => pledgesAsync.when(
                data: (pledges) {
                  final totalPledges = needs.fold<int>(0, (sum, n) => sum + n.quantityPledged);
                  final itemsReceived = pledges
                      .where((p) => p.status == 'confirmed')
                      .fold<int>(0, (sum, p) => sum + p.quantity);
                  return Row(children: [
                    Expanded(child: _MetricCard(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Total Pledges',
                      value: totalPledges.toString(),
                      growth: null,
                      color: kPrimary,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricCard(
                      icon: Icons.inventory_2_rounded,
                      label: 'Items Received',
                      value: itemsReceived.toString(),
                      growth: null,
                      color: kMatched,
                    )),
                  ]);
                },
                loading: () => const SizedBox(height: 90),
                error: (_, __) => const SizedBox(height: 90),
              ),
              loading: () => const SizedBox(height: 90),
              error: (_, __) => const SizedBox(height: 90),
            ),
            const SizedBox(height: 24),

            // Active Requests
            needsAsync.when(
              data: (needs) {
                final active = needs.where((n) => n.status == 'open' || n.status == 'urgent').take(3).toList();
                if (active.isEmpty) return const SizedBox.shrink();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Active Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kForeground)),
                    TextButton(
                      onPressed: () => context.go('/ngo/pledges'),
                      child: const Text('View All'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  ...active.map((n) => _NeedProgressCard(need: n)),
                  const SizedBox(height: 8),
                ]);
              },
              loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: kUrgent)),
            ),

            // Incoming Pledges
            pledgesAsync.when(
              data: (pledges) {
                if (pledges.isEmpty) return const SizedBox.shrink();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('Incoming Pledges',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kForeground)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(20)),
                      child: Text('${pledges.length} New',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  ...pledges.take(3).map((p) => _IncomingPledgeCard(
                    pledge: p,
                    onRefresh: () {
                      ref.invalidate(myNgoPendingPledgesProvider);
                      ref.invalidate(myNgoNeedsProvider);
                    },
                  )),
                ]);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? growth;
  final Color color;
  const _MetricCard({required this.icon, required this.label, required this.value, required this.color, this.growth});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 12),
      Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: kMutedFg))),
        if (growth != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: kMatched.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Text(growth!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kMatched)),
          ),
      ]),
    ]),
  );
}

class _NeedProgressCard extends StatelessWidget {
  final DonationNeed need;
  const _NeedProgressCard({required this.need});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: need.isUrgent ? kUrgent.withAlpha(60) : kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: need.isUrgent ? kUrgent.withAlpha(20) : kPrimary.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            need.isUrgent ? 'Urgent' : 'In Progress',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: need.isUrgent ? kUrgent : kPrimary,
            ),
          ),
        ),
        const Spacer(),
        Text('${(need.progress * 100).round()}%',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPrimary)),
      ]),
      const SizedBox(height: 8),
      Text(need.itemName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kForeground)),
      const SizedBox(height: 2),
      Text('Goal: ${need.quantityNeeded} units · Deadline ${need.deadline}',
        style: const TextStyle(fontSize: 12, color: kMutedFg)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: need.progress,
          backgroundColor: kMuted,
          valueColor: AlwaysStoppedAnimation(need.isUrgent ? kUrgent : kPrimary),
          minHeight: 7,
        ),
      ),
    ]),
  );
}

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
      final userId = client.auth.currentUser!.id;
      await client.from('pledges').update({'status': 'confirmed'}).eq('id', widget.pledge.id);
      await client.from('deliveries').insert({'pledge_id': widget.pledge.id, 'confirmed_by': userId});
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm: $e'), backgroundColor: kUrgent),
        );
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
        color: kSurface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: kPrimary.withAlpha(20), shape: BoxShape.circle),
          child: Center(child: Text(
            donor?.fullName.isNotEmpty == true ? donor!.fullName[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary, fontSize: 16),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(donor?.fullName ?? 'Donor',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kForeground)),
          Text('${widget.pledge.quantity} units · ${need?.itemName ?? ''}',
            style: const TextStyle(fontSize: 12, color: kMutedFg)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 11, color: kMutedFg),
            const SizedBox(width: 3),
            Text('Delivery by ${widget.pledge.deliveryDate}',
              style: const TextStyle(fontSize: 11, color: kMutedFg)),
          ]),
        ])),
        const SizedBox(width: 8),
        _acting
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
            : ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMatched,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Confirm',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
      ]),
    );
  }
}
