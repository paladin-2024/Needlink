import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers.dart';
import '../../theme.dart';

class VerificationRequestScreen extends ConsumerStatefulWidget {
  const VerificationRequestScreen({super.key});
  @override
  ConsumerState<VerificationRequestScreen> createState() => _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends ConsumerState<VerificationRequestScreen> {
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  static const _docTypes = [
    (HugeIcons.strokeRoundedFile01, 'Certificate of Registration'),
    (HugeIcons.strokeRoundedBank, 'Bank Account Proof'),
    (HugeIcons.strokeRoundedId, 'Director ID Copy'),
    (HugeIcons.strokeRoundedBuilding04, 'Physical Address Proof'),
  ];

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final ngo = await ref.read(myNgoProvider.future);
    if (ngo == null) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await Supabase.instance.client.from('verification_requests').insert({
        'ngo_id': ngo.id,
        'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        'status': 'pending',
      });
      if (mounted) setState(() { _submitted = true; _submitting = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const shadow = [
      BoxShadow(color: Color(0x140891B2), blurRadius: 10, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
    ];

    if (_submitted) {
      return Scaffold(
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
              Text('Request Submitted', style: GoogleFonts.sora(
                fontSize: 22, fontWeight: FontWeight.w900, color: kForeground,
              )),
              const SizedBox(height: 8),
              Text(
                'Our team will review your request within 3–5 business days and update your account.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: kMutedFg, height: 1.55),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/ngo/settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Back to Settings', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: kSurface,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/ngo/settings'),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text('Request Verification', style: GoogleFonts.sora(
                    fontSize: 22, fontWeight: FontWeight.w800, color: kForeground,
                  )),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Get the verified badge to build donor trust.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // Benefits
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kMatched.withAlpha(10), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kMatched.withAlpha(40)),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(HugeIcons.strokeRoundedCheckmarkBadge01, size: 18, color: kMatched),
                    const SizedBox(width: 8),
                    Text('Benefits of Verification', style: GoogleFonts.sora(
                      fontSize: 14, fontWeight: FontWeight.w800, color: kMatched,
                    )),
                  ]),
                  const SizedBox(height: 10),
                  ...[
                    'Verified badge on your NGO profile',
                    'Higher ranking in donor search results',
                    'Increased donor trust and pledge rates',
                    'Access to premium analytics features',
                  ].map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Icon(HugeIcons.strokeRoundedTick01, size: 14, color: kMatched),
                      const SizedBox(width: 8),
                      Text(b, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kForeground)),
                    ]),
                  )),
                ]),
              ),
              const SizedBox(height: 20),

              Text('REQUIRED DOCUMENTS', style: GoogleFonts.sora(
                fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
              )),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: kSurface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder), boxShadow: shadow,
                ),
                child: Column(children: _docTypes.asMap().entries.map((e) => Column(children: [
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: kPrimary.withAlpha(18), borderRadius: BorderRadius.circular(10)),
                      child: Icon(e.value.$1, size: 18, color: kPrimary),
                    ),
                    title: Text(e.value.$2, style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kForeground,
                    )),
                    trailing: const Icon(HugeIcons.strokeRoundedInformationCircle, size: 16, color: kMutedFg),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  ),
                  if (e.key < _docTypes.length - 1) const Divider(height: 1, color: kBorder),
                ])).toList()),
              ),
              const SizedBox(height: 8),
              Text(
                'Documents are submitted to our team via email after this request.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kMutedFg),
              ),
              const SizedBox(height: 20),

              Text('NOTES (OPTIONAL)', style: GoogleFonts.sora(
                fontSize: 11, fontWeight: FontWeight.w800, color: kMutedFg, letterSpacing: 1.5,
              )),
              const SizedBox(height: 10),
              TextField(
                controller: _notesCtrl,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Anything you want to tell us about your organization…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: kPrimary.withValues(alpha: 0.5),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Submit Verification Request', style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 15,
                        )),
                ),
              ),
            ])),
          ),
        ],
      ),
    );
  }
}
