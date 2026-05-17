import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';

class SavedNeedsScreen extends ConsumerWidget {
  const SavedNeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedNeedsProvider);

    return Scaffold(
      body: savedAsync.when(
        data: (saved) => RefreshIndicator(
          color: kPrimary,
          onRefresh: () => ref.refresh(savedNeedsProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: kSurface,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.canPop() ? context.pop() : context.go('/donor/profile'),
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text('Saved Needs', style: GoogleFonts.sora(
                        fontSize: 22, fontWeight: FontWeight.w800, color: kForeground,
                      )),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      saved.isEmpty ? 'No saved needs yet' : '${saved.length} saved ${saved.length == 1 ? 'need' : 'needs'}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kMutedFg),
                    ),
                  ]),
                ),
              ),
              if (saved.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Lottie.asset('assets/lottie/empty_state.json', width: 160, height: 160),
                      const SizedBox(height: 4),
                      Text('Nothing saved yet', style: GoogleFonts.sora(
                        fontSize: 15, fontWeight: FontWeight.w700, color: kForeground,
                      )),
                      const SizedBox(height: 6),
                      Text('Tap the heart on any need to save it', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: kMutedFg,
                      )),
                    ]),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _SavedNeedCard(
                        savedNeed: saved[i],
                        onUnsave: () async {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) return;
                          await Supabase.instance.client
                              .from('saved_needs')
                              .delete()
                              .eq('donor_id', user.id)
                              .eq('need_id', saved[i].needId);
                          ref.invalidate(savedNeedsProvider);
                          ref.invalidate(savedNeedIdsProvider);
                        },
                        onTap: () => context.push('/donor/need/${saved[i].needId}'),
                      ),
                      childCount: saved.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: kUrgent))),
      ),
    );
  }
}

class _SavedNeedCard extends StatelessWidget {
  final SavedNeed savedNeed;
  final VoidCallback onUnsave;
  final VoidCallback onTap;
  const _SavedNeedCard({required this.savedNeed, required this.onUnsave, required this.onTap});

  static const _catColors = {
    'food': Color(0xFFEA580C), 'clothing': Color(0xFF7C3AED),
    'medicine': Color(0xFF16A34A), 'supplies': Color(0xFF0891B2),
  };

  @override
  Widget build(BuildContext context) {
    final need = savedNeed.need;
    if (need == null) return const SizedBox.shrink();
    final catColor = _catColors[need.category] ?? kPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 4, height: 52,
            decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(need.itemName, style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w700, color: kForeground,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              UserAvatar(
                seed: need.ngo?.id ?? need.ngoId,
                initials: need.ngo?.name.isNotEmpty == true ? need.ngo!.name[0].toUpperCase() : 'N',
                avatarUrl: need.ngo?.logoUrl,
                radius: 8, isOrg: true,
              ),
              const SizedBox(width: 5),
              Expanded(child: Text(
                '${need.ngo?.name ?? ''} · ${need.category}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kMutedFg),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: need.progress, minHeight: 4,
                backgroundColor: kMuted,
                valueColor: AlwaysStoppedAnimation(catColor),
              ),
            ),
            const SizedBox(height: 3),
            Text('${(need.progress * 100).round()}% · ${need.remaining} remaining',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMutedFg)),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onUnsave,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFFDC2626)),
            ),
          ),
        ]),
      ),
    );
  }
}
