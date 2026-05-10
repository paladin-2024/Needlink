import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';

class NgoPledgesScreen extends StatefulWidget {
  const NgoPledgesScreen({super.key});
  @override
  State<NgoPledgesScreen> createState() => _NgoPledgesScreenState();
}

class _NgoPledgesScreenState extends State<NgoPledgesScreen> {
  List<Map<String, dynamic>> _pledges = [];
  bool _loading = true;
  String? _ngoId;
  String? _acting;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final ngoData = await Supabase.instance.client.from('ngos').select('id').eq('admin_id', user.id).maybeSingle();
    if (ngoData == null) { setState(() => _loading = false); return; }
    _ngoId = ngoData['id'];

    final data = await Supabase.instance.client
        .from('pledges')
        .select('*, donation_need:donation_needs!inner(*, ngo_id), donor:profiles!donor_id(full_name, phone)')
        .eq('donation_need.ngo_id', _ngoId!)
        .order('created_at', ascending: false);

    setState(() { _pledges = List<Map<String, dynamic>>.from(data); _loading = false; });
  }

  Future<void> _act(Map<String, dynamic> pledge, String action) async {
    setState(() => _acting = pledge['id']);
    final user = Supabase.instance.client.auth.currentUser!;

    await Supabase.instance.client.from('pledges').update({'status': action}).eq('id', pledge['id']);

    if (action == 'confirmed') {
      await Supabase.instance.client.from('deliveries').insert({'pledge_id': pledge['id'], 'confirmed_by': user.id});
    } else if (action == 'rejected') {
      final need = await Supabase.instance.client.from('donation_needs').select('quantity_pledged, status').eq('id', pledge['need_id']).single();
      final newPledged = ((need['quantity_pledged'] as int) - (pledge['quantity'] as int)).clamp(0, 99999);
      final newStatus = need['status'] == 'matched' ? 'open' : need['status'];
      await Supabase.instance.client.from('donation_needs').update({'quantity_pledged': newPledged, 'status': newStatus}).eq('id', pledge['need_id']);
    }

    await _load();
    setState(() => _acting = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)));

    final pending = _pledges.where((p) => p['status'] == 'pending').toList();
    final others = _pledges.where((p) => p['status'] != 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pledges${pending.isNotEmpty ? ' (${pending.length} pending)' : ''}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/ngo')),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _pledges.isEmpty
          ? const Center(child: Text('No pledges yet', style: TextStyle(color: kMutedFg, fontFamily: 'FiraCode')))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('⚡ Needs Action', style: TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 13, color: kAccent)),
                  ),
                  ...pending.map((p) => _PledgeCard(pledge: p, acting: _acting, onAct: _act)),
                  const SizedBox(height: 16),
                ],
                if (others.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('History', style: TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.bold, fontSize: 13, color: kMutedFg)),
                  ),
                  ...others.map((p) => _PledgeCard(pledge: p, acting: _acting, onAct: _act)),
                ],
              ],
            ),
    );
  }
}

class _PledgeCard extends StatelessWidget {
  final Map<String, dynamic> pledge;
  final String? acting;
  final Future<void> Function(Map<String, dynamic>, String) onAct;

  const _PledgeCard({required this.pledge, required this.acting, required this.onAct});

  static const _statusColors = {
    'pending': (Color(0xFFFFFBEB), Color(0xFFD97706)),
    'matched': (Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
    'in_transit': (Color(0xFFF5F3FF), Color(0xFF7C3AED)),
    'confirmed': (Color(0xFFF0FDF4), Color(0xFF15803D)),
    'rejected': (Color(0xFFFEF2F2), Color(0xFFDC2626)),
  };

  @override
  Widget build(BuildContext context) {
    final status = pledge['status'] as String;
    final colors = _statusColors[status] ?? (kMuted, kMutedFg);
    final donor = pledge['donor'] as Map<String, dynamic>?;
    final need = pledge['donation_need'] as Map<String, dynamic>?;
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPending ? const Color(0xFFFDE68A) : kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(donor?['full_name'] ?? 'Donor', style: const TextStyle(fontFamily: 'FiraCode', fontWeight: FontWeight.w600, color: kForeground)),
            if (donor?['phone'] != null)
              Text(donor!['phone'], style: const TextStyle(fontSize: 12, color: kMutedFg)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(20)),
            child: Text(status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'FiraCode', color: colors.$2)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('${need?['item_name'] ?? 'Unknown'} — ${pledge['quantity']} units',
          style: const TextStyle(fontSize: 13, color: kForeground)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 12, color: kMutedFg),
          const SizedBox(width: 4),
          Text('Delivery: ${pledge['delivery_date']}', style: const TextStyle(fontSize: 12, color: kMutedFg)),
        ]),
        if (pledge['notes'] != null && (pledge['notes'] as String).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('"${pledge['notes']}"', style: const TextStyle(fontSize: 12, color: kMutedFg, fontStyle: FontStyle.italic)),
        ],
        if (isPending) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: acting == pledge['id'] ? null : () => onAct(pledge, 'rejected'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), side: const BorderSide(color: Color(0xFFFECACA))),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              onPressed: acting == pledge['id'] ? null : () => onAct(pledge, 'confirmed'),
              style: ElevatedButton.styleFrom(backgroundColor: kMatched),
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: const Text('Confirm', style: TextStyle(color: Colors.white)),
            )),
          ]),
        ],
      ]),
    );
  }
}
