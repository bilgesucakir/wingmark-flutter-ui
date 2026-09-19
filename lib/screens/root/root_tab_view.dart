import 'package:flutter/material.dart';

import '../../core/app_localizations.dart';
import '../badges/badges_screen.dart';
import '../diary/diary_screen.dart';
import '../guide/guide_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

/// Main tab bar, mirroring Swift's RootTabView (Map / Guide / Diary /
/// Badges / Profile, in that order).
class RootTabView extends StatefulWidget {
  const RootTabView({super.key});

  @override
  State<RootTabView> createState() => _RootTabViewState();
}

class _RootTabViewState extends State<RootTabView> {
  int _index = 0;

  static const _screens = [
    MapScreen(),
    GuideScreen(),
    DiaryScreen(),
    BadgesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.tabMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.tabGuide,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories),
            label: l10n.tabDiary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events),
            label: l10n.tabBadges,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
