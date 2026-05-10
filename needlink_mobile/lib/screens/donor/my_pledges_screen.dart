import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers.dart';
import '../../theme.dart';

class MyPledgesScreen extends ConsumerWidget {
  const MyPledgesScreen({super.key});

  static const _statusColors = {
    'pending': (Color(0xFFFFFBEB), Color(0xFFD97706)),
    'matched': (Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
    'in_transit': (Color(0xFFF5F3FF), Color(0xFF7C3AED)),
    'confirmed': (Color(0xFFF0FDF4), Color(0xFF15803D)),
    'rejected': (Color(0xFFFEF2F2), Color(0xFFDC2626)),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pledgesAsync = ref.watch(myPledgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pledges'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/donor')),
      ),
      body: pledgesAsync.when(
        data: (pledges) {
          if (pledges.isEmpty) return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: kMuted),
              SizedBox(height: 12),
              Text("You haven't pledged anything yet", style: TextStyle(fontFamily: 'FiraCode', color: kMutedFg)),
            ]),
          );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pledges.length,
            itemBuilder: (_, i) {
              final p = pledges[i];
              final colors = _statusColors[p.status] ?? (kMuted, kMutedFg);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.status == 'pending' ? const Color(0xFFFDE68A) : kBorder),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(p.donationNeed?.itemName ?? 'Unknown item',
                      style: const TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, color: kForeground))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(20)),
                      child: Text(p.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'FiraCode', color: colors.$2)),
                    ),
                  ]),
                  if (p.donationNeed?.ngo != null) ...[
                    const SizedBox(height: 4),
                    Text('${p.donationNeed!.ngo!.name} · ${p.donationNeed!.ngo!.location}',
                      style: const TextStyle(fontSize: 12, color: kMutedFg)),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.inventory_2_outlined, size: 14, color: kMutedFg),
                    const SizedBox(width: 6),
                    Text('${p.quantity} units', style: const TextStyle(fontSize: 13, color: kForeground, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: kMutedFg),
                    const SizedBox(width: 6),
                    Text('By ${p.deliveryDate}', style: const TextStyle(fontSize: 13, color: kMutedFg)),
                  ]),
                  if (p.notes != null && p.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('"${p.notes}"', style: const TextStyle(fontSize: 12, color: kMutedFg, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 6),
                  Text('Pledged on ${DateFormat('MMM d, yyyy').format(DateTime.parse(p.createdAt))}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'FiraCode')),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
