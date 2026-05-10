import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

class NeedCard extends StatelessWidget {
  final DonationNeed need;
  final VoidCallback onTap;

  const NeedCard({super.key, required this.need, required this.onTap});

  static const _catColors = {
    'food': Color(0xFFFFF7ED),
    'clothing': Color(0xFFF5F3FF),
    'medicine': Color(0xFFFEF2F2),
    'supplies': Color(0xFFEFF6FF),
  };
  static const _catTextColors = {
    'food': Color(0xFFC2410C),
    'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFFDC2626),
    'supplies': Color(0xFF1D4ED8),
  };
  static const _catEmojis = {
    'food': '🌾', 'clothing': '👕', 'medicine': '💊', 'supplies': '📦',
  };

  @override
  Widget build(BuildContext context) {
    final catBg = _catColors[need.category] ?? kMuted;
    final catFg = _catTextColors[need.category] ?? kMutedFg;
    final emoji = _catEmojis[need.category] ?? '📦';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: catBg, borderRadius: BorderRadius.circular(20)),
                child: Text('$emoji ${need.category}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: catFg)),
              ),
              const SizedBox(width: 8),
              if (need.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: kUrgent, borderRadius: BorderRadius.circular(20)),
                  child: const Text('⚡ URGENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              const Spacer(),
              _StatusChip(status: need.status),
            ]),
            const SizedBox(height: 10),
            Text(need.itemName, style: const TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 16, color: kForeground)),
            if (need.ngo != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: kMutedFg),
                const SizedBox(width: 4),
                Expanded(child: Text('${need.ngo!.name} · ${need.ngo!.location}',
                  style: const TextStyle(fontSize: 12, color: kMutedFg), overflow: TextOverflow.ellipsis)),
              ]),
            ],
            if (need.description != null && need.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(need.description!, style: const TextStyle(fontSize: 12, color: kMutedFg), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.inventory_2_outlined, size: 13, color: kMutedFg),
              const SizedBox(width: 4),
              Text('${need.quantityPledged}/${need.quantityNeeded}', style: const TextStyle(fontSize: 12, color: kMutedFg)),
              const Spacer(),
              Text('${(need.progress * 100).round()}%',
                style: const TextStyle(fontSize: 12, fontFamily: 'FiraCode', color: kMutedFg)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: need.progress,
                backgroundColor: kMuted,
                valueColor: AlwaysStoppedAnimation(need.progress >= 1 ? kMatched : kPrimary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: kMutedFg),
              const SizedBox(width: 4),
              Text('Deadline: ${need.deadline}', style: const TextStyle(fontSize: 11, color: kMutedFg)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'open': (const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
      'matched': (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'closed': (const Color(0xFFF1F5F9), kMutedFg),
    };
    final c = colors[status] ?? (kMuted, kMutedFg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.$1, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'FiraCode', color: c.$2)),
    );
  }
}
