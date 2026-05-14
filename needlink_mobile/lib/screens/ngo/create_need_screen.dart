import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';

class CreateNeedScreen extends StatefulWidget {
  const CreateNeedScreen({super.key});
  @override
  State<CreateNeedScreen> createState() => _CreateNeedScreenState();
}

class _CreateNeedScreenState extends State<CreateNeedScreen> {
  int _step = 0; // 0 = Basic Info, 1 = Items & Logistics, 2 = Review

  // Step 1
  final _itemCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'food';
  String _urgency = 'normal';

  // Step 2
  int _quantity = 1;
  DateTime? _deadline;

  bool _loading = false;
  bool _published = false;
  String? _error;

  @override
  void dispose() { _itemCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  bool get _step1Valid => _itemCtrl.text.trim().isNotEmpty;
  bool get _step2Valid => _deadline != null;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final ngoData = await Supabase.instance.client.from('ngos').select('id').eq('admin_id', user.id).single();
      await Supabase.instance.client.from('donation_needs').insert({
        'ngo_id': ngoData['id'],
        'item_name': _itemCtrl.text.trim(),
        'category': _category,
        'quantity_needed': _quantity,
        'urgency': _urgency,
        'deadline': DateFormat('yyyy-MM-dd').format(_deadline!),
        'description': _descCtrl.text.isNotEmpty ? _descCtrl.text.trim() : null,
      });
      setState(() { _published = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_published) return _PublishedScreen(onDone: () => context.go('/ngo'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Need'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/ngo'),
        ),
      ),
      body: Column(children: [
        // Step indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: List.generate(3, (i) {
            final done = i < _step;
            final active = i == _step;
            return Expanded(child: Row(children: [
              Expanded(child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: done || active ? kPrimary : kMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              if (i < 2) const SizedBox(width: 4),
            ]));
          })),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              'Step ${_step + 1} of 3  ·  ${['Basic Info', 'Items & Logistics', 'Review'][_step]}',
              style: const TextStyle(fontSize: 12, color: kMutedFg),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
          ]),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: [_buildStep1, _buildStep2, _buildReview][_step](),
        )),

        // Bottom nav buttons
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: kSurface, border: Border(top: BorderSide(color: kBorder)),
          ),
          child: Row(children: [
            if (_step > 0)
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: kBorder),
                  foregroundColor: kForeground,
                ),
                child: const Text('Back'),
              )),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _loading ? null : () {
                if (_step == 0) {
                  if (!_step1Valid) { setState(() => _error = 'Item name is required'); return; }
                  setState(() { _step = 1; _error = null; });
                } else if (_step == 1) {
                  if (!_step2Valid) { setState(() => _error = 'Please select a deadline'); return; }
                  setState(() { _step = 2; _error = null; });
                } else {
                  _submit();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_step < 2 ? 'Continue' : 'Publish Need', style: const TextStyle(fontWeight: FontWeight.w600)),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStep1() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('What do you need?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kForeground)),
    const SizedBox(height: 4),
    const Text('Describe the item your organization is requesting.',
      style: TextStyle(fontSize: 13, color: kMutedFg)),
    const SizedBox(height: 20),

    TextField(
      controller: _itemCtrl,
      decoration: const InputDecoration(labelText: 'Item name *', hintText: 'e.g. School exercise books'),
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 16),

    const Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground)),
    const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: [
      ...['food', 'clothing', 'medicine', 'supplies'].map((c) {
        const icons = {
          'food': Icons.restaurant_rounded,
          'clothing': Icons.checkroom_rounded,
          'medicine': Icons.medication_rounded,
          'supplies': Icons.school_rounded,
        };
        const labels = {'food': 'Food', 'clothing': 'Clothing', 'medicine': 'Medicine', 'supplies': 'Supplies'};
        final selected = _category == c;
        return GestureDetector(
          onTap: () => setState(() => _category = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? kPrimary.withAlpha(20) : kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? kPrimary : kBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icons[c] ?? Icons.inventory_2_rounded, size: 16, color: selected ? kPrimary : kMutedFg),
              const SizedBox(width: 6),
              Text(labels[c] ?? c, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? kPrimary : kMutedFg,
              )),
            ]),
          ),
        );
      }),
    ]),
    const SizedBox(height: 16),

    const Text('Priority *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground)),
    const SizedBox(height: 10),
    Row(children: [
      _UrgencyChip('Normal', Icons.radio_button_unchecked_rounded, _urgency == 'normal', kPrimary,
        () => setState(() => _urgency = 'normal')),
      const SizedBox(width: 10),
      _UrgencyChip('Urgent', Icons.bolt_rounded, _urgency == 'urgent', kUrgent,
        () => setState(() => _urgency = 'urgent')),
    ]),
    const SizedBox(height: 16),

    TextField(
      controller: _descCtrl,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        hintText: 'More context about this need, who it helps, specific requirements…',
        alignLabelWithHint: true,
      ),
      textCapitalization: TextCapitalization.sentences,
    ),
    const SizedBox(height: 20),
  ]);

  Widget _buildStep2() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Items & Logistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kForeground)),
    const SizedBox(height: 4),
    const Text('Set the quantity needed and your collection deadline.',
      style: TextStyle(fontSize: 13, color: kMutedFg)),
    const SizedBox(height: 20),

    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Quantity needed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground)),
          Row(children: [
            GestureDetector(
              onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _quantity > 1 ? kPrimary.withAlpha(20) : kMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.remove_rounded, size: 18, color: _quantity > 1 ? kPrimary : kMutedFg),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$_quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kForeground)),
            ),
            GestureDetector(
              onTap: () => setState(() => _quantity++),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_rounded, size: 18, color: kPrimary),
              ),
            ),
          ]),
        ]),
      ]),
    ),
    const SizedBox(height: 14),

    const Text('Collection deadline *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground)),
    const SizedBox(height: 10),
    GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 14)),
          firstDate: DateTime.now().add(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
            child: child!,
          ),
        );
        if (d != null) setState(() => _deadline = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _deadline != null ? kPrimary.withAlpha(10) : kBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _deadline != null ? kPrimary : kBorder),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: _deadline != null ? kPrimary : kMutedFg),
          const SizedBox(width: 10),
          Text(
            _deadline != null ? DateFormat('MMMM d, yyyy').format(_deadline!) : 'Select a deadline',
            style: TextStyle(color: _deadline != null ? kForeground : kMutedFg, fontWeight: _deadline != null ? FontWeight.w600 : FontWeight.normal),
          ),
        ]),
      ),
    ),
    const SizedBox(height: 20),
  ]);

  Widget _buildReview() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Review & Publish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kForeground)),
    const SizedBox(height: 4),
    const Text('Check the details before publishing this need.',
      style: TextStyle(fontSize: 13, color: kMutedFg)),
    const SizedBox(height: 20),

    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _ReviewChip(_category, kPrimary),
          const SizedBox(width: 8),
          _ReviewChip(_urgency == 'urgent' ? 'URGENT' : 'Normal', _urgency == 'urgent' ? kUrgent : kMutedFg),
        ]),
        const SizedBox(height: 12),
        Text(_itemCtrl.text.trim(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kForeground)),
        if (_descCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_descCtrl.text.trim(), style: const TextStyle(fontSize: 13, color: kMutedFg, height: 1.5)),
        ],
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),
        _ReviewRow(Icons.inventory_2_outlined, 'Quantity', '$_quantity units'),
        const SizedBox(height: 8),
        _ReviewRow(Icons.calendar_today_outlined, 'Deadline', _deadline != null ? DateFormat('MMMM d, yyyy').format(_deadline!) : '-'),
        const SizedBox(height: 8),
        _ReviewRow(Icons.category_outlined, 'Category', _category[0].toUpperCase() + _category.substring(1)),
      ]),
    ),
    const SizedBox(height: 12),

    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withAlpha(10), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withAlpha(40)),
      ),
      child: Row(children: const [
        Icon(Icons.info_outline_rounded, size: 16, color: kPrimary),
        SizedBox(width: 8),
        Expanded(child: Text(
          'Once published, donors on NeedLink will be able to see and pledge to this need.',
          style: TextStyle(fontSize: 12, color: kPrimary),
        )),
      ]),
    ),
    const SizedBox(height: 20),
  ]);
}

class _PublishedScreen extends StatelessWidget {
  final VoidCallback onDone;
  const _PublishedScreen({required this.onDone});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: kMatched.withAlpha(20), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, size: 44, color: kMatched),
          ),
          const SizedBox(height: 20),
          const Text('Need Published!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kForeground)),
          const SizedBox(height: 8),
          const Text(
            'Your need is now live and visible to donors on NeedLink.',
            style: TextStyle(fontSize: 14, color: kMutedFg, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    ),
  );
}

class _UrgencyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _UrgencyChip(this.label, this.icon, this.selected, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : kBorder),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: selected ? color : kMutedFg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? color : kMutedFg)),
        ]),
      ),
    ),
  );
}

class _ReviewChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ReviewChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
    child: Text(label[0].toUpperCase() + label.substring(1),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReviewRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: kMutedFg),
    const SizedBox(width: 8),
    Text('$label: ', style: const TextStyle(fontSize: 13, color: kMutedFg)),
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground)),
  ]);
}
