import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/library_store.dart';
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
  final settings = await SettingsStore.load();
  final library = await LibraryStore.load();
  runApp(MuseFlowApp(settings: settings, library: library));
}
