import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/downloads/presentation/pages/downloads_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/playlists/presentation/pages/playlists_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/shell/presentation/pages/main_shell_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              name: 'library',
              builder: (context, state) => const LibraryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/downloads',
              name: 'downloads',
              builder: (context, state) => const DownloadsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/playlists',
              name: 'playlists',
              builder: (context, state) => const PlaylistsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
