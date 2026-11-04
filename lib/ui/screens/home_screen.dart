import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/demo_catalog.dart';
import '../../models/radio_station.dart';
import '../../models/song.dart';
import '../../services/library_store.dart';
import '../../services/music_repository.dart';
import '../../services/player_service.dart';
import '../../services/radio_repository.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/radio_cards.dart';
import '../widgets/song_tile.dart';
import 'charts_screen.dart';
import 'playlist_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key, required this.onOpenSearch, required this.onOpenRadio});

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenRadio;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Song>> _dailyFuture;
  late final Future<List<Song>> _trendingFuture;
  late final Future<List<RadioStation>> _radioFuture;

  @override
  void initState() {
    super.initState();
    final repository = context.read<MusicRepository>();
    _dailyFuture = repository.dailyMix();
    _trendingFuture = repository.chartSongs('hot');
    _radioFuture = context.read<RadioRepository>().featured();
  }

  void _openPlaylist(Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _openChart(ChartSummary chart, List<Song> songs) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChartsScreen(initialChart: chart, initialSongs: songs),
      ),
    );
  }

  void _playRadio(List<RadioStation> list, RadioStation station) {
    final songs = list.map((item) => item.toSong()).toList();
    final index = list.indexOf(station);
    context
        .read<PlayerService>()
        .playQueue(songs, startIndex: index < 0 ? 0 : index);
  }

  void _playPlaylist(Playlist playlist) {
    if (playlist.songs.isEmpty) return;
    context.read<PlayerService>().playQueue(playlist.songs);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final history = library.history;
    final player = context.watch<PlayerService>();

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 880;
      final padding = compact ? 20.0 : 36.0;
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              padding, compact ? 8 : 16, padding, compact ? 24 : 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compact) ...[
                    const BrandLockup(compact: true),
                    const SizedBox(height: 26),
                  ],
                  _Greeting(
                      compact: compact, onOpenSearch: widget.onOpenSearch),
                  const SizedBox(height: 22),
                  if (compact) ...[
                    _SearchEntry(onTap: widget.onOpenSearch),
                    const SizedBox(height: 22),
                  ],
                  _Hero(
                    compact: compact,
                    playlist: editorialPlaylists.first,
                    onPlay: () => _playPlaylist(editorialPlaylists.first),
                    onOpen: () => _openPlaylist(editorialPlaylists.first),
                  ),
                  const SizedBox(height: 34),
                  SectionHeader(
                    title: '为你推荐',
                    subtitle: '编辑精选 · 按你的口味挑选',
                    action: '全部歌单',
                    onAction: () => showToast(context, '更多歌单正在路上'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: compact ? 232 : 258,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: editorialPlaylists.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: compact ? 14 : 18),
                      itemBuilder: (context, index) {
                        final playlist = editorialPlaylists[index];
                        return PlaylistCard(
                          playlist: playlist,
                          width: compact ? 162 : 196,
                          onTap: () => _openPlaylist(playlist),
                          onPlay: () => _playPlaylist(playlist),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 34),
                  FutureBuilder<List<RadioStation>>(
                    future: _radioFuture,
                    builder: (context, snapshot) {
                      final featured = (snapshot.data ?? const <RadioStation>[])
                          .take(6)
                          .toList();
                      if (featured.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: '世界广播',
                            subtitle: '来自 190+ 个国家 · 24 小时实时直播',
                            action: '全部电台',
                            onAction: widget.onOpenRadio,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: featured.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final station = featured[index];
                                final song = station.toSong();
                                return SizedBox(
                                  width: compact ? 284 : 310,
                                  child: RadioStationCard(
                                    station: station,
                                    dense: true,
                                    favorite: library.isFavorite(song),
                                    onPlay: () => _playRadio(featured, station),
                                    onFavorite: () async {
                                      await library.toggleFavorite(song);
                                      if (context.mounted) {
                                        showToast(
                                          context,
                                          library.isFavorite(song)
                                              ? '已收藏电台'
                                              : '已取消收藏',
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 34),
                  _DailySection(
                    future: _dailyFuture,
                    compact: compact,
                    onOpen: (playlist) => _openPlaylist(playlist),
                  ),
                  const SizedBox(height: 34),
                  FutureBuilder<List<Song>>(
                    future: _trendingFuture,
                    builder: (context, snapshot) {
                      final songs = snapshot.data ?? const <Song>[];
                      final charts = demoCharts
                          .map((chart) => ChartSummary(
                                id: chart.id,
                                name: chart.name,
                                tag: chart.tag,
                                colors: chart.colors,
                                songs: chart.id == 'hot' && songs.isNotEmpty
                                    ? songs.take(4).toList()
                                    : chart.songs.take(4).toList(),
                              ))
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: '热门榜单',
                            subtitle: '实时热度 · 每天更新',
                            action: '查看全部',
                            onAction: () => _openChart(charts.first, songs),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 216,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: charts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final chart = charts[index];
                                return ChartCard(
                                  chart: chart,
                                  width: compact ? 264 : 300,
                                  onTap: () => _openChart(
                                      chart, index == 0 ? songs : chart.songs),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 34),
                  const SectionHeader(
                    title: '心情电台',
                    subtitle: '此刻的你，适合听点什么？',
                  ),
                  const SizedBox(height: 16),
                  _MoodGrid(compact: compact, onOpen: _openMoodPlaylist),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 34),
                    SectionHeader(
                      title: '最近播放',
                      subtitle: '继续上次没有听完的旋律',
                      action: '清空',
                      onAction: () =>
                          context.read<LibraryStore>().clearHistory(),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Column(
                        children: [
                          for (var i = 0; i < math.min(history.length, 4); i++)
                            SongTile(
                              song: history[i],
                              showCover: true,
                              dense: true,
                              index: i,
                              isCurrent: player.current?.uid == history[i].uid,
                              isPlaying: player.isPlaying,
                              onTap: () =>
                                  playSong(context, history[i], queue: history),
                              onMore: () => showSongMenu(context, history[i],
                                  queue: history, index: i),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'MuseFlow · 音乐属于每一个认真聆听的人\n音源来自公开接口，仅供个人学习研究',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.8,
                        color: AppColors.textTertiary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _openMoodPlaylist(String mood, String title, String subtitle) {
    final ids = moodTracks[mood] ?? const <String>[];
    final songs = ids.map(demoById).toList();
    final playlist = Playlist(
      id: 'mood_$mood',
      name: title,
      description: subtitle,
      cover: songs.isEmpty ? '' : songs.first.cover,
      songs: songs,
      isEditorial: true,
    );
    _openPlaylist(playlist);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.compact, required this.onOpenSearch});

  final bool compact;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${greetingFor(now)}，音乐旅人',
                style: TextStyle(
                  fontFamily: 'InterDisplay',
                  fontSize: compact ? 28 : 36,
                  height: 1.12,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitleFor(now),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (!compact)
          Row(
            children: [
              _DatePill(now: now),
              const SizedBox(width: 12),
              CircleIconButton(
                icon: Icons.search_rounded,
                size: 40,
                tooltip: '搜索',
                onTap: onOpenSearch,
              ),
            ],
          ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(
              now.hour >= 18 || now.hour < 6
                  ? Icons.dark_mode_outlined
                  : Icons.wb_sunny_outlined,
              size: 14,
              color: AppColors.amber),
          const SizedBox(width: 7),
          Text(
            '${now.month} 月 ${now.day} 日 · ${weekdays[now.weekday - 1]}',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.line),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: AppColors.textTertiary),
            SizedBox(width: 10),
            Text(
              '搜索歌曲、歌手、专辑',
              style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.compact,
    required this.playlist,
    required this.onPlay,
    required this.onOpen,
  });

  final bool compact;
  final Playlist playlist;
  final VoidCallback onPlay;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 348.0 : 320.0;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1642), Color(0xFF101A2C), Color(0xFF0B1120)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.violet.withOpacity(0.35),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -160,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withOpacity(0.18),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          if (compact)
            Positioned(
              right: 2,
              top: 40,
              child: Opacity(
                opacity: 0.24,
                child: Transform.rotate(
                  angle: 0.08,
                  child: Artwork(
                    url: playlist.cover,
                    size: 150,
                    radius: 22,
                    seed: playlist.name,
                    glow: true,
                  ),
                ),
              ),
            )
          else
            Positioned(
              right: 18,
              top: 18,
              bottom: 18,
              width: 340,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    bottom: 2,
                    child: Container(
                      width: 152,
                      height: 152,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF262A3A), Color(0xFF0A0B12)],
                        ),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: artworkGradient(playlist.name),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            size: 24,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Transform.rotate(
                      angle: 0.05,
                      child: Artwork(
                        url: playlist.cover,
                        size: 244,
                        radius: 24,
                        seed: playlist.name,
                        glow: true,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: const Text(
                        '5 TRACKS · 24 MIN',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.2,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(compact ? 22 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Text(
                      'MUSEFLOW EDITORIAL · VOL. 24',
                      style: TextStyle(
                        fontSize: 8.5,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 16 : 22),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 230 : 460),
                    child: Text(
                      '在极光之下\n重新听见自己',
                      style: TextStyle(
                        fontFamily: 'InterDisplay',
                        fontSize: compact ? 30 : 42,
                        height: 1.12,
                        letterSpacing: -1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 220 : 400),
                    child: Text(
                      playlist.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      PrimaryButton(
                        label: '立即播放',
                        icon: Icons.play_arrow_rounded,
                        onPressed: onPlay,
                        height: 42,
                      ),
                      GhostButton(
                        label: '查看歌单',
                        icon: Icons.arrow_outward_rounded,
                        onPressed: onOpen,
                        height: 42,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySection extends StatelessWidget {
  const _DailySection({
    required this.future,
    required this.compact,
    required this.onOpen,
  });

  final Future<List<Song>> future;
  final bool compact;
  final ValueChanged<Playlist> onOpen;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return FutureBuilder<List<Song>>(
      future: future,
      builder: (context, snapshot) {
        final songs = snapshot.data ?? const <Song>[];
        final playlist = Playlist(
          id: 'daily_${today.year}${today.month}${today.day}',
          name: '每日推荐',
          description: '根据每日心情与收听偏好，为你挑选的 ${songs.length} 首歌。',
          cover: songs.isEmpty ? '' : songs.first.cover,
          songs: songs,
          isEditorial: true,
        );
        final promo = Container(
          width: compact ? double.infinity : 260,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.mint.withOpacity(0.2),
                AppColors.cyan.withOpacity(0.08),
                AppColors.surface.withOpacity(0.9),
              ],
            ),
            border: Border.all(color: AppColors.mint.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 15, color: AppColors.mint),
                  const SizedBox(width: 6),
                  Text(
                    '每日推荐',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mint.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              if (compact) const SizedBox(height: 20) else const Spacer(),
              Text(
                '${today.day}',
                style: const TextStyle(
                  fontFamily: 'InterDisplay',
                  fontSize: 58,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              Text(
                '${today.month} 月 · ${songs.length} 首精选',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: '播放全部',
                icon: Icons.play_arrow_rounded,
                height: 38,
                onPressed: songs.isEmpty
                    ? null
                    : () => context.read<PlayerService>().playQueue(songs),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onOpen(playlist),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '查看完整推荐 →',
                  style:
                      TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        );

        final list = GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              for (var i = 0; i < songs.length; i++)
                SongTile(
                  song: songs[i],
                  index: i + 1,
                  showNumber: true,
                  showCover: false,
                  dense: true,
                  onTap: () =>
                      playSong(context, songs[i], queue: songs, index: i),
                  onMore: () =>
                      showSongMenu(context, songs[i], queue: songs, index: i),
                ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '每日推荐', subtitle: '每天 00:00 更新 · 只属于今天'),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (compact)
              Column(children: [promo, const SizedBox(height: 14), list])
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    promo,
                    const SizedBox(width: 16),
                    Expanded(child: list),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({required this.compact, required this.onOpen});

  final bool compact;
  final void Function(String mood, String title, String subtitle) onOpen;

  @override
  Widget build(BuildContext context) {
    const moods = [
      ('chill', '松弛时刻', 'Chillwave & Lo-Fi', Icons.waves_rounded),
      ('night', '深夜频率', '为夜行者准备的歌', Icons.nightlight_round),
      ('focus', '深度心流', '专注时的背景音', Icons.self_improvement_rounded),
      ('morning', '晨间苏醒', '从一杯咖啡开始', Icons.wb_sunny_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact ? 2 : 4;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final mood in moods)
              SizedBox(
                width: itemWidth,
                height: 124,
                child: MoodCard(
                  title: mood.$2,
                  subtitle: mood.$3,
                  icon: mood.$4,
                  colors: [moodColor(mood.$1), AppColors.violet],
                  onTap: () => onOpen(mood.$1, mood.$2, mood.$3),
                ),
              ),
          ],
        );
      },
    );
  }
}
