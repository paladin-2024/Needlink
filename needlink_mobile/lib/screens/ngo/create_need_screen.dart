import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';

class CreateNeedScreen extends StatefulWidget {
  const CreateNeedScreen({super.key});
  @override
  State<CreateNeedScreen> createState() => _CreateNeedScreenState();
}

class _CreateNeedScreenState extends State<CreateNeedScreen> {
  final _itemCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'food';
  String _urgency = 'normal';
  int _quantity = 1;
  DateTime? _deadline;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_deadline == null) { setState(() => _error = 'Please select a deadline'); return; }
    if (_itemCtrl.text.isEmpty) { setState(() => _error = 'Item name is required'); return; }
    setState(() { _loading = true; _error = null; });

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final ngoData = await Supabase.instance.client.from('ngos').select('id').eq('admin_id', user.id).single();

      await Supabase.instance.client.from('donation_needs').insert({
        'ngo_id': ngoData['id'], 'item_name': _itemCtrl.text.trim(),
        'category': _category, 'quantity_needed': _quantity,
        'urgency': _urgency, 'deadline': '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}',
        'description': _descCtrl.text.isNotEmpty ? _descCtrl.text.trim() : null,
      });

      if (mounted) context.go('/ngo');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() { _itemCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Need')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
            ),

          TextField(controller: _itemCtrl, decoration: const InputDecoration(labelText: 'Item name *', hintText: 'e.g. School exercise books')),
          const SizedBox(height: 16),

          const Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kForeground)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ...['food', 'clothing', 'medicine', 'supplies'].map((c) => _CatChip(
              label: '${_emoji(c)} ${c[0].toUpperCase()}${c.substring(1)}',
              selected: _category == c,
              onTap: () => setState(() => _category = c),
            )),
          ]),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quantity *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kForeground)),
              const SizedBox(height: 8),
              Row(children: [
                IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove_circle_outline), color: kPrimary),
                Text('$_quantity', style: const TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 20, color: kForeground)),
                IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add_circle_outline), color: kPrimary),
              ]),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Urgency *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kForeground)),
              const SizedBox(height: 8),
              Row(children: [
                _CatChip(label: 'Normal', selected: _urgency == 'normal', onTap: () => setState(() => _urgency = 'normal')),
                const SizedBox(width: 8),
                _CatChip(label: '⚡ Urgent', selected: _urgency == 'urgent', onTap: () => setState(() => _urgency = 'urgent'), urgent: true),
              ]),
            ])),
          ]),
          const SizedBox(height: 16),

          const Text('Deadline *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kForeground)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context, initialDate: DateTime.now().add(const Duration(days: 14)),
                firstDate: DateTime.now().add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)), child: child!),
              );
              if (d != null) setState(() => _deadline = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: _deadline != null ? kPrimary : kBorder)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: kMutedFg),
                const SizedBox(width: 10),
                Text(_deadline != null ? '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}' : 'Select deadline',
                  style: TextStyle(color: _deadline != null ? kForeground : kMutedFg)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)', hintText: 'More context about this need…')),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: kAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Post Need', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  String _emoji(String c) => const {'food': '🌾', 'clothing': '👕', 'medicine': '💊', 'supplies': '📦'}[c] ?? '📦';
}

class _CatChip extends StatelessWidget {
  final String label; final bool selected; final bool urgent; final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected, required this.onTap, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? (urgent ? kUrgent : kForeground) : kSurface;
    final fg = selected ? Colors.white : kMutedFg;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? bg : kBorder)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}
