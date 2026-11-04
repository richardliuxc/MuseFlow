import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/song.dart';
import '../api_client.dart';
import '../music_source.dart';

class QqSource implements MusicSource {
  QqSource(this._client);

  final ApiClient _client;
  final Random _random = Random();

  static const _headers = {
    'Referer': 'https://y.qq.com/',
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36',
  };

  @override
  String get id => 'qq';

  @override
  String get label => 'QQ 音乐';

  @override
  String get description => '正版曲库 · 需会员资源';

  @override
  Color get color => const Color(0xFF31C27C);

  @override
  bool get supportsStreaming => true;

  @override
  Future<List<Song>> search(String keyword, {int limit = 20}) async {
    final uri = Uri.https('c.y.qq.com', '/soso/fcgi-bin/client_search_cp', {
      'w': keyword,
      'format': 'json',
      'p': '1',
      'n': '$limit',
      'cr': '1',
      'new_json': '1',
    });
    final json = await _client.getJson(uri.toString(), headers: _headers);
    final data = json['data'];
    final songBlock = data is Map ? data['song'] : null;
    final list = songBlock is Map ? songBlock['list'] as List? ?? const [] : const [];
    final songs = <Song>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final mid = raw['songmid']?.toString() ?? raw['mid']?.toString() ?? '';
      if (mid.isEmpty) continue;
      final singers = (raw['singer'] as List? ?? const [])
          .map((singer) => singer is Map ? singer['name']?.toString() ?? '' : '')
          .where((name) => name.isNotEmpty)
          .join('、');
      final albumMid = raw['albummid']?.toString() ?? '';
      final cover = albumMid.isEmpty
          ? ''
          : 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
      final interval = int.tryParse(raw['interval']?.toString() ?? '') ?? 0;
      final pay = raw['pay'] is Map ? raw['pay'] as Map : const {};
      songs.add(
        Song(
          id: mid,
          source: 'qq',
          name: decodeHtml(raw['songname']?.toString() ?? raw['name']?.toString() ?? ''),
          artist: decodeHtml(singers),
          album: decodeHtml(raw['albumname']?.toString() ?? ''),
          cover: cover,
          durationMs: interval * 1000,
          bitrate: 320,
          extra: {
            'songmid': mid,
            'payplay': '${pay['payplay'] ?? 0}',
            'paydownload': '${pay['paydownload'] ?? 0}',
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
    final mid = song.extra['songmid'] ?? song.id;
    final guid = '${1000000000 + _random.nextInt(1000000000)}';
    final qualities = quality == AudioQuality.standard
        ? ['M500']
        : ['M800', 'M500'];
    final filenames = qualities.map((prefix) => '$prefix$mid$mid.mp3').toList();
    final payload = {
      'comm': {
        'cv': 4747474,
        'ct': 24,
        'format': 'json',
        'inCharset': 'utf-8',
        'outCharset': 'utf-8',
        'notice': 0,
        'platform': 'yqq.json',
        'needNewCode': 1,
        'uin': 0,
      },
      'req_1': {
        'module': 'music.vkey.GetVkey',
        'method': 'UrlGetVkey',
        'param': {
          'guid': guid,
          'songmid': [mid],
          'songtype': [0],
          'uin': '0',
          'loginflag': 1,
          'platform': '20',
          'filename': filenames,
        },
      },
    };
    try {
      final json = await _client.postJsonForMap(
        'https://u.y.qq.com/cgi-bin/musicu.fcg',
        body: payload,
        headers: _headers,
      );
      final data = (json['req_1'] as Map?)?['data'];
      final infoList = data is Map ? data['midurlinfo'] as List? ?? const [] : const [];
      for (final filename in filenames) {
        for (final info in infoList) {
          if (info is! Map) continue;
          if (info['filename']?.toString() != filename) continue;
          final purl = info['purl']?.toString() ?? '';
          if (purl.isEmpty) continue;
          if (purl.startsWith('http')) return purl;
          return 'https://ws.stream.qqmusic.qq.com/$purl';
        }
      }
      throw MusicApiException('QQ 音乐该曲目需要会员');
    } on MusicApiException {
      rethrow;
    } catch (_) {
      throw MusicApiException('QQ 音乐音源暂时不可用');
    }
  }

  @override
  Future<LyricBundle?> lyrics(Song song) async {
    try {
      final mid = song.extra['songmid'] ?? song.id;
      final uri = Uri.https('c.y.qq.com', '/lyric/fcgi-bin/fcg_query_lyric_new.fcg', {
        'songmid': mid,
        'format': 'json',
        'nobase64': '1',
      });
      final text = await _client.getText(uri.toString(), headers: _headers);
      var raw = text.trim();
      if (raw.startsWith('MusicJsonCallback(') && raw.endsWith(')')) {
        raw = raw.substring('MusicJsonCallback('.length, raw.length - 1);
      }
      final decoded = raw.contains('"lyric"')
          ? raw
          : raw.substring(raw.indexOf('{'), raw.lastIndexOf('}') + 1);
      final json = _decodeJson(decoded);
      final lrc = _unescape(json['lyric']?.toString() ?? '');
      if (lrc.trim().isEmpty) return null;
      return LyricBundle(lrc: lrc);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }

  String _unescape(String input) => input
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}
