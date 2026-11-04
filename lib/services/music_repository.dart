import 'dart:async';


import '../core/lrc.dart';
import '../core/utils.dart';
import '../data/demo_catalog.dart';
import '../models/song.dart';
import 'api_client.dart';
import 'music_source.dart';
import 'settings_store.dart';
import 'sources/demo_source.dart';
import 'sources/kugou_source.dart';
import 'sources/kuwo_source.dart';
import 'sources/migu_source.dart';
import 'sources/netease_source.dart';
import 'sources/qq_source.dart';

class MusicRepository {
  MusicRepository({required SettingsStore settings, ApiClient? client})
      : _settings = settings,
        _client = client ?? ApiClient() {
    _sources = {
      'netease': NeteaseSource(_client),
      'kuwo': KuwoSource(_client),
      'kugou': KugouSource(_client),
      'qq': QqSource(_client),
      'migu': MiguSource(_client),
      'demo': const DemoSource(),
    };
  }

  final SettingsStore _settings;
  final ApiClient _client;
  late final Map<String, MusicSource> _sources;
  final Map<String, List<LyricLine>> _lyricCache = {};
  final Map<String, List<Song>> _chartCache = {};

  static const chartIds = {
    'hot': 3778678,
    'new': 3779629,
    'rising': 19723756,
  };

  List<MusicSource> get sources => _sources.values.toList(growable: false);

  MusicSource sourceFor(String id) =>
      _sources[id] ?? _sources['demo']!;

  bool isSourceEnabled(String id) => _settings.isSourceEnabled(id);

  Future<SearchOutcome> search(String query, {String? sourceId, int limit = 36}) async {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      return const SearchOutcome(songs: [], errors: {});
    }
    final active = <MusicSource>[];
    if (sourceId != null) {
      active.add(sourceFor(sourceId));
    } else {
      for (final source in _sources.values) {
        if (_settings.isSourceEnabled(source.id)) active.add(source);
      }
      if (active.isEmpty) active.add(_sources['demo']!);
    }
    final perSource = sourceId != null ? limit : (limit / active.length).ceil().clamp(6, 14);
    final errors = <String, String>{};

    final results = await Future.wait(
      active.map((source) async {
        try {
          final songs = await source
              .search(keyword, limit: perSource)
              .timeout(const Duration(seconds: 14));
          return MapEntry(source, songs);
        } catch (error) {
          errors[source.label] = errorText(error);
          return MapEntry(source, const <Song>[]);
        }
      }),
    );

    if (sourceId != null) {
      return SearchOutcome(songs: results.first.value, errors: errors);
    }

    // Round-robin interleave so a single provider cannot flood the results.
    final buckets = results.map((entry) => List<Song>.of(entry.value)).toList();
    final merged = <Song>[];
    final seen = <String>{};
    var index = 0;
    var added = true;
    while (added && merged.length < limit) {
      added = false;
      for (final bucket in buckets) {
        if (index >= bucket.length) continue;
        final song = bucket[index];
        if (seen.add(song.uid)) {
          merged.add(song);
          added = true;
        }
        if (merged.length >= limit) break;
      }
      index++;
    }
    return SearchOutcome(songs: merged, errors: errors);
  }

  Future<List<Song>> chartSongs(String chartId) async {
    if (_chartCache.containsKey(chartId)) return _chartCache[chartId]!;
    final remoteId = chartIds[chartId];
    if (remoteId == null) {
      final fallback = demoCharts.firstWhere(
        (chart) => chart.id == chartId,
        orElse: () => demoCharts.first,
      ).songs;
      _chartCache[chartId] = fallback;
      return fallback;
    }
    try {
      final uri = Uri.https('music.163.com', '/api/v6/playlist/detail', {
        'id': '$remoteId',
        'n': '60',
      });
      final json = await _client.getJson(
        uri.toString(),
        headers: const {
          'Referer': 'https://music.163.com/',
          'Cookie': 'appver=2.0.2',
        },
        timeout: const Duration(seconds: 14),
      );
      final playlist = json['playlist'];
      if (playlist is! Map) throw MusicApiException('榜单接口异常');
      final tracks = playlist['tracks'] as List? ?? const [];
      final netease = _sources['netease'] as NeteaseSource;
      final songs = tracks
          .map(netease.songFromJson)
          .whereType<Song>()
          .take(40)
          .toList();
      if (songs.isEmpty) throw MusicApiException('榜单为空');
      _chartCache[chartId] = songs;
      return songs;
    } catch (_) {
      final fallback = demoCharts.firstWhere(
        (chart) => chart.id == chartId,
        orElse: () => demoCharts.first,
      ).songs;
      _chartCache[chartId] = fallback;
      return fallback;
    }
  }

  Future<List<Song>> dailyMix() async {
    final day = DateTime.now();
    final seed = stableHash('${day.year}-${day.month}-${day.day}');
    final pool = List<Song>.of(demoTracks);
    pool.sort((a, b) => stableHash(a.uid).compareTo(stableHash(b.uid)));
    final offset = seed % pool.length;
    final rotated = [...pool.sublist(offset), ...pool.sublist(0, offset)];
    return rotated.take(6).toList();
  }

  Future<ResolvedStream> resolve(Song song, {bool allowSwitch = true}) async {
    final primary = sourceFor(song.source);
    Object? primaryError;
    try {
      final url = await primary
          .resolveStream(song, quality: _settings.quality)
          .timeout(const Duration(seconds: 16));
      if (url.trim().isEmpty) throw MusicApiException('未获取到音频地址');
      return ResolvedStream(
        url: url,
        song: song,
        isAsset: song.isDemo,
        note: null,
      );
    } catch (error) {
      primaryError = error;
    }

    if (!allowSwitch || !_settings.autoSwitchSource) {
      throw MusicApiException('${song.sourceLabel}：${errorText(primaryError)}');
    }

    final fallbackOrder = ['netease', 'kuwo', 'kugou', 'qq']
        .where((id) => id != song.source && _settings.isSourceEnabled(id));
    final normalized = _normalize(song.name);
    var attempts = 0;
    for (final id in fallbackOrder) {
      if (attempts >= 3) break;
      final source = _sources[id]!;
      if (!source.supportsStreaming) continue;
      try {
        final candidates = await source
            .search('${song.name} ${song.artist.split('、').first}', limit: 5)
            .timeout(const Duration(seconds: 12));
        final match = _bestMatch(song, candidates, normalized);
        if (match == null) continue;
        attempts++;
        final url = await source
            .resolveStream(match, quality: _settings.quality)
            .timeout(const Duration(seconds: 16));
        if (url.trim().isEmpty) continue;
        return ResolvedStream(
          url: url,
          song: match,
          isAsset: match.isDemo,
          switched: true,
          note: '${song.sourceLabel} 暂不可用，已切换到 ${source.label}',
        );
      } catch (_) {
        continue;
      }
    }

    throw MusicApiException(
      '${song.sourceLabel}：${errorText(primaryError)}\n已尝试自动换源，仍未找到可播放版本',
    );
  }

  Song? _bestMatch(Song original, List<Song> candidates, String normalized) {
    Song? best;
    var bestScore = 0;
    for (final candidate in candidates) {
      final normalizedName = _normalize(candidate.name);
      var score = 0;
      if (normalizedName == normalized) {
        score += 5;
      } else if (normalizedName.contains(normalized) || normalized.contains(normalizedName)) {
        score += 3;
      }
      if (candidate.artist.contains(original.artist.split('、').first)) score += 3;
      if (original.durationMs > 0 &&
          candidate.durationMs > 0 &&
          (candidate.durationMs - original.durationMs).abs() < 15000) {
        score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return bestScore >= 3 ? best : null;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\-_/\\()（）\[\]【】]'), '')
      .replaceAll(RegExp(r'(live|remix|demo|伴奏|纯音乐|现场|版)'), '')
      .trim();

  Future<List<LyricLine>> lyrics(Song song, {String? translation}) async {
    final cached = _lyricCache[song.uid];
    if (cached != null) return cached;
    try {
      final source = sourceFor(song.source);
      var bundle = await source.lyrics(song).timeout(const Duration(seconds: 10));
      if ((bundle == null || bundle.lrc.trim().isEmpty) && song.source != 'netease') {
        bundle = await _neteaseLyricsFor(song);
      }
      if (bundle == null || bundle.lrc.trim().isEmpty) return const [];
      final lines = parseLrc(bundle.lrc, translationRaw: bundle.translation);
      if (lines.isNotEmpty) _lyricCache[song.uid] = lines;
      return lines;
    } catch (_) {
      return const [];
    }
  }

  Future<LyricBundle?> _neteaseLyricsFor(Song song) async {
    try {
      final netease = _sources['netease'] as NeteaseSource;
      final results = await netease
          .search('${song.name} ${song.artist.split('、').first}', limit: 3)
          .timeout(const Duration(seconds: 10));
      if (results.isEmpty) return null;
      final match = _bestMatch(song, results, _normalize(song.name));
      if (match == null) return null;
      return netease.lyrics(match);
    } catch (_) {
      return null;
    }
  }

  void clearCharts() => _chartCache.clear();

  void dispose() => _client.dispose();
}
