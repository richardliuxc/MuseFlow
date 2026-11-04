import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/song.dart';
import '../api_client.dart';
import '../music_source.dart';

class NeteaseSource implements MusicSource {
  NeteaseSource(this._client);

  final ApiClient _client;

  static const _headers = {
    'Referer': 'https://music.163.com/',
    'Cookie': 'appver=2.0.2',
  };

  @override
  String get id => 'netease';

  @override
  String get label => '网易云音乐';

  @override
  String get description => '全曲库 · 歌词 · 封面';

  @override
  Color get color => const Color(0xFFEC4141);

  @override
  bool get supportsStreaming => true;

  Song? songFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString();
    final name = raw['name']?.toString();
    if (id == null || name == null || name.isEmpty) return null;
    final artists = (raw['artists'] as List? ?? raw['ar'] as List? ?? const [])
        .map((artist) => artist is Map ? artist['name']?.toString() ?? '' : '')
        .where((value) => value.isNotEmpty)
        .join('、');
    final album = raw['album'] is Map ? raw['album'] as Map : raw['al'] is Map ? raw['al'] as Map : null;
    final albumName = album?['name']?.toString() ?? '';
    var cover = album?['picUrl']?.toString() ?? album?['pic_url']?.toString() ?? '';
    if (cover.startsWith('http://')) {
      cover = cover.replaceFirst('http://', 'https://');
    }
    final durationMs = int.tryParse(raw['duration']?.toString() ?? '') ??
        int.tryParse(raw['dt']?.toString() ?? '') ??
        0;
    final fee = int.tryParse(raw['fee']?.toString() ?? '') ?? 0;
    return Song(
      id: id,
      source: 'netease',
      name: decodeHtml(name),
      artist: decodeHtml(artists),
      album: decodeHtml(albumName),
      cover: cover,
      durationMs: durationMs,
      extra: {
        'fee': '$fee',
        if (raw['privilege'] is Map)
          'st': '${(raw['privilege'] as Map)['st'] ?? ''}',
      },
    );
  }

  @override
  Future<List<Song>> search(String keyword, {int limit = 20}) async {
    final uri = Uri.https('music.163.com', '/api/search/get/web', {
      's': keyword,
      'type': '1',
      'offset': '0',
      'total': 'true',
      'limit': '$limit',
    });
    final json = await _client.getJson(uri.toString(), headers: _headers);
    final result = json['result'];
    if (result is! Map) {
      final code = json['code'];
      if (code != null && code != 200) {
        throw MusicApiException('网易云搜索失败（$code）');
      }
      return const [];
    }
    final songs = result['songs'] as List? ?? const [];
    return songs.map(songFromJson).whereType<Song>().toList();
  }

  @override
  Future<String> resolveStream(
    Song song, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    final br = switch (quality) {
      AudioQuality.standard => 128000,
      AudioQuality.high => 320000,
      AudioQuality.lossless => 999000,
    };
    try {
      final uri = Uri.https('music.163.com', '/api/song/enhance/player/url', {
        'ids': '[${song.id}]',
        'br': '$br',
      });
      final json = await _client.getJson(uri.toString(), headers: _headers);
      final data = json['data'];
      if (data is List && data.isNotEmpty) {
        final item = data.first;
        if (item is Map) {
          final url = item['url']?.toString();
          if (url != null && url.isNotEmpty) return url;
        }
      }
    } catch (_) {
      // Fall through to the public outer-url route.
    }

    final outer = 'https://music.163.com/song/media/outer/url?id=${song.id}.mp3';
    if (await _client.isPlayable(outer)) {
      return outer;
    }
    throw MusicApiException('网易云版权限制：该曲目需要会员或已下架');
  }

  @override
  Future<LyricBundle?> lyrics(Song song) async {
    try {
      final uri = Uri.https('music.163.com', '/api/song/lyric', {
        'id': song.id,
        'lv': '1',
        'kv': '1',
        'tv': '-1',
      });
      final json = await _client.getJson(uri.toString(), headers: _headers);
      final lrc = (json['lrc'] as Map?)?['lyric']?.toString() ?? '';
      final translation = (json['tlyric'] as Map?)?['lyric']?.toString();
      if (lrc.trim().isEmpty) return null;
      return LyricBundle(
        lrc: lrc,
        translation: (translation ?? '').trim().isEmpty ? null : translation,
      );
    } catch (_) {
      return null;
    }
  }
}
