import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers.dart';
import '../../theme.dart';

class NgoPledgesScreen extends ConsumerStatefulWidget {
  const NgoPledgesScreen({super.key});
  @override
  ConsumerState<NgoPledgesScreen> createState() => _NgoPledgesScreenState();
}

class _NgoPledgesScreenState extends ConsumerState<NgoPledgesScreen> {
  List<Map<String, dynamic>> _pledges = [];
  bool _loading = true;
  String? _ngoId;
  String? _acting;
  String _filter = 'All';
  static const _filters = ['All', 'Pending', 'Confirmed', 'Rejected'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseProvider);
      final userId = client.auth.currentUser!.id;
      final ngoData = await client.from('ngos').select('id').eq('admin_id', userId).maybeSingle();
      if (ngoData == null) { setState(() => _loading = false); return; }
      _ngoId = ngoData['id'];

      final data = await client
          .from('pledges')
          .select('*, donation_need:donation_needs!inner(*, ngo_id), donor:profiles!donor_id(full_name, phone)')
          .eq('donation_need.ngo_id', _ngoId!)
          .order('created_at', ascending: false);

      if (mounted) setState(() { _pledges = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pledges: $e'), backgroundColor: kUrgent),
        );
      }
    }
  }

  Future<void> _act(Map<String, dynamic> pledge, String action) async {
    setState(() => _acting = pledge['id']);
    try {
      final client = ref.read(supabaseProvider);
      final userId = client.auth.currentUser!.id;
      await client.from('pledges').update({'status': action}).eq('id', pledge['id']);

      if (action == 'confirmed') {
        await client.from('deliveries').insert({'pledge_id': pledge['id'], 'confirmed_by': userId});
      } else if (action == 'rejected') {
        final need = await client
            .from('donation_needs').select('quantity_pledged, status').eq('id', pledge['need_id']).single();
        final newPledged = ((need['quantity_pledged'] as int) - (pledge['quantity'] as int)).clamp(0, 99999);
        final newStatus = need['status'] == 'matched' ? 'open' : need['status'];
        await client.from('donation_needs')
            .update({'quantity_pledged': newPledged, 'status': newStatus}).eq('id', pledge['need_id']);
      }

      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: kUrgent),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pledges.where((p) => p['status'] == 'pending').length;

    final filtered = _filter == 'All'
        ? _pledges
        : _pledges.where((p) => p['status'].toString().toLowerCase() == _filter.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pledges${pending > 0 ? ' ($pending pending)' : ''}'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary row
                  Row(children: [
                    _SummaryCard('${_pledges.length}', 'Total', kPrimary),
                    const SizedBox(width: 8),
                    _SummaryCard('$pending', 'Pending', const Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      '${_pledges.where((p) => p['status'] == 'confirmed').length}',
                      'Confirmed', kMatched),
                  ]),
                  const SizedBox(height: 16),

                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _filters.map((f) {
                        final active = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f),
                            selected: active,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor: kPrimary.withAlpha(30),
                            checkmarkColor: kPrimary,
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: active ? kPrimary : kMutedFg,
                              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(color: active ? kPrimary : kBorder),
                            backgroundColor: kSurface,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.inbox_rounded, size: 48, color: kMuted),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'All' ? 'No pledges yet' : 'No $_filter pledges',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kForeground),
                        ),
                        const SizedBox(height: 4),
                        const Text('Pledges from donors will appear here', style: TextStyle(fontSize: 13, color: kMutedFg)),
                      ]),
                    )
                  else
                    ...filtered.map((p) => _PledgeCard(
                      pledge: p, acting: _acting, onAct: _act,
                    )),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SummaryCard(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kMutedFg)),
      ]),
    ),
  );
}

class _PledgeCard extends StatelessWidget {
  final Map<String, dynamic> pledge;
  final String? acting;
  final Future<void> Function(Map<String, dynamic>, String) onAct;
  const _PledgeCard({required this.pledge, required this.acting, required this.onAct});

  static const _statusConfig = {
    'pending': (Color(0xFFFFFBEB), Color(0xFFD97706), 'Pending'),
    'confirmed': (Color(0xFFF0FDF4), Color(0xFF15803D), 'Confirmed'),
    'rejected': (Color(0xFFFEF2F2), Color(0xFFDC2626), 'Rejected'),
  };

  @override
  Widget build(BuildContext context) {
    final status = pledge['status'] as String;
    final cfg = _statusConfig[status] ?? (kMuted, kMutedFg, status);
    final donor = pledge['donor'] as Map<String, dynamic>?;
    final need = pledge['donation_need'] as Map<String, dynamic>?;
    final isPending = status == 'pending';
    final isBusy = acting == pledge['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPending ? const Color(0xFFFDE68A) : kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: kPrimary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_rounded, size: 20, color: kPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(donor?['full_name'] ?? 'Donor',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kForeground)),
            if (donor?['phone'] != null)
              Text(donor!['phone'] as String, style: const TextStyle(fontSize: 12, color: kMutedFg)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: cfg.$1, borderRadius: BorderRadius.circular(20)),
            child: Text(cfg.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg.$2)),
          ),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Text(
          '${need?['item_name'] ?? 'Unknown item'}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground),
        ),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.inventory_2_outlined, size: 13, color: kMutedFg),
          const SizedBox(width: 4),
          Text('${pledge['quantity']} units', style: const TextStyle(fontSize: 12, color: kMutedFg)),
          const SizedBox(width: 12),
          const Icon(Icons.calendar_today_outlined, size: 13, color: kMutedFg),
          const SizedBox(width: 4),
          Text('By ${pledge['delivery_date']}', style: const TextStyle(fontSize: 12, color: kMutedFg)),
        ]),
        if (pledge['notes'] != null && (pledge['notes'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.notes_rounded, size: 13, color: kMutedFg),
              const SizedBox(width: 6),
              Expanded(child: Text(pledge['notes'] as String, style: const TextStyle(fontSize: 12, color: kMutedFg))),
            ]),
          ),
        ],
        if (isPending) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: isBusy ? null : () => onAct(pledge, 'rejected'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFECACA)),
                minimumSize: const Size(0, 40),
              ),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Reject'),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              onPressed: isBusy ? null : () => onAct(pledge, 'confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMatched,
                minimumSize: const Size(0, 40),
              ),
              icon: isBusy
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              label: const Text('Confirm', style: TextStyle(color: Colors.white)),
            )),
          ]),
        ],
      ]),
    );
  }
}
