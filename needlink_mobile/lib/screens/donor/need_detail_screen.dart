import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../models.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';

class NeedDetailScreen extends ConsumerStatefulWidget {
  final String needId;
  const NeedDetailScreen({super.key, required this.needId});
  @override
  ConsumerState<NeedDetailScreen> createState() => _NeedDetailScreenState();
}

class _NeedDetailScreenState extends ConsumerState<NeedDetailScreen> {
  DonationNeed? _need;
  bool _loading = true;
  bool _pledging = false;
  bool _success = false;
  String? _error;
  int _quantity = 1;
  DateTime? _deliveryDate;
  final _notesCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('donation_needs').select('*, ngo:ngos(*)').eq('id', widget.needId).single();
      setState(() { _need = DonationNeed.fromJson(data); _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _submitPledge() async {
    if (_need == null || _deliveryDate == null) return;
    setState(() { _pledging = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.from('pledges').insert({
        'need_id': _need!.id, 'donor_id': user.id, 'quantity': _quantity,
        'delivery_date': DateFormat('yyyy-MM-dd').format(_deliveryDate!),
        'notes': _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      });
      // quantity_pledged and status are updated atomically by a DB trigger — not here.
      ref.invalidate(myPledgesProvider);
      ref.invalidate(donationNeedsProvider);
      ref.invalidate(myNgoPendingPledgesProvider);
      setState(() { _success = true; _pledging = false; });
      HapticFeedback.mediumImpact();
      // Prompt for app review after first successful pledge
      try {
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) inAppReview.requestReview();
      } catch (_) {}
    } catch (e) {
      setState(() { _error = e.toString(); _pledging = false; });
    }
  }

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  static const _catColors = {
    'food': Color(0xFFEA580C), 'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFF16A34A), 'supplies': Color(0xFF0891B2),
  };
  static const _catIcons = {
    'food': Icons.restaurant_rounded, 'clothing': Icons.checkroom_rounded,
    'medicine': Icons.medication_rounded, 'supplies': Icons.school_rounded,
  };

  static const _shadow = [
    BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)));
    if (_need == null) return const Scaffold(body: Center(child: Text('Not found')));

    final need = _need!;
    final remaining = need.remaining;
    final isClosed = need.status == 'matched' || need.status == 'closed' || remaining <= 0;
    final catColor = _catColors[need.category] ?? kPrimary;
    final catIcon = _catIcons[need.category] ?? Icons.inventory_2_rounded;

    return Scaffold(
      body: Column(children: [
        // ── Gradient hero ────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.4, -1), end: Alignment(1, 0.6),
              colors: [Color(0xFF0C4A6E), Color(0xFF0891B2)],
            ),
          ),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _DotPainter())),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      onPressed: () => context.canPop() ? context.pop() : context.go('/donor'),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
                      onPressed: () {
                        final text = '${need.itemName} — ${need.ngo?.name ?? 'NeedLink'} needs your help!\n'
                            '${need.quantityPledged} of ${need.quantityNeeded} units pledged so far.\n'
                            'Download NeedLink to make a difference.';
                        Share.share(text);
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withAlpha(55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: catColor.withAlpha(90)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(catIcon, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            need.category[0].toUpperCase() + need.category.substring(1),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      if (need.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: kUrgent, borderRadius: BorderRadius.circular(20)),
                          child: const Text('URGENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('OPEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(need.itemName, style: GoogleFonts.sora(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2,
                    )),
                  ),
                  if (need.ngo != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(need.ngo!.name, style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.65), fontSize: 12,
                      )),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        ),

        // ── Scrollable content ────────────────────────────────────────────────
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // NGO card
            if (need.ngo != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSurface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder), boxShadow: _shadow,
                ),
                child: Row(children: [
                  UserAvatar(
                    seed: need.ngo!.id,
                    initials: need.ngo!.name.isNotEmpty ? need.ngo!.name[0].toUpperCase() : 'N',
                    avatarUrl: need.ngo!.logoUrl,
                    radius: 22,
                    isOrg: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(need.ngo!.name, style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 14, color: kForeground,
                    )),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: kMutedFg),
                      const SizedBox(width: 3),
                      Text(need.ngo!.location, style: const TextStyle(fontSize: 12, color: kMutedFg)),
                    ]),
                  ])),
                  if (need.ngo!.verified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kMatched.withAlpha(20), borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.verified_rounded, size: 12, color: kMatched),
                        SizedBox(width: 4),
                        Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMatched)),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            // Progress block
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFF), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder), boxShadow: _shadow,
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${need.quantityPledged}', style: GoogleFonts.sora(
                      fontSize: 28, fontWeight: FontWeight.w900, color: kPrimary,
                    )),
                    Text('Pledged', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kMutedFg)),
                  ]),
                  Column(children: [
                    Text('${(need.progress * 100).round()}%', style: GoogleFonts.sora(
                      fontSize: 28, fontWeight: FontWeight.w900, color: kForeground,
                    )),
                    Text('Progress', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kMutedFg)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${need.quantityNeeded}', style: GoogleFonts.sora(
                      fontSize: 28, fontWeight: FontWeight.w900, color: kForeground,
                    )),
                    Text('Goal', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kMutedFg)),
                  ]),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: need.progress,
                    backgroundColor: kMuted,
                    valueColor: AlwaysStoppedAnimation(need.progress >= 1 ? kMatched : kPrimary),
                    minHeight: 8,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Description
            if (need.description != null && need.description!.isNotEmpty) ...[
              Text('ABOUT THIS NEED', style: GoogleFonts.sora(
                fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
              )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSurface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder), boxShadow: _shadow,
                ),
                child: Text(need.description!, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: kForeground, height: 1.65,
                )),
              ),
              const SizedBox(height: 16),
            ],

            // Logistics
            Text('LOGISTICS', style: GoogleFonts.sora(
              fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder), boxShadow: _shadow,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _InfoRow(Icons.inventory_2_outlined, 'Still needed', '$remaining units'),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kBorder)),
                _InfoRow(Icons.calendar_today_outlined, 'Deadline', need.deadline),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kBorder)),
                _InfoRow(
                  Icons.category_outlined, 'Category',
                  need.category[0].toUpperCase() + need.category.substring(1),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Success banner
            if (_success)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(children: [
                  Lottie.asset(
                    'assets/lottie/pledge_success.json',
                    width: 200, height: 160,
                    repeat: false,
                  ),
                  const SizedBox(height: 4),
                  Text('Pledge submitted!', style: GoogleFonts.sora(
                    fontSize: 17, fontWeight: FontWeight.w800, color: kMatched,
                  )),
                  const SizedBox(height: 4),
                  Text(
                    'The NGO will review your pledge.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => context.go('/donor/pledges'),
                    child: Text('View my pledges →', style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: kPrimary, fontWeight: FontWeight.w700,
                    )),
                  ),
                ]),
              ),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
              ),

            const SizedBox(height: 100),
          ]),
        )),
      ]),
      bottomSheet: isClosed || _success ? null : _PledgeSheet(
        remaining: remaining, quantity: _quantity, deliveryDate: _deliveryDate,
        notesCtrl: _notesCtrl, pledging: _pledging, need: need,
        onQuantityChanged: (v) => setState(() => _quantity = v),
        onDateChanged: (d) => setState(() => _deliveryDate = d),
        onSubmit: _submitPledge,
      ),
    );
  }
}

// ── Pledge bottom sheet ──────────────────────────────────────────────────────

class _PledgeSheet extends StatelessWidget {
  final int remaining, quantity;
  final DateTime? deliveryDate;
  final TextEditingController notesCtrl;
  final bool pledging;
  final DonationNeed need;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onSubmit;

  const _PledgeSheet({
    required this.remaining, required this.quantity, required this.deliveryDate,
    required this.notesCtrl, required this.pledging, required this.need,
    required this.onQuantityChanged, required this.onDateChanged, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 20),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      border: Border.all(color: kBorder),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, -4))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 14),
      Text('Make a Pledge', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: kForeground)),
      const SizedBox(height: 16),

      Row(children: [
        Text('Quantity', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg)),
        const Spacer(),
        GestureDetector(
          onTap: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: quantity > 1 ? kPrimary.withAlpha(20) : kMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove_rounded, size: 18, color: quantity > 1 ? kPrimary : kMutedFg),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text('$quantity', style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w900, color: kForeground)),
        ),
        GestureDetector(
          onTap: quantity < remaining ? () => onQuantityChanged(quantity + 1) : null,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add_rounded, size: 18, color: kPrimary),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      GestureDetector(
        onTap: () async {
          DateTime lastDate;
          try { lastDate = DateTime.parse(need.deadline); } catch (_) { lastDate = DateTime.now().add(const Duration(days: 60)); }
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 3)),
            firstDate: DateTime.now(), lastDate: lastDate,
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
              child: child!,
            ),
          );
          if (d != null) onDateChanged(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: kBackground, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: deliveryDate != null ? kPrimary : kBorder),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: deliveryDate != null ? kPrimary : kMutedFg),
            const SizedBox(width: 10),
            Text(
              deliveryDate != null ? DateFormat('MMM d, yyyy').format(deliveryDate!) : 'Select delivery date',
              style: TextStyle(
                color: deliveryDate != null ? kForeground : kMutedFg, fontSize: 13,
                fontWeight: deliveryDate != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 10),

      TextField(
        controller: notesCtrl,
        maxLines: 2,
        style: GoogleFonts.plusJakartaSans(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Notes for the NGO (optional)',
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      const SizedBox(height: 16),

      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: (pledging || deliveryDate == null) ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: kPrimary.withValues(alpha: 0.4),
          ),
          child: pledging
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Submit Pledge', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  );
}

// ── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: kMutedFg),
    const SizedBox(width: 10),
    Text('$label: ', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg)),
    Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(
      fontSize: 13, fontWeight: FontWeight.w700, color: kForeground,
    ))),
  ]);
}

// ── Dot pattern painter (matches donor home hero) ─────────────────────────────

class _DotPainter extends CustomPainter {
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}
