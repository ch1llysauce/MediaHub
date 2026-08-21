import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:audio_service/audio_service.dart';

import 'app/app.dart';
import 'core/providers/providers.dart';
import 'core/services/mediahub_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();
  final container = ProviderContainer();

  await AudioService.init(
    builder: () => MediaHubAudioHandler(
      container.read(audioPlayerServiceProvider),
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.mediahub.audio',
      androidNotificationChannelName: 'MediaHub',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
   UncontrolledProviderScope(
      container: container,
      child: const MediaHubApp(),
    ),
  );
}

