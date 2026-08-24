import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_color_scheme.dart';

/// Persistent user preferences for the Settings module.
class SettingsState {
  final ThemeMode themeMode;
  final AppColorScheme appColorScheme;
  final String? downloadDirectory;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.appColorScheme = AppColorScheme.teal,
    this.downloadDirectory,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppColorScheme? appColorScheme,
    String? downloadDirectory,
    bool clearDownloadDirectory = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      appColorScheme: appColorScheme ?? this.appColorScheme,
      downloadDirectory: clearDownloadDirectory
          ? null
          : (downloadDirectory ?? this.downloadDirectory),
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  static const _themeModeKey = 'settings.themeMode';
  static const _appColorSchemeKey = 'settings.appColorScheme';
  static const _downloadDirectoryKey = 'settings.downloadDirectory';

  SettingsController() : super(const SettingsState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDownloadDir = prefs.getString(_downloadDirectoryKey);
    final validDownloadDir =
        savedDownloadDir != null && savedDownloadDir.isNotEmpty
            ? savedDownloadDir
            : null;

    final fallbackDir = validDownloadDir ?? await _defaultDownloadDirectory();

    state = SettingsState(
      themeMode: _themeModeFromName(prefs.getString(_themeModeKey)),
      appColorScheme: _colorSchemeFromName(prefs.getString(_appColorSchemeKey)),
      downloadDirectory: fallbackDir,
    );
  }

  AppColorScheme _colorSchemeFromName(String? name) {
    if (name == null) return AppColorScheme.teal;
    return AppColorScheme.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppColorScheme.teal,
    );
  }

  ThemeMode _themeModeFromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<String> _defaultDownloadDirectory() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/MediaHub';
    }
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'MediaHub_Downloads');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeName(mode));
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    state = state.copyWith(appColorScheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appColorSchemeKey, scheme.name);
  }

  Future<void> setDownloadDirectory(String path) async {
    state = state.copyWith(downloadDirectory: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadDirectoryKey, path);
  }

  Future<void> resetDownloadDirectory() async {
    final defaultDir = await _defaultDownloadDirectory();
    state = state.copyWith(downloadDirectory: defaultDir);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadDirectoryKey, defaultDir);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController();
});
