import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';

class NgoMapScreen extends ConsumerStatefulWidget {
  const NgoMapScreen({super.key});
  @override
  ConsumerState<NgoMapScreen> createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends ConsumerState<NgoMapScreen> {
  Ngo? _selected;
  final _mapCtrl = MapController();

  @override
  Widget build(BuildContext context) {
    final ngosAsync = ref.watch(allNgosProvider);

    return Scaffold(
      body: Stack(children: [
        ngosAsync.when(
          data: (ngos) {
            final mapped = ngos.where((n) => n.latitude != null && n.longitude != null).toList();
            return FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: mapped.isNotEmpty
                    ? LatLng(mapped.first.latitude!, mapped.first.longitude!)
                    : const LatLng(-1.9403, 29.8739),
                initialZoom: 7,
                onTap: (tapPos, latLng) => setState(() => _selected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'io.needlink.app',
                ),
                MarkerLayer(
                  markers: mapped.map((ngo) => Marker(
                    point: LatLng(ngo.latitude!, ngo.longitude!),
                    width: 44, height: 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selected = ngo);
                        _mapCtrl.move(LatLng(ngo.latitude!, ngo.longitude!), 13);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(color: kPrimary.withAlpha(80), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Center(
                          child: UserAvatar(
                            seed: ngo.id,
                            initials: ngo.name.isNotEmpty ? ngo.name[0].toUpperCase() : 'N',
                            avatarUrl: ngo.logoUrl,
                            radius: 16, isOrg: true,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: kUrgent))),
        ),

        // Back button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8)],
                  ),
                  child: IconButton(
                    icon: const Icon(HugeIcons.strokeRoundedArrowLeft01, color: kForeground),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/donor'),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                  ),
                  child: Text('NGO Map', style: GoogleFonts.sora(
                    fontSize: 14, fontWeight: FontWeight.w800, color: kForeground,
                  )),
                ),
              ],
            ),
          ),
        ),

        // NGO count badge
        ngosAsync.when(
          data: (ngos) {
            final count = ngos.where((n) => n.latitude != null && n.longitude != null).length;
            if (count == 0) return const SizedBox.shrink();
            return Positioned(
              top: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                    ),
                    child: Text('$count NGOs', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700, color: kForeground,
                    )),
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Selected NGO bottom sheet
        if (_selected != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _NgoBottomCard(
              ngo: _selected!,
              onClose: () => setState(() => _selected = null),
              onViewNeeds: () => context.push('/donor?ngo=${_selected!.id}'),
            ),
          ),
      ]),
    );
  }
}

class _NgoBottomCard extends StatelessWidget {
  final Ngo ngo;
  final VoidCallback onClose;
  final VoidCallback onViewNeeds;
  const _NgoBottomCard({required this.ngo, required this.onClose, required this.onViewNeeds});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20, offset: const Offset(0, -4))],
    ),
    child: Row(children: [
      UserAvatar(
        seed: ngo.id,
        initials: ngo.name.isNotEmpty ? ngo.name[0].toUpperCase() : 'N',
        avatarUrl: ngo.logoUrl,
        radius: 24, isOrg: true,
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(ngo.name, style: GoogleFonts.sora(
            fontSize: 15, fontWeight: FontWeight.w800, color: kForeground,
          ), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (ngo.verified)
            const Icon(HugeIcons.strokeRoundedCheckmarkBadge01, size: 16, color: kMatched),
        ]),
        Row(children: [
          const Icon(HugeIcons.strokeRoundedLocation01, size: 13, color: kMutedFg),
          const SizedBox(width: 3),
          Expanded(child: Text(ngo.location, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: kMutedFg,
          ), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ])),
      const SizedBox(width: 8),
      Column(children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: kBackground, shape: BoxShape.circle),
            child: const Icon(HugeIcons.strokeRoundedCancel01, size: 16, color: kMutedFg),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onViewNeeds,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Needs', style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700,
          )),
        ),
      ]),
    ]),
  );
}
