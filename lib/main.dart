import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/audio_handler.dart';
import 'services/library_store.dart';
import 'services/nas_store.dart';
import 'services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF06070D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  MuseAudioHandler? audioHandler;
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      final handler = await AudioService.init(
        builder: MuseAudioHandler.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'app.museflow.playback',
          androidNotificationChannelName: 'MuseFlow 播放控制',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
        ),
      );
      audioHandler = handler;
    } catch (error, stackTrace) {
      debugPrint('Media notification unavailable: $error\n$stackTrace');
    }
  }

  final settings = await SettingsStore.load();
  final library = await LibraryStore.load();
  final nas = await NasStore.load();
  runApp(MuseFlowApp(
    settings: settings,
    library: library,
    nasStore: nas,
    audioHandler: audioHandler,
  ));
}
