import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/providers.dart';
import '../../../player/presentation/widgets/mini_player_widget.dart';

class MainShellPage extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellPage({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(index, initialLocation: true);
  }

  @override
  Widget build(BuildContext context) {
    final backIntercept = ref.watch(libraryFolderBackInterceptProvider);

    return PopScope(
      canPop: backIntercept == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        backIntercept?.call();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 600;
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

          if (isWideScreen) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: _onDestinationSelected,
                    labelType: isLandscape
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    // Center icons vertically along Y-axis instead of clumping at the top (-1.0)
                    groupAlignment: 0.0,
                    leading: Padding(
                      padding: EdgeInsets.symmetric(vertical: isLandscape ? 12 : 8),
                      child: Icon(
                        Icons.perm_media_outlined,
                        size: 28,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    destinations: [
                      NavigationRailDestination(
                        icon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.home_outlined),
                        ),
                        selectedIcon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.home),
                        ),
                        label: const Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.video_library_outlined),
                        ),
                        selectedIcon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.video_library),
                        ),
                        label: const Text('Library'),
                      ),
                      NavigationRailDestination(
                        icon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.download_for_offline_outlined),
                        ),
                        selectedIcon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.download_for_offline),
                        ),
                        label: const Text('Downloads'),
                      ),
                      NavigationRailDestination(
                        icon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.queue_music_outlined),
                        ),
                        selectedIcon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.queue_music),
                        ),
                        label: const Text('Playlists'),
                      ),
                      NavigationRailDestination(
                        icon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.settings_outlined),
                        ),
                        selectedIcon: Padding(
                          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 2),
                          child: const Icon(Icons.settings),
                        ),
                        label: const Text('Settings'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: widget.navigationShell),
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
            resizeToAvoidBottomInset: true,
            body: widget.navigationShell,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayerWidget(),
                if (!isKeyboardOpen)
                  BottomNavigationBar(
                    currentIndex: widget.navigationShell.currentIndex,
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
          );
        },
      ),
    );
  }
}