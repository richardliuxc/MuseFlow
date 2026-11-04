import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/song.dart';
import '../api_client.dart';
import '../music_source.dart';

class KuwoSource implements MusicSource {
  KuwoSource(this._client);

  final ApiClient _client;

  static const _headers = {
    'Referer': 'https://www.kuwo.cn/',
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
  };

  @override
  String get id => 'kuwo';

  @override
  String get label => '酷我音乐';

  @override
  String get description => '高可用直链 · 多码率';

  @override
  Color get color => const Color(0xFFFFB800);

  @override
  bool get supportsStreaming => true;

  Map<String, dynamic> _decode(String raw) {
    var text = raw.trim();
    if (text.startsWith('(') && text.endsWith(')')) {
      text = text.substring(1, text.length - 1);
    }
    if (text.startsWith('callback(')) {
      text = text.substring(text.indexOf('(') + 1, text.lastIndexOf(')'));
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Kuwo's legacy endpoint returns single-quoted pseudo JSON. Values escape
      // apostrophes as &apos;, so a quote swap is safe for this payload.
      final swapped = text.replaceAll("'", '"');
      final decoded = jsonDecode(swapped);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw MusicApiException('酷我接口返回格式异常');
  }

  int _bitrateFrom(String minfo) {
    final values = RegExp(r'bitrate:(\d+),format:mp3')
        .allMatches(minfo)
        .map((match) => int.tryParse(match.group(1) ?? '') ?? 0)
        .where((value) => value > 0 && value <= 1000);
    if (values.isEmpty) return 128;
    return values.reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<List<Song>> search(String keyword, {int limit = 20}) async {
    final uri = Uri.https('search.kuwo.cn', '/r.s', {
      'all': keyword,
      'ft': 'music',
      'itemset': 'web_2013',
      'client': 'kt',
      'pn': '0',
      'rn': '$limit',
      'rformat': 'json',
      'encoding': 'utf8',
    });
    final raw = await _client.getText(uri.toString(), headers: _headers);
    final json = _decode(raw);
    final list = json['abslist'] as List? ?? const [];
    final songs = <Song>[];
    for (final rawItem in list) {
      if (rawItem is! Map) continue;
      final musicId = rawItem['MUSICRID']?.toString() ?? '';
      final id = musicId.replaceFirst('MUSIC_', '');
      if (id.isEmpty) continue;
      var cover = rawItem['hts_MVPIC']?.toString() ??
          rawItem['web_albumpic_short']?.toString() ??
          '';
      if (cover.startsWith('http://')) {
        cover = cover.replaceFirst('http://', 'https://');
      }
      final seconds = int.tryParse(rawItem['DURATION']?.toString() ?? '') ?? 0;
      final minfo = rawItem['MINFO']?.toString() ?? '';
      songs.add(
        Song(
          id: id,
          source: 'kuwo',
          name: decodeHtml(rawItem['SONGNAME']?.toString() ?? ''),
          artist: decodeHtml(rawItem['ARTIST']?.toString() ?? ''),
          album: decodeHtml(rawItem['ALBUM']?.toString() ?? ''),
          cover: cover,
          durationMs: seconds * 1000,
          bitrate: _bitrateFrom(minfo),
          extra: {
            'rid': id,
            'pay': rawItem['PAY']?.toString() ?? '0',
            'formats': rawItem['FORMATS']?.toString() ?? '',
          },
        ),
      );
    }
    return songs;
  }

  @override
  Future<LyricBundle?> lyrics(Song song) async => null;

  @override
  Future<String> resolveStream(
    Song song, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    final formats = quality == AudioQuality.lossless
        ? const ['flac', 'mp3']
        : const ['mp3'];
    Object? lastError;
    for (final format in formats) {
      try {
        final uri = Uri.https('antiserver.kuwo.cn', '/anti.s', {
          'type': 'convert_url',
          'format': format,
          'response': 'url',
          'rid': 'MUSIC_${song.id}',
        });
        final text = (await _client.getText(uri.toString(), headers: _headers)).trim();
        if (text.startsWith('http')) return text;
        lastError = MusicApiException('酷我暂未提供该曲目音频');
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? MusicApiException('酷我音源暂时不可用');
  }
}
