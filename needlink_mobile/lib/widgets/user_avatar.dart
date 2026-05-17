import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Circle avatar that shows, in priority order:
/// 1. An uploaded photo (`avatarUrl`)
/// 2. A generated DiceBear avatar based on `seed` (userId or NGO id)
/// 3. Initials fallback while loading or when offline
class UserAvatar extends StatelessWidget {
  final String seed;
  final String initials;
  final String? avatarUrl;
  final double radius;
  final bool isOrg;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    required this.seed,
    required this.initials,
    this.avatarUrl,
    this.radius = 20,
    this.isOrg = false,
    this.onTap,
    this.showEditBadge = false,
  });

  static String diceBearUrl(String seed, {bool isOrg = false, int size = 256}) {
    final style = isOrg ? 'shapes' : 'lorelei';
    final encoded = Uri.encodeComponent(seed);
    return 'https://api.dicebear.com/9.x/$style/png'
        '?seed=$encoded&size=$size&backgroundColor=0891b2,0e7490,0c4a6e';
  }

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final imageUrl = avatarUrl ?? diceBearUrl(seed, isOrg: isOrg);

    Widget avatar = ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        placeholder: (_, _) => _InitialCircle(initials: initials, radius: radius, muted: true),
        errorWidget: (_, _, _) => _InitialCircle(initials: initials, radius: radius),
      ),
    );

    if (showEditBadge) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: radius * 0.65,
              height: radius * 0.65,
              decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
              child: Icon(Icons.camera_alt_rounded, size: radius * 0.35, color: Colors.white),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}

class _InitialCircle extends StatelessWidget {
  final String initials;
  final double radius;
  final bool muted;
  const _InitialCircle({required this.initials, required this.radius, this.muted = false});

  @override
  Widget build(BuildContext context) => Container(
    width: radius * 2,
    height: radius * 2,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: muted
            ? [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]
            : [const Color(0xFF164E63), kPrimary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        initials.isEmpty ? '?' : initials[0].toUpperCase(),
        style: TextStyle(
          color: muted ? kMutedFg : Colors.white,
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
