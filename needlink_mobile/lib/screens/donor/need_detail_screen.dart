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
  void initState() {
    super.initState();
    _load();
  }

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

    return Scaffold(
      appBar: AppBar(title: Text(need.itemName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Need info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _Chip(need.status.toUpperCase(), need.status == 'matched' ? kMatched : kPrimary),
                const SizedBox(width: 8),
                if (need.isUrgent) _Chip('⚡ URGENT', kUrgent),
              ]),
              const SizedBox(height: 12),
              Text(need.itemName, style: const TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 20, color: kForeground)),
              if (need.ngo != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: kMutedFg),
                  const SizedBox(width: 4),
                  Text('${need.ngo!.name} · ${need.ngo!.location}', style: const TextStyle(fontSize: 13, color: kMutedFg)),
                ]),
              ],
              if (need.description != null) ...[
                const SizedBox(height: 10),
                Text(need.description!, style: const TextStyle(fontSize: 14, color: kForeground, height: 1.5)),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _StatBox('Needed', need.quantityNeeded.toString())),
                const SizedBox(width: 12),
                Expanded(child: _StatBox('Still needed', remaining.toString(), accent: true)),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${need.quantityPledged} pledged', style: const TextStyle(fontSize: 12, color: kMutedFg)),
                Text('${(need.progress * 100).round()}%', style: const TextStyle(fontSize: 12, fontFamily: 'FiraCode', color: kMutedFg)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: need.progress,
                  backgroundColor: kMuted,
                  valueColor: AlwaysStoppedAnimation(need.progress >= 1 ? kMatched : kPrimary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: kMutedFg),
                const SizedBox(width: 6),
                Text('Deadline: ${need.deadline}', style: const TextStyle(fontSize: 13, color: kMutedFg)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          if (_success)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: kMatched, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pledge submitted!', style: TextStyle(fontWeight: FontWeight.bold, color: kMatched)),
                  const SizedBox(height: 2),
                  const Text('The NGO will review your pledge soon.', style: TextStyle(fontSize: 13, color: kMutedFg)),
                  TextButton(onPressed: () => context.go('/donor/pledges'), child: const Text('View my pledges →')),
                ])),
              ]),
            )
          else if (need.status != 'closed') ...[
            const Text('Make a Pledge', style: TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 18, color: kForeground)),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
              ),
            Text('Quantity (max $remaining) *', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kForeground)),
            const SizedBox(height: 8),
            Row(children: [
              IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline), color: kPrimary),
              Expanded(child: Center(child: Text('$_quantity', style: const TextStyle(fontFamily: 'FiraCode', fontSize: 20, fontWeight: FontWeight.bold, color: kForeground)))),
              IconButton(onPressed: _quantity < remaining ? () => setState(() => _quantity++) : null,
                icon: const Icon(Icons.add_circle_outline), color: kPrimary),
            ]),
            const SizedBox(height: 16),
            Text('Expected delivery date *', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kForeground)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context, initialDate: DateTime.now().add(const Duration(days: 3)),
                  firstDate: DateTime.now(), lastDate: DateTime.parse(need.deadline),
                  builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)), child: child!),
                );
                if (d != null) setState(() => _deliveryDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: _deliveryDate != null ? kPrimary : kBorder)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: kMutedFg),
                  const SizedBox(width: 10),
                  Text(_deliveryDate != null ? DateFormat('MMM d, yyyy').format(_deliveryDate!) : 'Select date',
                    style: TextStyle(color: _deliveryDate != null ? kForeground : kMutedFg)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)', hintText: 'Any special info for the NGO…'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_pledging || _deliveryDate == null || remaining == 0) ? null : _submitPledge,
              style: ElevatedButton.styleFrom(backgroundColor: kAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _pledging
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Pledge', style: TextStyle(fontSize: 16)),
            ),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'FiraCode')),
  );
}

class _StatBox extends StatelessWidget {
  final String label, value; final bool accent;
  const _StatBox(this.label, this.value, {this.accent = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: kMutedFg)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 22,
        color: accent ? kAccent : kForeground)),
    ]),
  );
}
