import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/controllers/settings_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class MediaHubApp extends ConsumerWidget {
  const MediaHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'MediaHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(settings.appColorScheme),
      darkTheme: AppTheme.getDarkTheme(settings.appColorScheme),
      themeMode: settings.themeMode,
      routerConfig: appRouter,
    );
  }
}
