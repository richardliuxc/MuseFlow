import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/demo_catalog.dart';
import '../../models/song.dart';
import '../music_source.dart';

class DemoSource implements MusicSource {
  const DemoSource();

  @override
  String get id => 'demo';

  @override
  String get label => 'MuseFlow 录音室';

  @override
  String get description => '原创示例曲 · 完全离线';

  @override
  Color get color => AppColors.violet;

  @override
  bool get supportsStreaming => true;

  @override
  Future<List<Song>> search(String keyword, {int limit = 20}) async {
    final query = keyword.trim().toLowerCase();
    if (query.isEmpty) return demoTracks.take(limit).toList();
    final tokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final matched = demoTracks.where((song) {
      final haystack =
          '${song.name} ${song.artist} ${song.album} ${song.extra['genre'] ?? ''}'
              .toLowerCase();
      return tokens.every(haystack.contains);
    }).toList();
    return matched.take(limit).toList();
  }

  @override
  Future<String> resolveStream(
    Song song, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    final asset = song.assetPath;
    if (asset == null || asset.isEmpty) {
      throw Exception('示例音轨缺失');
    }
    return asset;
  }

  @override
  Future<LyricBundle?> lyrics(Song song) async {
    final lrc = demoLyrics[song.id];
    if (lrc == null) return null;
    return LyricBundle(lrc: lrc);
  }
}
