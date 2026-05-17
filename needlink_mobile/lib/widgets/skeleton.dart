import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';

// ── Internal helpers ──────────────────────────────────────────────────────────

Widget _shimmerWrap(Widget child) => Shimmer.fromColors(
      baseColor: const Color(0xFFE8F4F8),
      highlightColor: const Color(0xFFF5FBFF),
      child: child,
    );

class _Box extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  const _Box({required this.height, this.width, this.radius = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _Circle extends StatelessWidget {
  final double size;
  const _Circle({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
}

// ── Public skeleton widgets ───────────────────────────────────────────────────

/// Mimics a compact need card row (used on donor home)
class NeedCardSkeleton extends StatelessWidget {
  const NeedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Box(height: 13, width: 200),
                        const SizedBox(height: 6),
                        _Box(height: 10, width: 140),
                        const SizedBox(height: 9),
                        _Box(height: 4),
                        const SizedBox(height: 6),
                        _Box(height: 9, width: 180),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Mimics a pledge card row (used on my pledges and NGO pledges)
class PledgeCardSkeleton extends StatelessWidget {
  const PledgeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              const _Circle(size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(height: 13, width: 160),
                    const SizedBox(height: 5),
                    _Box(height: 10, width: 110),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Box(height: 24, width: 72, radius: 20),
            ],
          ),
        ),
      );
}

/// Mimics the profile header + stats section
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        Column(
          children: [
            Container(
              height: 260,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Circle(size: 80),
                    const SizedBox(height: 12),
                    _Box(height: 18, width: 140, radius: 9),
                    const SizedBox(height: 8),
                    _Box(height: 12, width: 180, radius: 6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    child: Container(
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )),
              ),
            ),
          ],
        ),
      );
}

/// Stat row skeleton for NGO dashboard
class StatsRowSkeleton extends StatelessWidget {
  const StatsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        Row(
          children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )),
        ),
      );
}
