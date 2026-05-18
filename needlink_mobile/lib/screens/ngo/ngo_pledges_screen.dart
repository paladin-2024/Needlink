import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import '../../services/storage_service.dart';

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

  // Bulk selection
  bool _bulkMode = false;
  final Set<String> _selected = {};

  void _toggleBulk() {
    HapticFeedback.selectionClick();
    setState(() { _bulkMode = !_bulkMode; _selected.clear(); });
  }

  Future<void> _bulkAct(String action) async {
    if (_selected.isEmpty) return;
    final ids = _selected.toList();
    setState(() { _acting = 'bulk'; });
    try {
      final client = ref.read(supabaseProvider);
      for (final id in ids) {
        await client.from('pledges').update({'status': action}).eq('id', id);
      }
      ref.invalidate(myNgoPendingPledgesProvider);
      ref.invalidate(myNgoNeedsProvider);
      ref.invalidate(donationNeedsProvider);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk action failed: $e'), backgroundColor: kUrgent),
        );
      }
    } finally {
      if (mounted) setState(() { _acting = null; _bulkMode = false; _selected.clear(); });
    }
  }

  static const _shadow = [
    BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

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
          .select('*, donation_need:donation_needs!inner(*, ngo_id), donor:profiles!donor_id(id, full_name, phone, avatar_url)')
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
      ref.invalidate(myNgoPendingPledgesProvider);
      ref.invalidate(myNgoNeedsProvider);
      ref.invalidate(donationNeedsProvider);
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
    final confirmed = _pledges.where((p) => p['status'] == 'confirmed').length;
    final filtered = _filter == 'All'
        ? _pledges
        : _pledges.where((p) => p['status'].toString().toLowerCase() == _filter.toLowerCase()).toList();

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: kSurface,
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text('Pledges', style: GoogleFonts.sora(
                            fontSize: 22, fontWeight: FontWeight.w800, color: kForeground,
                          ))),
                          if (pending > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: kUrgent, borderRadius: BorderRadius.circular(20)),
                              child: Text('$pending pending', style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                              )),
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(_bulkMode ? HugeIcons.strokeRoundedCancel01 : HugeIcons.strokeRoundedCheckList,
                              color: _bulkMode ? kUrgent : kMutedFg, size: 20),
                            onPressed: _toggleBulk,
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            tooltip: _bulkMode ? 'Cancel' : 'Select',
                          ),
                          IconButton(
                            icon: const Icon(HugeIcons.strokeRoundedRefresh, color: kMutedFg, size: 20),
                            onPressed: _load, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          ),
                        ]),
                        if (_bulkMode && _selected.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Text('${_selected.length} selected', style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: kMutedFg,
                            )),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: _acting != null ? null : () => _bulkAct('rejected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Reject All'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _acting != null ? null : () => _bulkAct('confirmed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary, elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: _acting == 'bulk'
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Confirm All', style: TextStyle(color: Colors.white)),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 14),

                        // Summary tiles
                        Row(children: [
                          _SummaryTile('${_pledges.length}', 'Total', kPrimary),
                          const SizedBox(width: 8),
                          _SummaryTile('$pending', 'Pending', const Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          _SummaryTile('$confirmed', 'Confirmed', kMatched),
                        ]),
                        const SizedBox(height: 14),

                        // Filter chips
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _filters.map((f) {
                              final active = _filter == f;
                              return GestureDetector(
                                onTap: () => setState(() => _filter = f),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: active ? kPrimary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: active ? kPrimary : kBorder),
                                  ),
                                  child: Text(f, style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: active ? Colors.white : kMutedFg,
                                  )),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(HugeIcons.strokeRoundedInbox, size: 52, color: kMuted),
                          const SizedBox(height: 14),
                          Text(
                            _filter == 'All' ? 'No pledges yet' : 'No $_filter pledges',
                            style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: kForeground),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pledges from donors will appear here',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
                          ),
                        ]),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _PledgeCard(
                            pledge: filtered[i], acting: _acting, onAct: _act, shadow: _shadow,
                            bulkMode: _bulkMode,
                            selected: _selected.contains(filtered[i]['id'] as String? ?? ''),
                            onToggleSelect: (id) => setState(() {
                              if (_selected.contains(id)) { _selected.remove(id); } else { _selected.add(id); }
                            }),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ── Summary tile ──────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String value, label;
  final Color color;
  const _SummaryTile(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFF), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kMutedFg)),
      ]),
    ),
  );
}

// ── Pledge card ───────────────────────────────────────────────────────────────

class _PledgeCard extends StatefulWidget {
  final Map<String, dynamic> pledge;
  final String? acting;
  final Future<void> Function(Map<String, dynamic>, String) onAct;
  final List<BoxShadow> shadow;
  final bool bulkMode;
  final bool selected;
  final void Function(String) onToggleSelect;
  const _PledgeCard({
    required this.pledge, required this.acting, required this.onAct, required this.shadow,
    required this.bulkMode, required this.selected, required this.onToggleSelect,
  });
  @override
  State<_PledgeCard> createState() => _PledgeCardState();
}

class _PledgeCardState extends State<_PledgeCard> {
  bool _uploadingProof = false;

  static const _statusConfig = {
    'pending':   (Color(0xFFFFFBEB), Color(0xFFD97706), 'Pending'),
    'confirmed': (Color(0xFFF0FDF4), Color(0xFF15803D), 'Confirmed'),
    'rejected':  (Color(0xFFFEF2F2), Color(0xFFDC2626), 'Rejected'),
  };

  @override
  Widget build(BuildContext context) {
    final pledge = widget.pledge;
    final status = pledge['status'] as String;
    final cfg = _statusConfig[status] ?? (kMuted, kMutedFg, status);
    final donor = pledge['donor'] as Map<String, dynamic>?;
    final need = pledge['donation_need'] as Map<String, dynamic>?;
    final isPending = status == 'pending';
    final isConfirmed = status == 'confirmed';
    final isBusy = widget.acting == pledge['id'];
    final proofUrl = pledge['delivery_proof_url'] as String?;

    return GestureDetector(
      onTap: widget.bulkMode ? () => widget.onToggleSelect(pledge['id'] as String? ?? '') : null,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.selected ? kPrimary.withAlpha(8) : kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.selected ? kPrimary : isPending ? const Color(0xFFFDE68A) : kBorder),
        boxShadow: widget.shadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (widget.bulkMode)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: widget.selected ? kPrimary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.selected ? kPrimary : kBorder, width: 2),
                ),
                child: widget.selected ? const Icon(HugeIcons.strokeRoundedTick01, size: 14, color: Colors.white) : null,
              ),
            ),
          UserAvatar(
            seed: donor?['id'] as String? ?? 'donor',
            initials: (donor?['full_name'] as String? ?? 'D')[0].toUpperCase(),
            avatarUrl: donor?['avatar_url'] as String?,
            radius: 19,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(donor?['full_name'] ?? 'Donor', style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 14, color: kForeground,
            )),
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
        const Divider(height: 1, color: kBorder),
        const SizedBox(height: 10),
        Text(
          need?['item_name'] ?? 'Unknown item',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimary),
        ),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(HugeIcons.strokeRoundedPackage, size: 13, color: kMutedFg),
          const SizedBox(width: 4),
          Text('${pledge['quantity']} units', style: const TextStyle(fontSize: 12, color: kMutedFg)),
          const SizedBox(width: 12),
          const Icon(HugeIcons.strokeRoundedCalendar01, size: 13, color: kMutedFg),
          const SizedBox(width: 4),
          Text('By ${pledge['delivery_date']}', style: const TextStyle(fontSize: 12, color: kMutedFg)),
        ]),
        if (pledge['notes'] != null && (pledge['notes'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(HugeIcons.strokeRoundedNote01, size: 13, color: kMutedFg),
              const SizedBox(width: 6),
              Expanded(child: Text(pledge['notes'] as String, style: const TextStyle(fontSize: 12, color: kMutedFg))),
            ]),
          ),
        ],
        if (isPending && !widget.bulkMode) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: isBusy ? null : () => widget.onAct(pledge, 'rejected'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFECACA)),
                minimumSize: const Size(0, 42),
              ),
              icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 16),
              label: const Text('Reject'),
            )),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ElevatedButton.icon(
              onPressed: isBusy ? null : () { HapticFeedback.mediumImpact(); widget.onAct(pledge, 'confirmed'); },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, minimumSize: const Size(0, 42), elevation: 0,
              ),
              icon: isBusy
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(HugeIcons.strokeRoundedTick01, size: 16, color: Colors.white),
              label: const Text('Confirm Pledge', style: TextStyle(color: Colors.white)),
            )),
          ]),
        ],
        // Delivery proof upload for confirmed pledges
        if (isConfirmed && !widget.bulkMode) ...[
          const SizedBox(height: 10),
          proofUrl != null
              ? Row(children: [
                  const Icon(HugeIcons.strokeRoundedImage01, size: 14, color: kMatched),
                  const SizedBox(width: 6),
                  Text('Proof uploaded', style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: kMatched, fontWeight: FontWeight.w600,
                  )),
                ])
              : OutlinedButton.icon(
                  onPressed: _uploadingProof ? null : () async {
                    setState(() => _uploadingProof = true);
                    try {
                      final url = await StorageService.uploadDeliveryProof(pledge['id'] as String);
                      if (url != null) {
                        await Supabase.instance.client
                            .from('pledges')
                            .update({'delivery_proof_url': url})
                            .eq('id', pledge['id']);
                        if (mounted) setState(() { pledge['delivery_proof_url'] = url; });
                      }
                    } catch (_) {} finally {
                      if (mounted) setState(() => _uploadingProof = false);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary, side: const BorderSide(color: kBorder),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: _uploadingProof
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                      : const Icon(HugeIcons.strokeRoundedUpload01, size: 15),
                  label: Text('Upload Delivery Proof', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                ),
        ],
      ]),
    ));
  }
}
