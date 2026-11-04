import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._prefs);

  static const _key = 'museflow.settings.v1';
  final SharedPreferences _prefs;

  AudioQuality _quality = AudioQuality.high;
  bool _autoSwitchSource = true;
  bool _showTranslation = false;
  bool _animatedCover = true;
  bool _wifiOnlyDownload = false;
  bool _demoSourceEnabled = true;
  final Set<String> _disabledSources = <String>{};

  AudioQuality get quality => _quality;
  bool get autoSwitchSource => _autoSwitchSource;
  bool get showTranslation => _showTranslation;
  bool get animatedCover => _animatedCover;
  bool get wifiOnlyDownload => _wifiOnlyDownload;
  bool get demoSourceEnabled => _demoSourceEnabled;

  static Future<SettingsStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsStore._(prefs);
    store._restore();
    return store;
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _quality = AudioQuality.values.firstWhere(
        (value) => value.name == json['quality'],
        orElse: () => AudioQuality.high,
      );
      _autoSwitchSource = json['autoSwitchSource'] as bool? ?? true;
      _showTranslation = json['showTranslation'] as bool? ?? false;
      _animatedCover = json['animatedCover'] as bool? ?? true;
      _wifiOnlyDownload = json['wifiOnlyDownload'] as bool? ?? false;
      _demoSourceEnabled = json['demoSourceEnabled'] as bool? ?? true;
      final disabled = (json['disabledSources'] as List?)?.cast<String>();
      if (disabled != null) {
        _disabledSources
          ..clear()
          ..addAll(disabled);
      }
    } catch (_) {
      // Keep defaults on corrupted settings.
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'quality': _quality.name,
        'autoSwitchSource': _autoSwitchSource,
        'showTranslation': _showTranslation,
        'animatedCover': _animatedCover,
        'wifiOnlyDownload': _wifiOnlyDownload,
        'demoSourceEnabled': _demoSourceEnabled,
        'disabledSources': _disabledSources.toList(),
      }),
    );
    notifyListeners();
  }

  bool isSourceEnabled(String source) {
    if (source == 'demo') return _demoSourceEnabled;
    return !_disabledSources.contains(source);
  }

  Future<void> setQuality(AudioQuality quality) async {
    _quality = quality;
    await _persist();
  }

  Future<void> setAutoSwitchSource(bool value) async {
    _autoSwitchSource = value;
    await _persist();
  }

  Future<void> setShowTranslation(bool value) async {
    _showTranslation = value;
    await _persist();
  }

  Future<void> setAnimatedCover(bool value) async {
    _animatedCover = value;
    await _persist();
  }

  Future<void> setWifiOnlyDownload(bool value) async {
    _wifiOnlyDownload = value;
    await _persist();
  }

  Future<void> setDemoSourceEnabled(bool value) async {
    _demoSourceEnabled = value;
    await _persist();
  }

  Future<void> setSourceEnabled(String source, bool enabled) async {
    if (source == 'demo') {
      _demoSourceEnabled = enabled;
    } else if (enabled) {
      _disabledSources.remove(source);
    } else {
      _disabledSources.add(source);
    }
    await _persist();
  }

  Set<String> get disabledSources => Set.unmodifiable(_disabledSources);
}
