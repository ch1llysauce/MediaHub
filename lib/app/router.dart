import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/media_item_entity.dart';
import '../features/downloader/presentation/pages/downloads_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/favorites/presentation/pages/favorites_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/player/presentation/pages/video_player_page.dart';
import '../features/playlists/presentation/pages/playlist_detail_page.dart';
import '../features/playlists/presentation/pages/playlists_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/scan_directories_page.dart';
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
              routes: [
                GoRoute(
                  path: 'search',
                  name: 'search',
                  builder: (context, state) => const SearchPage(),
                ),
              ],
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
              routes: [
                GoRoute(
                  path: 'favorites',
                  name: 'favorites',
                  builder: (context, state) => const FavoritesPage(),
                ),
                GoRoute(
                  path: 'history',
                  name: 'history',
                  builder: (context, state) => const HistoryPage(),
                ),
                GoRoute(
                  path: ':id',
                  name: 'playlistDetail',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return PlaylistDetailPage(playlistId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: 'scan-directories',
                  name: 'scanDirectories',
                  builder: (context, state) => const ScanDirectoriesPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/player/video',
      name: 'videoPlayer',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          final item = map['item'] as MediaItemEntity;
          final playlist = map['playlist'] as List<MediaItemEntity>?;
          return VideoPlayerPage(item: item, playlist: playlist);
        }
        final item = state.extra as MediaItemEntity;
        return VideoPlayerPage(item: item);
      },
    ),

  ],
);

