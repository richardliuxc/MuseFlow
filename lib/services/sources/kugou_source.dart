import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/song.dart';
import '../api_client.dart';
import '../music_source.dart';

class KugouSource implements MusicSource {
  KugouSource(this._client);

  final ApiClient _client;

  static const _headers = {
    'Referer': 'https://www.kugou.com/',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/80.0.3987.162 Mobile Safari/537.36',
  };

  @override
  String get id => 'kugou';

  @override
  String get label => '酷狗音乐';

  @override
  String get description => '海量曲库 · 部分会员';

  @override
  Color get color => const Color(0xFF2CA2F9);

  @override
  bool get supportsStreaming => true;

  String _clean(String value) {
    final stripped = value.replaceAll(RegExp(r'<[^>]+>'), '');
    return decodeHtml(stripped);
  }

  @override
  Future<List<Song>> search(String keyword, {int limit = 20}) async {
    final uri = Uri.https('songsearch.kugou.com', '/song_search_v2', {
      'keyword': keyword,
      'page': '1',
      'pagesize': '$limit',
      'platform': 'WebFilter',
      'format': 'json',
      'tag': 'em',
      'filter': '2',
      'iscorrection': '1',
      'privilege_filter': '0',
    });
    final json = await _client.getJson(uri.toString(), headers: _headers);
    final data = json['data'];
    final list = data is Map ? data['lists'] as List? ?? const [] : const [];
    final songs = <Song>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final hash = raw['FileHash']?.toString() ?? '';
      if (hash.isEmpty) continue;
      final duration = int.tryParse(raw['Duration']?.toString() ?? '') ?? 0;
      final size = int.tryParse(raw['FileSize']?.toString() ?? '') ?? 0;
      final bitrate = duration > 0 && size > 0
          ? (size * 8 / 1000 / duration).round()
          : 128;
      var cover = raw['Image']?.toString() ?? '';
      cover = cover.replaceAll('{size}', '400');
      if (cover.startsWith('http://')) {
        cover = cover.replaceFirst('http://', 'https://');
      }
      songs.add(
        Song(
          id: hash,
          source: 'kugou',
          name: _clean(raw['SongName']?.toString() ?? ''),
          artist: _clean(raw['SingerName']?.toString() ?? ''),
          album: _clean(raw['AlbumName']?.toString() ?? ''),
          cover: cover,
          durationMs: duration * 1000,
          bitrate: bitrate.clamp(0, 1000).toInt(),
          extra: {
            'hash': hash,
            'hqhash': raw['HQFileHash']?.toString() ?? '',
            'sqhash': raw['SQFileHash']?.toString() ?? '',
            'privilege': raw['Privilege']?.toString() ?? '',
            'paytype': raw['PayType']?.toString() ?? '',
          },
        ),
      );
    }
    return songs;
  }

  @override
  Future<String> resolveStream(
    Song song, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    var hash = song.extra['hash'] ?? song.id;
    if (quality == AudioQuality.lossless && (song.extra['sqhash'] ?? '').isNotEmpty) {
      hash = song.extra['sqhash']!;
    } else if (quality != AudioQuality.standard && (song.extra['hqhash'] ?? '').isNotEmpty) {
      hash = song.extra['hqhash']!;
    }
    final uri = Uri.https('m.kugou.com', '/app/i/getSongInfo.php', {
      'cmd': 'playInfo',
      'hash': hash,
    });
    try {
      final json = await _client.getJson(uri.toString(), headers: _headers);
      final url = json['url']?.toString() ?? '';
      if (url.isNotEmpty) return url;
      final fileName = json['fileName']?.toString();
      throw MusicApiException(
        fileName == null || fileName.isEmpty
            ? '酷狗该曲目需要会员'
            : '酷狗暂未开放该曲目',
      );
    } on MusicApiException {
      rethrow;
    } catch (_) {
      throw MusicApiException('酷狗音源暂时不可用');
    }
  }

  @override
  Future<LyricBundle?> lyrics(Song song) async {
    try {
      final hash = song.extra['hash'] ?? song.id;
      final searchUri = Uri.https('krcs.kugou.com', '/search', {
        'ver': '1',
        'man': 'yes',
        'client': 'mobi',
        'keyword': '',
        'duration': '${(song.durationMs / 1000).round()}',
        'hash': hash,
      });
      final search = await _client.getJson(searchUri.toString(), headers: _headers);
      final candidates = search['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;
      final candidate = candidates.first as Map;
      final id = candidate['id']?.toString();
      final accessKey = candidate['accesskey']?.toString();
      if (id == null || accessKey == null) return null;
      final uri = Uri.https('lyrics.kugou.com', '/download', {
        'ver': '1',
        'client': 'pc',
        'id': id,
        'accesskey': accessKey,
        'fmt': 'lrc',
        'charset': 'utf8',
      });
      final json = await _client.getJson(uri.toString(), headers: _headers);
      final content = json['content']?.toString();
      if (content == null || content.isEmpty) return null;
      final lrc = utf8.decode(base64Decode(content), allowMalformed: true);
      if (lrc.trim().isEmpty) return null;
      return LyricBundle(lrc: lrc);
    } catch (_) {
      return null;
    }
  }
}
