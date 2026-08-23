import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../player/presentation/widgets/mini_player_widget.dart';

class MainShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellPage({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(index, initialLocation: true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 600;

        if (isWideScreen) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.selected,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.perm_media_outlined, size: 32),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.video_library_outlined),
                      selectedIcon: Icon(Icons.video_library),
                      label: Text('Library'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.download_for_offline_outlined),
                      selectedIcon: Icon(Icons.download_for_offline),
                      label: Text('Downloads'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.queue_music_outlined),
                      selectedIcon: Icon(Icons.queue_music),
                      label: Text('Playlists'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // BAGO: binalot sa Column para may lugar ang mini player sa ilalim
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: navigationShell),
                      const MiniPlayerWidget(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final isKeyboardOpen = bottomInset > 0;

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: AnimatedPadding(
            padding: EdgeInsets.only(bottom: bottomInset),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayerWidget(),
                if (!isKeyboardOpen)
                  BottomNavigationBar(
                    currentIndex: navigationShell.currentIndex,
                    onTap: _onDestinationSelected,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.video_library_outlined),
                        activeIcon: Icon(Icons.video_library),
                        label: 'Library',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.download_for_offline_outlined),
                        activeIcon: Icon(Icons.download_for_offline),
                        label: 'Downloads',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.queue_music_outlined),
                        activeIcon: Icon(Icons.queue_music),
                        label: 'Playlists',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings_outlined),
                        activeIcon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
