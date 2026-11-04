import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/song.dart';
import '../api_client.dart';
import '../music_source.dart';

class MiguSource implements MusicSource {
  MiguSource(this._client);

  final ApiClient _client;

  static const _headers = {
    'Referer': 'https://music.migu.cn/',
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
  };

  @override
  String get id => 'migu';

  @override
  String get label => '咪咕音乐';

  @override
  String get description => '搜索与元数据 · 自动换源';

  @override
  Color get color => const Color(0xFFE6006F);

  @override
  bool get supportsStreaming => false;

  @override
  Future<List<Song>> search(String keyword, {int limit = 20}) async {
    final uri = Uri.https('pd.musicapp.migu.cn', '/MIGUM2.0/v1.0/content/search_all.do', {
      'ua': 'Android_migu',
      'version': '5.0.1',
      'text': keyword,
      'pageNo': '1',
      'pageSize': '$limit',
      'searchSwitch': '{"song":1,"album":0,"singer":0,"tagSong":0,"mvSong":0,"songlist":0,"bestShow":1}',
    });
    final json = await _client.getJson(uri.toString(), headers: _headers);
    final block = json['songResultData'];
    final list = block is Map ? block['result'] as List? ?? const [] : const [];
    final songs = <Song>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final contentId = raw['contentId']?.toString() ?? '';
      if (contentId.isEmpty) continue;
      final singers = (raw['singers'] as List? ?? const [])
          .map((singer) => singer is Map ? singer['name']?.toString() ?? '' : '')
          .where((name) => name.isNotEmpty)
          .join('、');
      var album = '';
      final albums = raw['albums'];
      if (albums is List && albums.isNotEmpty && albums.first is Map) {
        album = (albums.first as Map)['name']?.toString() ?? '';
      }
      songs.add(
        Song(
          id: contentId,
          source: 'migu',
          name: decodeHtml(raw['name']?.toString() ?? ''),
          artist: decodeHtml(singers),
          album: decodeHtml(album),
          durationMs: 0,
          bitrate: 128,
          extra: {
            'contentId': contentId,
            'copyrightId': raw['copyrightId']?.toString() ?? '',
            'songId': raw['id']?.toString() ?? '',
            if (raw['lyricUrl']?.toString().isNotEmpty ?? false)
              'lyricUrl': raw['lyricUrl'].toString(),
          },
        ),
      );
    }
    return songs.take(limit).toList();
  }

  @override
  Future<String> resolveStream(
    Song song, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    throw MusicApiException('咪咕版权曲目暂不支持直接播放，正在为你切换音源');
  }

  @override
  Future<LyricBundle?> lyrics(Song song) async {
    final lyricUrl = song.extra['lyricUrl'];
    if (lyricUrl == null || lyricUrl.isEmpty) return null;
    try {
      final text = await _client.getText(lyricUrl, headers: _headers);
      if (!text.contains('[') || text.trim().isEmpty) return null;
      return LyricBundle(lrc: text);
    } catch (_) {
      return null;
    }
  }
}
