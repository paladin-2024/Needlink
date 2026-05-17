import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DonorShell extends StatelessWidget {
  final Widget child;
  const DonorShell({super.key, required this.child});

  static const _tabs = [
    _NavItem(Icons.explore_outlined, Icons.explore_rounded, 'Discover', '/donor'),
    _NavItem(Icons.volunteer_activism_outlined, Icons.volunteer_activism, 'Donations', '/donor/pledges'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', '/donor/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t.path)).clamp(0, _tabs.length - 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: _AppNav(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs,
      ),
    );
  }
}

class NgoShell extends StatelessWidget {
  final Widget child;
  const NgoShell({super.key, required this.child});

  static const _tabs = [
    _NavItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings_rounded, 'Dashboard', '/ngo'),
    _NavItem(Icons.assessment_outlined, Icons.assessment_rounded, 'Reports', '/ngo/reports'),
    _NavItem(Icons.checklist_outlined, Icons.checklist_rounded, 'Pledges', '/ngo/pledges'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'Settings', '/ngo/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t.path)).clamp(0, _tabs.length - 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: _AppNav(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs,
      ),
    );
  }
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

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 64,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF0891B2).withAlpha(28),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? const Color(0xFF0891B2) : const Color(0xFF94A3B8),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? const Color(0xFF0891B2)
              : const Color(0xFF94A3B8),
        )),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          elevation: 0,
          destinations: items.map((item) => NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          )).toList(),
        ),
      ),
    );
  }
}
