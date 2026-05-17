import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../theme.dart';

class TrackingDetailScreen extends StatefulWidget {
  final String pledgeId;
  const TrackingDetailScreen({super.key, required this.pledgeId});
  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  Pledge? _pledge;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('pledges')
          .select('*, donation_need:donation_needs(*, ngo:ngos(*))')
          .eq('id', widget.pledgeId)
          .single();
      setState(() { _pledge = Pledge.fromJson(data); _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)));
    if (_error != null) return Scaffold(body: Center(child: Text('Error: $_error', style: const TextStyle(color: kUrgent))));
    if (_pledge == null) return const Scaffold(body: Center(child: Text('Not found')));

    final p = _pledge!;
    final need = p.donationNeed;
    final ngo = need?.ngo;
    final isPending = p.status == 'pending';
    final isConfirmed = p.status == 'confirmed';

    final timeline = _buildTimeline(p);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go('/donor/pledges')),
        actions: [IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // Product card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(need?.itemName ?? 'Donation',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kForeground)),
              if (ngo != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: kMutedFg),
                  const SizedBox(width: 4),
                  Text('To: ${ngo.name}, ${ngo.location}', style: const TextStyle(fontSize: 13, color: kMutedFg)),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // Status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: isConfirmed ? kMatched : isPending ? const Color(0xFFD97706) : kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConfirmed ? 'Delivered' : isPending ? 'Awaiting Confirmation' : 'In Transit',
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15,
                    color: isConfirmed ? kMatched : isPending ? const Color(0xFFD97706) : kPrimary,
                  ),
                ),
              ]),
              if (!isConfirmed && !isPending) ...[
                const SizedBox(height: 12),
                Center(
                  child: Lottie.asset(
                    'assets/lottie/delivery_walk.json',
                    width: 180, height: 110,
                    repeat: true,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _InfoRow(Icons.qr_code_rounded, 'Pledge ID', 'NL-${widget.pledgeId.substring(0, 8).toUpperCase()}'),
              const SizedBox(height: 8),
              _InfoRow(Icons.calendar_today_rounded, 'Delivery Date', p.deliveryDate),
              const SizedBox(height: 8),
              _InfoRow(Icons.inventory_2_outlined, 'Quantity', '${p.quantity} units'),
              if (p.notes != null && p.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(Icons.notes_rounded, 'Notes', p.notes!),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.support_agent_rounded, size: 16),
                label: const Text('Contact Support'),
                style: OutlinedButton.styleFrom(foregroundColor: kPrimary, side: const BorderSide(color: kPrimary)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Timeline
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Shipment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kForeground)),
              const SizedBox(height: 16),
              ...timeline.asMap().entries.map((e) => _TimelineNode(
                event: e.value,
                isLast: e.key == timeline.length - 1,
                isFirst: e.key == 0,
              )),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  List<_TimelineEvent> _buildTimeline(Pledge p) {
    final events = <_TimelineEvent>[];
    final createdDate = DateTime.tryParse(p.createdAt);

    if (p.status == 'confirmed') {
      events.add(_TimelineEvent(Icons.verified_rounded, 'Delivery Confirmed', 'NGO confirmed receipt', kMatched, true));
    }
    events.add(_TimelineEvent(Icons.local_shipping_rounded, 'In Transit', 'Heading to ${p.donationNeed?.ngo?.location ?? 'NGO'}', kPrimary, p.status == 'confirmed'));
    events.add(_TimelineEvent(Icons.calendar_today_rounded, 'Pledge Scheduled', 'Delivery by ${p.deliveryDate}', const Color(0xFF7C3AED), true));
    events.add(_TimelineEvent(Icons.verified_outlined, 'Pledge Confirmed', createdDate != null ? DateFormat('MMM d, yyyy').format(createdDate) : p.createdAt, kMatched, true));

    return events;
  }
}

class _TimelineEvent {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool done;
  const _TimelineEvent(this.icon, this.title, this.subtitle, this.color, this.done);
}

class _TimelineNode extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;
  final bool isFirst;
  const _TimelineNode({required this.event, required this.isLast, required this.isFirst});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: event.done ? event.color.withAlpha(25) : kMuted,
          shape: BoxShape.circle,
        ),
        child: Icon(event.icon, size: 18, color: event.done ? event.color : kMutedFg),
      ),
      if (!isLast)
        Container(width: 2, height: 40, color: event.done ? event.color.withAlpha(60) : kMuted),
    ]),
    const SizedBox(width: 12),
    Expanded(child: Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event.title, style: TextStyle(fontWeight: FontWeight.w600, color: event.done ? kForeground : kMutedFg)),
        const SizedBox(height: 2),
        Text(event.subtitle, style: const TextStyle(fontSize: 12, color: kMutedFg)),
      ]),
    )),
  ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: kMutedFg),
    const SizedBox(width: 8),
    Text('$label: ', style: const TextStyle(fontSize: 13, color: kMutedFg)),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground))),
  ]);
}
