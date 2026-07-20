import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';

/// Bottom-nav shell hosting the five primary sections. Kept intentionally
/// shallow: each destination owns its own Navigator stack via go_router's
/// StatefulShellRoute so switching tabs preserves scroll/state.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final destinations = [
      (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: s.navDashboard),
      (icon: Icons.grass_outlined, activeIcon: Icons.grass_rounded, label: s.navFarms),
      (icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: s.navMarket),
      (icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: s.navAiChat),
      (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: s.navProfile),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          for (final d in destinations)
            BottomNavigationBarItem(
              icon: Icon(d.icon),
              activeIcon: Icon(d.activeIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
