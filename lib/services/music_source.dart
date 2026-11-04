import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/song.dart';

class LyricBundle {
  const LyricBundle({required this.lrc, this.translation});

  final String lrc;
  final String? translation;
}

class ResolvedStream {
  const ResolvedStream({
    required this.url,
    required this.song,
    this.isAsset = false,
    this.switched = false,
    this.note,
  });

  final String url;
  final Song song;
  final bool isAsset;
  final bool switched;
  final String? note;
}

class SearchOutcome {
  const SearchOutcome({required this.songs, required this.errors});

  final List<Song> songs;
  final Map<String, String> errors;
}

abstract class MusicSource {
  String get id;
  String get label;
  String get description;
  Color get color;
  bool get supportsStreaming;

  Future<List<Song>> search(String keyword, {int limit = 20});

  Future<String> resolveStream(Song song, {AudioQuality quality = AudioQuality.high});

  Future<LyricBundle?> lyrics(Song song) async => null;
}

class SourceDescriptor {
  const SourceDescriptor({
    required this.id,
    required this.label,
    required this.description,
    required this.color,
    required this.streaming,
  });

  final String id;
  final String label;
  final String description;
  final Color color;
  final bool streaming;
}

const sourceDescriptors = <SourceDescriptor>[
  SourceDescriptor(
    id: 'netease',
    label: '网易云音乐',
    description: '全曲库 · 歌词 · 封面',
    color: Color(0xFFEC4141),
    streaming: true,
  ),
  SourceDescriptor(
    id: 'kuwo',
    label: '酷我音乐',
    description: '高可用直链 · 多码率',
    color: Color(0xFFFFB800),
    streaming: true,
  ),
  SourceDescriptor(
    id: 'kugou',
    label: '酷狗音乐',
    description: '海量曲库 · 部分会员',
    color: Color(0xFF2CA2F9),
    streaming: true,
  ),
  SourceDescriptor(
    id: 'qq',
    label: 'QQ 音乐',
    description: '正版曲库 · 需会员资源',
    color: Color(0xFF31C27C),
    streaming: true,
  ),
  SourceDescriptor(
    id: 'migu',
    label: '咪咕音乐',
    description: '搜索与元数据 · 自动换源',
    color: Color(0xFFE6006F),
    streaming: false,
  ),
  SourceDescriptor(
    id: 'demo',
    label: 'MuseFlow 录音室',
    description: '离线试听 · 原创示例曲',
    color: AppColors.violet,
    streaming: true,
  ),
];
