import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'services/audio_handler.dart';
import 'services/download_service.dart';
import 'services/library_store.dart';
import 'services/music_repository.dart';
import 'services/player_service.dart';
import 'services/radio_repository.dart';
import 'services/settings_store.dart';
import 'ui/screens/shell.dart';
import 'ui/screens/splash_screen.dart';

class MuseFlowApp extends StatefulWidget {
  const MuseFlowApp({
    super.key,
    required this.settings,
    required this.library,
    this.audioHandler,
  });

  final SettingsStore settings;
  final LibraryStore library;
  final MuseAudioHandler? audioHandler;

  @override
  State<MuseFlowApp> createState() => _MuseFlowAppState();
}

class _MuseFlowAppState extends State<MuseFlowApp> {
  late final MusicRepository _repository;
  late final PlayerService _player;
  late final DownloadService _downloads;
  late final RadioRepository _radio;

  @override
  void initState() {
    super.initState();
    _repository = MusicRepository(settings: widget.settings);
    _player = PlayerService(
      repository: _repository,
      library: widget.library,
      audioHandler: widget.audioHandler,
    );
    _downloads = DownloadService(repository: _repository, library: widget.library);
    _radio = RadioRepository();
  }

  @override
  void dispose() {
    _downloads.dispose();
    _player.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settings),
        ChangeNotifierProvider.value(value: widget.library),
        Provider<MusicRepository>.value(value: _repository),
        ChangeNotifierProvider<PlayerService>.value(value: _player),
        ChangeNotifierProvider<DownloadService>.value(value: _downloads),
        Provider<RadioRepository>.value(value: _radio),
      ],
      child: MaterialApp(
        title: 'MuseFlow · 沐声',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        scrollBehavior: const AppScrollBehavior(),
        home: const SplashGate(child: AppShell()),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
