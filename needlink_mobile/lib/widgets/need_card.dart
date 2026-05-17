import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import '../theme.dart';
import '../providers.dart';
import 'user_avatar.dart';

class NeedCard extends ConsumerWidget {
  final DonationNeed need;
  final VoidCallback onTap;
  const NeedCard({super.key, required this.need, required this.onTap});

  static const _categoryIcons = {
    'food': Icons.restaurant_rounded,
    'clothing': Icons.checkroom_rounded,
    'medicine': Icons.medication_rounded,
    'supplies': Icons.school_rounded,
  };

  static const _categoryColors = {
    'food': Color(0xFF16A34A),
    'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFFEF4444),
    'supplies': Color(0xFF2563EB),
  };

  static const _categoryGradients = {
    'food': [Color(0xFF14532D), Color(0xFF166534)],
    'clothing': [Color(0xFF3B0764), Color(0xFF5B21B6)],
    'medicine': [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
    'supplies': [Color(0xFF1E3A5F), Color(0xFF1D4ED8)],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMatched = need.status == 'matched';
    final isUrgent = need.isUrgent;
    final progress = need.progress;
    final catColor = _categoryColors[need.category] ?? kPrimary;
    final gradients = _categoryGradients[need.category] ?? [kDark, kPrimaryDark];
    final savedIds = ref.watch(savedNeedIdsProvider).when(
      data: (ids) => ids, loading: () => const <String>{}, error: (err, st) => const <String>{},
    );
    final isSaved = savedIds.contains(need.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: need.isFeatured
              ? kPrimary.withAlpha(80)
              : isUrgent ? kUrgent.withAlpha(80) : kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Hero image area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradients,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
                Positioned(top: 12, left: 12,
                  child: _StatusBadge(isUrgent: isUrgent, isMatched: isMatched, isFeatured: need.isFeatured)),
                // Save button top-right
                Positioned(
                  top: 8, right: 8,
                  child: _SaveButton(needId: need.id, isSaved: isSaved, ref: ref),
                ),
                Center(child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _categoryIcons[need.category] ?? Icons.inventory_2_rounded,
                    size: 28, color: Colors.white,
                  ),
                )),
                if (need.ngo != null)
                  Positioned(
                    bottom: 10, left: 12,
                    child: Row(children: [
                      UserAvatar(
                        seed: need.ngo!.id,
                        initials: need.ngo!.name.isNotEmpty ? need.ngo!.name[0].toUpperCase() : 'N',
                        avatarUrl: need.ngo!.logoUrl,
                        radius: 10, isOrg: true,
                      ),
                      const SizedBox(width: 6),
                      Text(need.ngo!.name,
                        style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
              ]),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(need.itemName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kForeground),
                maxLines: 2, overflow: TextOverflow.ellipsis),

              if (need.description != null && need.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(need.description!,
                  style: const TextStyle(fontSize: 12, color: kMutedFg, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${need.quantityPledged} of ${need.quantityNeeded} pledged',
                  style: const TextStyle(fontSize: 11, color: kMutedFg)),
                Text('${(progress * 100).round()}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isMatched ? kMatched : catColor)),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: kMuted,
                  valueColor: AlwaysStoppedAnimation(isMatched ? kMatched : catColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),

              Row(children: [
                if (need.ngo?.location != null) ...[
                  const Icon(Icons.location_on_outlined, size: 13, color: kMutedFg),
                  const SizedBox(width: 3),
                  Flexible(child: Text(need.ngo!.location,
                    style: const TextStyle(fontSize: 12, color: kMutedFg),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.calendar_today_outlined, size: 12, color: kMutedFg),
                const SizedBox(width: 3),
                Text('By ${need.deadline}', style: const TextStyle(fontSize: 12, color: kMutedFg)),
                const Spacer(),
                if (isMatched)
                  _GoalChip()
                else
                  _PledgeNowBtn(onTap: onTap),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final String needId;
  final bool isSaved;
  final WidgetRef ref;
  const _SaveButton({required this.needId, required this.isSaved, required this.ref});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> with SingleTickerProviderStateMixin {
  late bool _saved;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1, end: 1.3).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_SaveButton old) {
    super.didUpdateWidget(old);
    if (old.isSaved != widget.isSaved) setState(() => _saved = widget.isSaved);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    HapticFeedback.lightImpact();
    await _ctrl.forward();
    await _ctrl.reverse();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_saved) {
      await Supabase.instance.client
          .from('saved_needs')
          .delete()
          .eq('donor_id', user.id)
          .eq('need_id', widget.needId);
    } else {
      await Supabase.instance.client
          .from('saved_needs')
          .upsert({'donor_id': user.id, 'need_id': widget.needId});
    }
    setState(() => _saved = !_saved);
    widget.ref.invalidate(savedNeedIdsProvider);
    widget.ref.invalidate(savedNeedsProvider);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _toggle,
    child: ScaleTransition(
      scale: _scale,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _saved ? const Color(0xFFDC2626).withAlpha(20) : Colors.white.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 17,
          color: _saved ? const Color(0xFFDC2626) : Colors.white70,
        ),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool isUrgent;
  final bool isMatched;
  final bool isFeatured;
  const _StatusBadge({required this.isUrgent, required this.isMatched, required this.isFeatured});

  @override
  Widget build(BuildContext context) {
    if (isMatched) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: kMatched, borderRadius: BorderRadius.circular(20)),
        child: const Text('MATCHED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
      );
    }
    if (isFeatured && !isUrgent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.star_rounded, size: 11, color: Colors.white),
          SizedBox(width: 3),
          Text('FEATURED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      );
    }
    if (isUrgent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: kUrgent, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.priority_high_rounded, size: 11, color: Colors.white),
          SizedBox(width: 3),
          Text('URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: const Text('OPEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _PledgeNowBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _PledgeNowBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.volunteer_activism, size: 13, color: Colors.white),
        SizedBox(width: 5),
        Text('Pledge Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    ),
  );
}

class _GoalChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: kMatched.withAlpha(22), borderRadius: BorderRadius.circular(20)),
    child: const Text('Goal Reached', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMatched)),
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
