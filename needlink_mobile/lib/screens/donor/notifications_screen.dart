import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      body: notifAsync.when(
        data: (notifications) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: kSurface,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/donor'),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Notifications', style: GoogleFonts.sora(
                    fontSize: 22, fontWeight: FontWeight.w800, color: kForeground,
                  ))),
                  if (notifications.any((n) => !n.read))
                    TextButton(
                      onPressed: () async {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) return;
                        await Supabase.instance.client
                            .from('notifications')
                            .update({'read': true})
                            .eq('user_id', user.id)
                            .eq('read', false);
                        ref.invalidate(notificationsProvider);
                      },
                      child: Text('Mark all read', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600,
                      )),
                    ),
                ]),
              ),
            ),
            if (notifications.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: kPrimary.withAlpha(15), shape: BoxShape.circle,
                      ),
                      child: const Icon(HugeIcons.strokeRoundedNotification01, size: 36, color: kPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text('All caught up', style: GoogleFonts.sora(
                      fontSize: 16, fontWeight: FontWeight.w700, color: kForeground,
                    )),
                    const SizedBox(height: 6),
                    Text('Pledge updates and alerts appear here', style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: kMutedFg,
                    )),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _NotificationTile(
                      notif: notifications[i],
                      onTap: () async {
                        if (!notifications[i].read) {
                          await Supabase.instance.client
                              .from('notifications')
                              .update({'read': true})
                              .eq('id', notifications[i].id);
                          ref.invalidate(notificationsProvider);
                        }
                      },
                    ),
                    childCount: notifications.length,
                  ),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: kUrgent))),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  const _NotificationTile({required this.notif, required this.onTap});

  static const _typeConfig = {
    'pledge_update': (HugeIcons.strokeRoundedCharity, kPrimary),
    'new_need': (HugeIcons.strokeRoundedPackage, Color(0xFF7C3AED)),
    'system': (HugeIcons.strokeRoundedInformationCircle, kMutedFg),
    'delivery': (HugeIcons.strokeRoundedTruck, kMatched),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig[notif.type] ?? _typeConfig['system']!;
    final createdAt = DateTime.tryParse(notif.createdAt);
    final timeStr = createdAt != null ? _timeAgo(createdAt) : '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.read ? kSurface : kPrimary.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: notif.read ? kBorder : kPrimary.withAlpha(40)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: cfg.$2.withAlpha(18), shape: BoxShape.circle,
            ),
            child: Icon(cfg.$1, size: 20, color: cfg.$2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(notif.title, style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: notif.read ? FontWeight.w600 : FontWeight.w800,
                color: kForeground,
              ))),
              if (!notif.read)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                ),
            ]),
            const SizedBox(height: 2),
            Text(notif.body, style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: kMutedFg, height: 1.4,
            )),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(timeStr, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMutedFg)),
            ],
          ])),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
