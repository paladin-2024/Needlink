import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class DonorShell extends StatefulWidget {
  final Widget child;
  const DonorShell({super.key, required this.child});

  @override
  State<DonorShell> createState() => _DonorShellState();
}

class _DonorShellState extends State<DonorShell> {
  static const _tabs = [
    _NavItem(HugeIcons.strokeRoundedDiscoverCircle, HugeIcons.strokeRoundedDiscoverCircle, 'Discover', '/donor'),
    _NavItem(HugeIcons.strokeRoundedFavourite, HugeIcons.strokeRoundedFavourite, 'Donations', '/donor/pledges'),
    _NavItem(HugeIcons.strokeRoundedUser, HugeIcons.strokeRoundedUser, 'Profile', '/donor/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _AppNav(
        currentIndex: _activeIndex(location, _tabs),
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs,
      ),
    );
  }
}

class NgoShell extends StatefulWidget {
  final Widget child;
  const NgoShell({super.key, required this.child});

  @override
  State<NgoShell> createState() => _NgoShellState();
}

class _NgoShellState extends State<NgoShell> {
  static const _tabs = [
    _NavItem(HugeIcons.strokeRoundedDashboardSquare01, HugeIcons.strokeRoundedDashboardSquare01, 'Dashboard', '/ngo'),
    _NavItem(HugeIcons.strokeRoundedAnalytics01, HugeIcons.strokeRoundedAnalytics01, 'Analytics', '/ngo/analytics'),
    _NavItem(HugeIcons.strokeRoundedCheckList, HugeIcons.strokeRoundedCheckList, 'Pledges', '/ngo/pledges'),
    _NavItem(HugeIcons.strokeRoundedSettings01, HugeIcons.strokeRoundedSettings01, 'Settings', '/ngo/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _AppNav(
        currentIndex: _activeIndex(location, _tabs),
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs,
      ),
    );
  }
}

// Longest matching path wins — prevents /ngo matching /ngo/analytics.
int _activeIndex(String location, List<_NavItem> tabs) {
  int bestIndex = 0;
  int bestLength = -1;
  for (int i = 0; i < tabs.length; i++) {
    final path = tabs[i].path;
    if (location == path || location.startsWith('$path/')) {
      if (path.length > bestLength) {
        bestLength = path.length;
        bestIndex = i;
      }
    }
  }
  return bestIndex;
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem(this.icon, this.activeIcon, this.label, this.path);
}

class _AppNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;
  const _AppNav({required this.currentIndex, required this.onTap, required this.items});

  static const _primary = Color(0xFF0891B2);
  static const _muted = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60 + bottom,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom, top: 6),
            child: Row(
              children: List.generate(items.length, (i) {
                final active = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: items[i].icon,
                          color: active ? _primary : _muted,
                          size: 24,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            color: active ? _primary : _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
