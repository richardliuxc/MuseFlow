import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/song.dart';

/// An original, royalty-free catalogue synthesised for MuseFlow.
///
/// It powers the first-run experience, offline playback and the Web preview,
/// while real platform sources are queried in parallel for the live library.
const String demoAlbum = 'Aurora Sessions';

const List<Song> demoTracks = [
  Song(
    id: 'demo_01',
    source: 'demo',
    name: '潮汐',
    artist: 'LUMA',
    album: demoAlbum,
    cover: 'assets/images/covers/cover_01.jpg',
    durationMs: 44700,
    bitrate: 160,
    extra: {'asset': 'assets/audio/demo_01.mp3', 'genre': 'Chillwave', 'mood': 'chill'},
  ),
  Song(
    id: 'demo_02',
    source: 'demo',
    name: '夜航',
    artist: 'ASTER',
    album: demoAlbum,
    cover: 'assets/images/covers/cover_02.jpg',
    durationMs: 41400,
    bitrate: 160,
    extra: {'asset': 'assets/audio/demo_02.mp3', 'genre': 'Dream Pop', 'mood': 'night'},
  ),
  Song(
    id: 'demo_03',
    source: 'demo',
    name: '玻璃海',
    artist: 'NOVA',
    album: demoAlbum,
    cover: 'assets/images/covers/cover_03.jpg',
    durationMs: 43000,
    bitrate: 160,
    extra: {'asset': 'assets/audio/demo_03.mp3', 'genre': 'Ambient', 'mood': 'focus'},
  ),
  Song(
    id: 'demo_04',
    source: 'demo',
    name: '极光信笺',
    artist: 'KISARAGI',
    album: demoAlbum,
    cover: 'assets/images/covers/cover_04.jpg',
    durationMs: 47600,
    bitrate: 160,
    extra: {'asset': 'assets/audio/demo_04.mp3', 'genre': 'Downtempo', 'mood': 'focus'},
  ),
  Song(
    id: 'demo_05',
    source: 'demo',
    name: '霓虹雨',
    artist: 'MONO',
    album: demoAlbum,
    cover: 'assets/images/covers/cover_05.jpg',
    durationMs: 37900,
    bitrate: 160,
    extra: {'asset': 'assets/audio/demo_05.mp3', 'genre': 'Synthwave', 'mood': 'night'},
  ),
  Song(
    id: 'demo_06',
    source: 'demo',
    name: '慢速星球',
    artist: 'LUMA',
    album: demoAlbum,
    cover: 'assets/images/covers/cover_06.jpg',
    durationMs: 44100,
    bitrate: 160,
    extra: {'asset': 'assets/audio/demo_06.mp3', 'genre': 'Lo-Fi', 'mood': 'chill'},
  ),
  Song(
    id: 'demo_07',
    source: 'demo',
    name: '晨雾',
    artist: 'ASTER',
    album: demoAlbum,
    cover: 'assets/images/covers/cover_07.jpg',
    durationMs: 51000,
    bitrate: 160,
    extra: {'asset': 'assets/audio/demo_07.mp3', 'genre': 'Acoustic', 'mood': 'morning'},
  ),
  Song(
    id: 'demo_08',
    source: 'demo',
    name: '失重',
    artist: 'NOVA',
    album: demoAlbum,
    cover: 'assets/images/covers/cover_08.jpg',
    durationMs: 43700,
    bitrate: 160,
    extra: {'asset': 'assets/audio/demo_08.mp3', 'genre': 'Electronic', 'mood': 'energy'},
  ),
];

Song demoById(String id) => demoTracks.firstWhere(
      (song) => song.id == id,
      orElse: () => demoTracks.first,
    );

const Map<String, String> demoLyrics = {
  'demo_01': '''[00:00.00]潮汐 · Tides
[00:06.20]海面把月光揉成一片银
[00:14.80]风从很远的地方赶来
[00:23.60]我们站在退潮之后的岸边
[00:32.40]听见世界缓慢的呼吸
[00:40.00]让声音，替你抵达远方''',
  'demo_02': '''[00:00.00]夜航 · Night Flight
[00:05.60]城市在云层下面发光
[00:13.20]像一封没有寄出的信
[00:21.80]机翼掠过沉默的星群
[00:30.20]我把心事调到静音
[00:37.60]晚安，未眠的人''',
  'demo_03': '''[00:00.00]玻璃海 · Glass Sea
[00:07.40]光落在透明的浪上
[00:16.60]每一次呼吸都有回声
[00:25.80]时间在这里变得很慢
[00:35.20]慢到可以听见自己
[00:41.00]纯音乐 · 请闭上眼睛''',
  'demo_04': '''[00:00.00]极光信笺 · Aurora Letters
[00:06.80]绿色的光写下第一行
[00:15.40]紫色的风翻过下一页
[00:24.20]北纬六十六度的夜里
[00:33.60]所有远方都有了回音
[00:42.00]写给未来的你''',
  'demo_05': '''[00:00.00]霓虹雨 · Neon Rain
[00:04.60]雨滴落在霓虹的缝隙
[00:11.80]出租车拖着光尾远去
[00:19.40]凌晨两点的便利店
[00:26.60]收留所有醒着的心
[00:33.20]再跳一支舞吧''',
  'demo_06': '''[00:00.00]慢速星球 · Slow Planet
[00:07.20]把时钟拨慢一点
[00:15.00]让咖啡再凉得慢一点
[00:23.40]窗外的云停在天台
[00:31.60]今天不需要去任何地方
[00:38.80]就这样，刚刚好''',
  'demo_07': '''[00:00.00]晨雾 · Morning Mist
[00:08.00]雾从山谷里慢慢升起
[00:17.20]鸟鸣替清晨按下播放键
[00:26.40]昨夜的梦还没散场
[00:35.80]阳光已经在路上
[00:44.00]新的一天，慢一点也没关系''',
  'demo_08': '''[00:00.00]失重 · Zero-G
[00:05.20]关掉重力，向上漂浮
[00:12.60]城市变成一粒微光
[00:20.00]心跳是唯一的节拍器
[00:27.40]在你我之间的真空里
[00:34.60]自由从来没有声音''',
};

final List<Playlist> editorialPlaylists = [
  Playlist(
    id: 'ed_aurora',
    name: '极光之下',
    description: '在冷调的合成器里，重新听见自己。',
    cover: 'assets/images/covers/cover_04.jpg',
    songs: [demoTracks[3], demoTracks[2], demoTracks[0], demoTracks[6]],
    isEditorial: true,
  ),
  const Playlist(
    id: 'ed_night',
    name: '深夜驾驶',
    description: '城市退后，霓虹向前。给夜行者的 8 首歌。',
    cover: 'assets/images/covers/cover_02.jpg',
    songs: demoTracks,
    isEditorial: true,
  ),
  Playlist(
    id: 'ed_glass',
    name: '玻璃海',
    description: '透明、辽阔、没有边界的氛围电子。',
    cover: 'assets/images/covers/cover_03.jpg',
    songs: [demoTracks[2], demoTracks[3], demoTracks[7], demoTracks[0]],
    isEditorial: true,
  ),
  Playlist(
    id: 'ed_morning',
    name: '晨间仪式',
    description: '咖啡、日光和一点恰到好处的松弛。',
    cover: 'assets/images/covers/cover_07.jpg',
    songs: [demoTracks[6], demoTracks[5], demoTracks[3], demoTracks[1]],
    isEditorial: true,
  ),
  Playlist(
    id: 'ed_focus',
    name: '专注心流',
    description: '不打扰的背景音，陪你进入深度工作。',
    cover: 'assets/images/covers/cover_08.jpg',
    songs: [demoTracks[7], demoTracks[3], demoTracks[2], demoTracks[5]],
    isEditorial: true,
  ),
];

const Map<String, List<String>> moodTracks = {
  'chill': ['demo_01', 'demo_06'],
  'night': ['demo_02', 'demo_05', 'demo_01'],
  'focus': ['demo_03', 'demo_04', 'demo_08'],
  'morning': ['demo_07', 'demo_06'],
  'energy': ['demo_08', 'demo_05'],
};

final List<ChartSummary> demoCharts = [
  const ChartSummary(
    id: 'hot',
    name: 'MuseFlow 热歌榜',
    tag: '每天 12:00 更新',
    colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
    songs: demoTracks,
  ),
  ChartSummary(
    id: 'new',
    name: '新声速递',
    tag: '本周新歌',
    colors: const [Color(0xFFF472B6), Color(0xFF8B5CF6)],
    songs: [demoTracks[7], demoTracks[5], demoTracks[2], demoTracks[6]],
  ),
  ChartSummary(
    id: 'rising',
    name: '独立飙升',
    tag: '独立音乐人',
    colors: const [Color(0xFF34D399), Color(0xFF0EA5E9)],
    songs: [demoTracks[1], demoTracks[4], demoTracks[0], demoTracks[3]],
  ),
];

const List<String> hotSearches = [
  '晴天',
  '起风了',
  '周杰伦',
  '孤勇者',
  '林俊杰',
  '陈奕迅',
  '五月天',
  '邓紫棋',
  '告五人',
  'Taylor Swift',
];

const List<String> discoverTags = [
  '流行',
  '华语',
  '电子',
  '摇滚',
  '民谣',
  '爵士',
  '古典',
  'Lo-Fi',
  '氛围',
  '粤语',
];

Color moodColor(String mood) => switch (mood) {
      'chill' => AppColors.cyan,
      'night' => AppColors.violet,
      'focus' => AppColors.mint,
      'morning' => AppColors.amber,
      'energy' => AppColors.pink,
      _ => AppColors.violet,
    };
