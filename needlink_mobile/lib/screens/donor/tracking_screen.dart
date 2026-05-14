import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pledgesAsync = ref.watch(myPledgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking'),
        actions: [IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {})],
      ),
      body: pledgesAsync.when(
        data: (pledges) {
          final active = pledges.where((p) => p.status != 'rejected').toList();
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () => ref.refresh(myPledgesProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Map banner
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [kDark, kPrimaryDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(children: [
                    // Grid overlay effect
                    ...List.generate(5, (i) => Positioned(
                      left: i * 70.0, top: 0, bottom: 0,
                      child: VerticalDivider(color: Colors.white.withAlpha(15), width: 1),
                    )),
                    Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.local_shipping_rounded, size: 36, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        '${active.length} Shipment${active.length != 1 ? 's' : ''} active across Uganda',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ])),
                  ]),
                ),
                const SizedBox(height: 20),

                if (active.isEmpty)
                  _EmptyTracking()
                else ...[
                  const Text('Your Donations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kForeground)),
                  const SizedBox(height: 12),
                  ...active.map((p) => _TrackingCard(
                    pledge: p,
                    onTap: () => context.go('/donor/tracking/${p.id}'),
                  )),
                  const SizedBox(height: 24),
                ],

                // Impact banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kMatched.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kMatched.withAlpha(50)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: kMatched.withAlpha(25), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_rounded, color: kMatched, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Donation Impact', style: TextStyle(fontWeight: FontWeight.w700, color: kForeground)),
                      Text('Every pledge you make reaches a community in need.',
                        style: const TextStyle(fontSize: 12, color: kMutedFg)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 12),

                // Help section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurface, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.w700, color: kForeground)),
                    const SizedBox(height: 4),
                    const Text('24/7 logistics support available.', style: TextStyle(fontSize: 13, color: kMutedFg)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.support_agent_rounded, size: 16),
                        label: const Text('Contact Support'),
                        style: OutlinedButton.styleFrom(foregroundColor: kPrimary, side: const BorderSide(color: kPrimary)),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.help_outline_rounded, size: 16),
                        label: const Text('FAQs'),
                        style: OutlinedButton.styleFrom(foregroundColor: kMutedFg, side: const BorderSide(color: kBorder)),
                      )),
                    ]),
                  ]),
                ),
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

class _TrackingCard extends StatelessWidget {
  final Pledge pledge;
  final VoidCallback onTap;
  const _TrackingCard({required this.pledge, required this.onTap});

  static const _statusConfig = {
    'pending': (Color(0xFFFFFBEB), Color(0xFFD97706), 'Scheduled', Icons.calendar_today_rounded, 0.05),
    'confirmed': (Color(0xFFF0FDF4), Color(0xFF15803D), 'Delivered', Icons.check_circle_rounded, 1.0),
    'rejected': (Color(0xFFFEF2F2), Color(0xFFDC2626), 'Cancelled', Icons.cancel_rounded, 0.0),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig[pledge.status] ?? (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), 'In Transit', Icons.local_shipping_rounded, 0.65);
    final need = pledge.donationNeed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
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
              Text(need?.itemName ?? 'Donation', style: const TextStyle(fontWeight: FontWeight.w600, color: kForeground)),
              Text(need?.ngo?.name ?? '', style: const TextStyle(fontSize: 12, color: kMutedFg)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: cfg.$1, borderRadius: BorderRadius.circular(20)),
              child: Text(cfg.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg.$2)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(cfg.$5 * 100).round()}% complete',
              style: const TextStyle(fontSize: 11, color: kMutedFg)),
            Text('Delivery: ${pledge.deliveryDate}',
              style: const TextStyle(fontSize: 11, color: kMutedFg)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cfg.$5,
              backgroundColor: kMuted,
              valueColor: AlwaysStoppedAnimation(cfg.$2),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.visibility_outlined, size: 14),
              label: const Text('View Details'),
              style: TextButton.styleFrom(foregroundColor: kPrimary, padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _EmptyTracking extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(mainAxisSize: MainAxisSize.min, children: const [
      Icon(Icons.local_shipping_outlined, size: 52, color: kMuted),
      SizedBox(height: 14),
      Text('No active shipments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kForeground)),
      SizedBox(height: 6),
      Text('Make a pledge to start tracking', style: TextStyle(fontSize: 13, color: kMutedFg)),
    ]),
  );
}
