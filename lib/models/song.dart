import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Normalised track model shared by every music provider.
@immutable
class Song {
  const Song({
    required this.id,
    required this.source,
    required this.name,
    required this.artist,
    this.album = '',
    this.cover = '',
    this.durationMs = 0,
    this.bitrate = 0,
    this.extra = const {},
  });

  final String id;
  final String source;
  final String name;
  final String artist;
  final String album;
  final String cover;
  final int durationMs;
  final int bitrate;
  final Map<String, String> extra;

  String get uid => '$source:$id';

  bool get isDemo => source == 'demo';

  bool get isRadio => source == 'radio' || extra['radio'] == '1';

  bool get isNas => source == 'nas' || extra['nas'] == '1';

  String? get assetPath => extra['asset'];

  String get sourceLabel => switch (source) {
        'netease' => '网易云',
        'kuwo' => '酷我',
        'kugou' => '酷狗',
        'qq' => 'QQ 音乐',
        'migu' => '咪咕',
        'demo' => 'MuseFlow',
        'radio' => '广播',
        'nas' => 'NAS',
        _ => source,
      };

  Color get sourceColor => switch (source) {
        'netease' => const Color(0xFFEC4141),
        'kuwo' => const Color(0xFFFFB800),
        'kugou' => const Color(0xFF2CA2F9),
        'qq' => const Color(0xFF31C27C),
        'migu' => const Color(0xFFE6006F),
        'demo' => AppColors.violet,
        'radio' => const Color(0xFFF59E0B),
        'nas' => const Color(0xFF38BDF8),
        _ => AppColors.cyan,
      };

  String get subtitle => album.isEmpty ? artist : '$artist · $album';

  Song copyWith({
    String? id,
    String? source,
    String? name,
    String? artist,
    String? album,
    String? cover,
    int? durationMs,
    int? bitrate,
    Map<String, String>? extra,
  }) {
    return Song(
      id: id ?? this.id,
      source: source ?? this.source,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      cover: cover ?? this.cover,
      durationMs: durationMs ?? this.durationMs,
      bitrate: bitrate ?? this.bitrate,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'name': name,
        'artist': artist,
        'album': album,
        'cover': cover,
        'durationMs': durationMs,
        'bitrate': bitrate,
        'extra': extra,
      };

  static Song? fromJson(dynamic value) {
    if (value is! Map) return null;
    try {
      return Song(
        id: value['id']?.toString() ?? '',
        source: value['source']?.toString() ?? '',
        name: value['name']?.toString() ?? '',
        artist: value['artist']?.toString() ?? '',
        album: value['album']?.toString() ?? '',
        cover: value['cover']?.toString() ?? '',
        durationMs: int.tryParse(value['durationMs']?.toString() ?? '') ?? 0,
        bitrate: int.tryParse(value['bitrate']?.toString() ?? '') ?? 0,
        extra: (value['extra'] as Map?)?.map(
              (key, dynamic v) => MapEntry(key.toString(), v?.toString() ?? ''),
            ) ??
            const {},
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Song && other.uid == uid && other.name == name;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'Song($source/$id, $name — $artist)';
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.description = '',
    this.cover = '',
    this.songs = const [],
    this.createdAt = 0,
    this.isEditorial = false,
  });

  final String id;
  final String name;
  final String description;
  final String cover;
  final List<Song> songs;
  final int createdAt;
  final bool isEditorial;

  int get totalDurationMs =>
      songs.fold(0, (total, song) => total + song.durationMs);

  String get artwork =>
      cover.isNotEmpty ? cover : (songs.isNotEmpty ? songs.first.cover : '');

  Playlist copyWith({
    String? name,
    String? description,
    String? cover,
    List<Song>? songs,
  }) =>
      Playlist(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        cover: cover ?? this.cover,
        songs: songs ?? this.songs,
        createdAt: createdAt,
        isEditorial: isEditorial,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'cover': cover,
        'songs': songs.map((song) => song.toJson()).toList(),
        'createdAt': createdAt,
      };

  static Playlist? fromJson(dynamic value) {
    if (value is! Map) return null;
    try {
      final songs = (value['songs'] as List?)
              ?.map(Song.fromJson)
              .whereType<Song>()
              .toList() ??
          const <Song>[];
      return Playlist(
        id: value['id']?.toString() ?? '',
        name: value['name']?.toString() ?? '未命名歌单',
        description: value['description']?.toString() ?? '',
        cover: value['cover']?.toString() ?? '',
        songs: songs,
        createdAt: int.tryParse(value['createdAt']?.toString() ?? '') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

class DownloadedTrack {
  const DownloadedTrack({required this.song, required this.path, required this.createdAt});

  final Song song;
  final String path;
  final int createdAt;

  Map<String, dynamic> toJson() => {
        'song': song.toJson(),
        'path': path,
        'createdAt': createdAt,
      };

  static DownloadedTrack? fromJson(dynamic value) {
    if (value is! Map) return null;
    final song = Song.fromJson(value['song']);
    final path = value['path']?.toString();
    if (song == null || path == null) return null;
    return DownloadedTrack(
      song: song,
      path: path,
      createdAt: int.tryParse(value['createdAt']?.toString() ?? '') ?? 0,
    );
  }
}

class ChartSummary {
  const ChartSummary({
    required this.id,
    required this.name,
    required this.tag,
    required this.colors,
    this.songs = const [],
  });

  final String id;
  final String name;
  final String tag;
  final List<Color> colors;
  final List<Song> songs;
}

enum RepeatMode { off, all, one }

enum AudioQuality { standard, high, lossless }

extension AudioQualityX on AudioQuality {
  String get label => switch (this) {
        AudioQuality.standard => '标准 · 128kbps',
        AudioQuality.high => '高品质 · 320kbps',
        AudioQuality.lossless => '无损 · FLAC',
      };

  String get shortLabel => switch (this) {
        AudioQuality.standard => '标准',
        AudioQuality.high => '高品质',
        AudioQuality.lossless => '无损',
      };
}
