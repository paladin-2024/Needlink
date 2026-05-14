import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../theme.dart';

class NeedDetailScreen extends StatefulWidget {
  final String needId;
  const NeedDetailScreen({super.key, required this.needId});
  @override
  State<NeedDetailScreen> createState() => _NeedDetailScreenState();
}

class _NeedDetailScreenState extends State<NeedDetailScreen> {
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
    final data = await Supabase.instance.client
        .from('donation_needs').select('*, ngo:ngos(*)').eq('id', widget.needId).single();
    setState(() { _need = DonationNeed.fromJson(data); _loading = false; });
  }

  Future<void> _submitPledge() async {
    if (_need == null || _deliveryDate == null) return;
    setState(() { _pledging = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.from('pledges').insert({
        'need_id': _need!.id, 'donor_id': user.id, 'quantity': _quantity,
        'delivery_date': DateFormat('yyyy-MM-dd').format(_deliveryDate!),
        'notes': _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      });
      final newPledged = _need!.quantityPledged + _quantity;
      final newStatus = newPledged >= _need!.quantityNeeded ? 'matched' : _need!.status;
      await Supabase.instance.client.from('donation_needs')
          .update({'quantity_pledged': newPledged, 'status': newStatus}).eq('id', _need!.id);
      setState(() { _success = true; _pledging = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _pledging = false; });
    }
  }

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)));
    if (_need == null) return const Scaffold(body: Center(child: Text('Not found')));

    final need = _need!;
    final remaining = need.remaining;
    final isClosed = need.status == 'matched' || need.status == 'closed' || remaining <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Need Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/donor')),
        actions: [IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // Category / priority chips
          Row(children: [
            _CategoryChip(need.category),
            const SizedBox(width: 8),
            if (need.isUrgent) _PriorityChip('URGENT', kUrgent),
            if (!need.isUrgent) _PriorityChip('OPEN', kPrimary),
          ]),
          const SizedBox(height: 12),

          // Item name
          Text(need.itemName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kForeground, height: 1.2)),
          const SizedBox(height: 8),

          // NGO info
          if (need.ngo != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.corporate_fare_rounded, size: 22, color: kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(need.ngo!.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kForeground)),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: kMutedFg),
                    const SizedBox(width: 3),
                    Text(need.ngo!.location, style: const TextStyle(fontSize: 12, color: kMutedFg)),
                  ]),
                ])),
                if (need.ngo!.verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: kMatched.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(Icons.verified_rounded, size: 12, color: kMatched),
                      SizedBox(width: 4),
                      Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMatched)),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
          ],

          // Progress block
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${need.quantityPledged}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kPrimary)),
                  const Text('Pledged', style: TextStyle(fontSize: 12, color: kMutedFg)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text('${(need.progress * 100).round()}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kForeground)),
                  const Text('Progress', style: TextStyle(fontSize: 12, color: kMutedFg)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${need.quantityNeeded}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kForeground)),
                  const Text('Goal', style: TextStyle(fontSize: 12, color: kMutedFg)),
                ]),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: need.progress,
                  backgroundColor: kMuted,
                  valueColor: AlwaysStoppedAnimation(need.progress >= 1 ? kMatched : kPrimary),
                  minHeight: 10,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Description
          if (need.description != null && need.description!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('About this need', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground)),
                const SizedBox(height: 8),
                Text(need.description!, style: const TextStyle(fontSize: 13, color: kForeground, height: 1.6)),
              ]),
            ),
            const SizedBox(height: 14),
          ],

          // Logistics
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Logistics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground)),
              const SizedBox(height: 12),
              _InfoRow(Icons.inventory_2_outlined, 'Still needed', '$remaining units'),
              const SizedBox(height: 8),
              _InfoRow(Icons.calendar_today_outlined, 'Deadline', need.deadline),
              const SizedBox(height: 8),
              _InfoRow(Icons.category_outlined, 'Category', need.category[0].toUpperCase() + need.category.substring(1)),
            ]),
          ),
          const SizedBox(height: 20),

          // Success banner
          if (_success)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: kMatched, size: 26),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pledge submitted!', style: TextStyle(fontWeight: FontWeight.w700, color: kMatched)),
                  const SizedBox(height: 2),
                  const Text('The NGO will review your pledge.', style: TextStyle(fontSize: 13, color: kMutedFg)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => context.go('/donor/pledges'),
                    child: const Text('View my pledges →', style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600)),
                  ),
                ])),
              ]),
            ),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
            ),
        ]),
      ),

      // Persistent FAB / pledge form at bottom
      bottomSheet: isClosed || _success ? null : _PledgeSheet(
        remaining: remaining,
        quantity: _quantity,
        deliveryDate: _deliveryDate,
        notesCtrl: _notesCtrl,
        pledging: _pledging,
        need: need,
        onQuantityChanged: (v) => setState(() => _quantity = v),
        onDateChanged: (d) => setState(() => _deliveryDate = d),
        onSubmit: _submitPledge,
      ),
    );
  }
}

class _PledgeSheet extends StatelessWidget {
  final int remaining;
  final int quantity;
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
    padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      border: Border.all(color: kBorder),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, -4))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 12),
      const Text('Make a Pledge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kForeground)),
      const SizedBox(height: 16),

      // Quantity stepper
      Row(children: [
        const Text('Quantity', style: TextStyle(fontSize: 13, color: kMutedFg)),
        const Spacer(),
        IconButton(
          onPressed: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, color: kPrimary),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kForeground)),
        ),
        IconButton(
          onPressed: quantity < remaining ? () => onQuantityChanged(quantity + 1) : null,
          icon: const Icon(Icons.add_circle_outline, color: kPrimary),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
      ]),
      const SizedBox(height: 12),

      // Date picker
      GestureDetector(
        onTap: () async {
          DateTime lastDate;
          try { lastDate = DateTime.parse(need.deadline); } catch (_) { lastDate = DateTime.now().add(const Duration(days: 60)); }
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 3)),
            firstDate: DateTime.now(),
            lastDate: lastDate,
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
              child: child!,
            ),
          );
          if (d != null) onDateChanged(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kBackground, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: deliveryDate != null ? kPrimary : kBorder),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: kMutedFg),
            const SizedBox(width: 10),
            Text(
              deliveryDate != null ? DateFormat('MMM d, yyyy').format(deliveryDate!) : 'Select delivery date',
              style: TextStyle(color: deliveryDate != null ? kForeground : kMutedFg, fontSize: 13),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      TextField(
        controller: notesCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'Notes for the NGO (optional)',
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      const SizedBox(height: 16),

      ElevatedButton(
        onPressed: (pledging || deliveryDate == null) ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: pledging
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Submit Pledge', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip(this.category);

  static const _icons = {
    'food': Icons.restaurant_rounded,
    'clothing': Icons.checkroom_rounded,
    'medicine': Icons.medication_rounded,
    'supplies': Icons.school_rounded,
  };
  static const _colors = {
    'food': Color(0xFF0891B2),
    'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFF059669),
    'supplies': Color(0xFFD97706),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category] ?? kPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icons[category] ?? Icons.inventory_2_rounded, size: 13, color: color),
        const SizedBox(width: 5),
        Text(category[0].toUpperCase() + category.substring(1),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  const _PriorityChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  );
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
