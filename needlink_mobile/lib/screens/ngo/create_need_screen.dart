import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers.dart';
import '../../theme.dart';

class CreateNeedScreen extends ConsumerStatefulWidget {
  final String? templateId;
  const CreateNeedScreen({super.key, this.templateId});
  @override
  ConsumerState<CreateNeedScreen> createState() => _CreateNeedScreenState();
}

class _CreateNeedScreenState extends ConsumerState<CreateNeedScreen> {
  int _step = 0;

  final _itemCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'food';
  String _urgency = 'normal';

  int _quantity = 1;
  DateTime? _deadline;

  bool _loading = false;
  bool _published = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.templateId != null) _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final data = await Supabase.instance.client
          .from('donation_needs').select().eq('id', widget.templateId!).single();
      if (!mounted) return;
      setState(() {
        _itemCtrl.text = data['item_name'] as String? ?? '';
        _descCtrl.text = data['description'] as String? ?? '';
        _category = data['category'] as String? ?? 'food';
        _urgency = data['urgency'] as String? ?? 'normal';
        _quantity = (data['quantity_needed'] as int?) ?? 1;
      });
    } catch (_) {}
  }

  @override
  void dispose() { _itemCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  bool get _step1Valid => _itemCtrl.text.trim().isNotEmpty;
  bool get _step2Valid => _deadline != null;

  static const _catColors = {
    'food': Color(0xFFEA580C), 'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFF16A34A), 'supplies': Color(0xFF0891B2),
  };
  static const _catIcons = {
    'food': HugeIcons.strokeRoundedRestaurant01, 'clothing': HugeIcons.strokeRoundedTShirt,
    'medicine': HugeIcons.strokeRoundedMedicine01, 'supplies': HugeIcons.strokeRoundedSchool,
  };
  static const _catLabels = {
    'food': 'Food', 'clothing': 'Clothing', 'medicine': 'Medicine', 'supplies': 'Supplies',
  };

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
      // Bust both caches so the new need appears immediately on return.
      ref.invalidate(myNgoNeedsProvider);
      ref.invalidate(donationNeedsProvider);
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
        title: Text('Post a Need', style: GoogleFonts.sora(fontWeight: FontWeight.w800, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(HugeIcons.strokeRoundedCancel01),
          onPressed: () => context.canPop() ? context.pop() : context.go('/ngo'),
        ),
      ),
      body: Column(children: [
        // ── Numbered step indicator ──────────────────────────────────────────
        Container(
          color: kSurface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(children: List.generate(3, (i) {
            final done = i < _step;
            final active = i == _step;
            final color = done ? kMatched : active ? kPrimary : kMuted;
            final labels = ['Basic Info', 'Logistics', 'Review'];
            return Expanded(child: Row(children: [
              Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: done ? kMatched : active ? kPrimary : kSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: done || active ? 0 : 1.5),
                  ),
                  child: Center(child: done
                    ? const Icon(HugeIcons.strokeRoundedTick01, size: 14, color: Colors.white)
                    : Text('${i + 1}', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: active ? Colors.white : kMutedFg,
                      )),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i], style: TextStyle(
                  fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                  color: active ? kForeground : kMutedFg,
                )),
              ]),
              if (i < 2) ...[
                const SizedBox(width: 6),
                Expanded(child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 2,
                  decoration: BoxDecoration(
                    color: i < _step ? kMatched : kMuted,
                    borderRadius: BorderRadius.circular(1),
                  ),
                )),
                const SizedBox(width: 6),
              ],
            ]));
          })),
        ),

        if (_error != null)
          Container(
            color: const Color(0xFFFEF2F2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Icon(HugeIcons.strokeRoundedAlertCircle, size: 14, color: Color(0xFFDC2626)),
              const SizedBox(width: 6),
              Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
            ]),
          ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: [_buildStep1, _buildStep2, _buildReview][_step](),
        )),

        // ── Navigation buttons ───────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: kSurface, border: const Border(top: BorderSide(color: kBorder)),
          ),
          child: Row(children: [
            if (_step > 0) ...[
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() { _step--; _error = null; }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: kBorder),
                  foregroundColor: kForeground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
            ],
            Expanded(flex: _step > 0 ? 2 : 1, child: ElevatedButton(
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
                backgroundColor: kPrimary, minimumSize: const Size(double.infinity, 50),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _step < 2 ? 'Continue' : 'Publish Need',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStep1() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('What do you need?', style: GoogleFonts.sora(
      fontSize: 18, fontWeight: FontWeight.w800, color: kForeground,
    )),
    const SizedBox(height: 4),
    Text('Describe the item your organization is requesting.',
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg)),
    const SizedBox(height: 20),

    TextField(
      controller: _itemCtrl,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: const InputDecoration(labelText: 'Item name *', hintText: 'e.g. School exercise books'),
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 20),

    Text('CATEGORY', style: GoogleFonts.sora(
      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
    )),
    const SizedBox(height: 10),
    Row(children: ['food', 'clothing', 'medicine', 'supplies'].map((c) {
      final selected = _category == c;
      final color = _catColors[c] ?? kPrimary;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _category = c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(18) : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : kBorder, width: selected ? 1.5 : 1),
          ),
          child: Column(children: [
            Icon(_catIcons[c] ?? HugeIcons.strokeRoundedPackage, size: 20, color: selected ? color : kMutedFg),
            const SizedBox(height: 4),
            Text(_catLabels[c] ?? c, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: selected ? color : kMutedFg,
            )),
          ]),
        ),
      ));
    }).toList()),
    const SizedBox(height: 20),

    Text('PRIORITY', style: GoogleFonts.sora(
      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
    )),
    const SizedBox(height: 10),
    Row(children: [
      _UrgencyChip('Normal', HugeIcons.strokeRoundedCircle, _urgency == 'normal', kPrimary,
        () => setState(() => _urgency = 'normal')),
      const SizedBox(width: 10),
      _UrgencyChip('Urgent', HugeIcons.strokeRoundedFlash, _urgency == 'urgent', kUrgent,
        () => setState(() => _urgency = 'urgent')),
    ]),
    const SizedBox(height: 20),

    TextField(
      controller: _descCtrl,
      maxLines: 4,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
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
    Text('Items & Logistics', style: GoogleFonts.sora(
      fontSize: 18, fontWeight: FontWeight.w800, color: kForeground,
    )),
    const SizedBox(height: 4),
    Text('Set the quantity needed and your collection deadline.',
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg)),
    const SizedBox(height: 20),

    Text('QUANTITY NEEDED', style: GoogleFonts.sora(
      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
    )),
    const SizedBox(height: 10),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Units', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground)),
        Row(children: [
          GestureDetector(
            onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _quantity > 1 ? kPrimary.withAlpha(20) : kMuted,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(HugeIcons.strokeRoundedMinusSign, size: 18, color: _quantity > 1 ? kPrimary : kMutedFg),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('$_quantity', style: GoogleFonts.sora(
              fontSize: 22, fontWeight: FontWeight.w900, color: kForeground,
            )),
          ),
          GestureDetector(
            onTap: () => setState(() => _quantity++),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(9)),
              child: const Icon(HugeIcons.strokeRoundedAdd01, size: 18, color: kPrimary),
            ),
          ),
        ]),
      ]),
    ),
    const SizedBox(height: 20),

    Text('COLLECTION DEADLINE', style: GoogleFonts.sora(
      fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
    )),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _deadline != null ? kPrimary.withAlpha(10) : kBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _deadline != null ? kPrimary : kBorder),
        ),
        child: Row(children: [
          Icon(HugeIcons.strokeRoundedCalendar01, size: 18, color: _deadline != null ? kPrimary : kMutedFg),
          const SizedBox(width: 10),
          Text(
            _deadline != null ? DateFormat('MMMM d, yyyy').format(_deadline!) : 'Select a deadline',
            style: TextStyle(
              color: _deadline != null ? kForeground : kMutedFg,
              fontWeight: _deadline != null ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ]),
      ),
    ),
    const SizedBox(height: 20),
  ]);

  Widget _buildReview() {
    final catColor = _catColors[_category] ?? kPrimary;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Review & Publish', style: GoogleFonts.sora(
        fontSize: 18, fontWeight: FontWeight.w800, color: kForeground,
      )),
      const SizedBox(height: 4),
      Text('Check the details before publishing this need.',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg)),
      const SizedBox(height: 20),

      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
            BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: catColor.withAlpha(20), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_catIcons[_category] ?? HugeIcons.strokeRoundedPackage, size: 12, color: catColor),
                const SizedBox(width: 4),
                Text(
                  (_catLabels[_category] ?? _category),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: catColor),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            if (_urgency == 'urgent')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kUrgent.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                child: const Text('URGENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kUrgent)),
              ),
          ]),
          const SizedBox(height: 12),
          Text(_itemCtrl.text.trim(), style: GoogleFonts.sora(
            fontSize: 18, fontWeight: FontWeight.w800, color: kForeground,
          )),
          if (_descCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_descCtrl.text.trim(), style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: kMutedFg, height: 1.55,
            )),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: kBorder),
          const SizedBox(height: 14),
          _ReviewRow(HugeIcons.strokeRoundedPackage, 'Quantity', '$_quantity units'),
          const SizedBox(height: 8),
          _ReviewRow(HugeIcons.strokeRoundedCalendar01, 'Deadline',
            _deadline != null ? DateFormat('MMMM d, yyyy').format(_deadline!) : '-'),
          const SizedBox(height: 8),
          _ReviewRow(HugeIcons.strokeRoundedGrid, 'Category', _catLabels[_category] ?? _category),
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
          Icon(HugeIcons.strokeRoundedInformationCircle, size: 16, color: kPrimary),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Once published, donors on NeedLink will see and pledge to this need.',
            style: TextStyle(fontSize: 12, color: kPrimary),
          )),
        ]),
      ),
      const SizedBox(height: 20),
    ]);
  }
}

// ── Published success ─────────────────────────────────────────────────────────

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
            child: const Icon(HugeIcons.strokeRoundedCheckmarkCircle01, size: 44, color: kMatched),
          ),
          const SizedBox(height: 20),
          Text('Need Published!', style: GoogleFonts.sora(
            fontSize: 22, fontWeight: FontWeight.w900, color: kForeground,
          )),
          const SizedBox(height: 8),
          Text(
            'Your need is now live and visible to donors on NeedLink.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: kMutedFg, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Back to Dashboard', style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 15,
              )),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ── Urgency chip ──────────────────────────────────────────────────────────────

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
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: selected ? color : kMutedFg,
          )),
        ]),
      ),
    ),
  );
}

// ── Review row ────────────────────────────────────────────────────────────────

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ReviewRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: kMutedFg),
    const SizedBox(width: 8),
    Text('$label: ', style: const TextStyle(fontSize: 13, color: kMutedFg)),
    Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground)),
  ]);
}
