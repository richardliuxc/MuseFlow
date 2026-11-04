import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/demo_catalog.dart';
import '../../models/song.dart';
import '../../services/music_repository.dart';
import '../../services/player_service.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/common.dart';
import '../widgets/song_tile.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({
    super.key,
    required this.initialChart,
    this.initialSongs = const [],
  });

  final ChartSummary initialChart;
  final List<Song> initialSongs;

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late int _index;
  final Map<String, List<Song>> _cache = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _index = demoCharts.indexWhere((chart) => chart.id == widget.initialChart.id);
    if (_index < 0) _index = 0;
    if (widget.initialSongs.isNotEmpty) {
      _cache[widget.initialChart.id] = widget.initialSongs;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  Future<void> _ensureLoaded() async {
    final chart = demoCharts[_index];
    if (_cache.containsKey(chart.id) && _cache[chart.id]!.isNotEmpty) return;
    setState(() => _loading = true);
    final songs = await context.read<MusicRepository>().chartSongs(chart.id);
    if (!mounted) return;
    setState(() {
      _cache[chart.id] = songs;
      _loading = false;
    });
  }

  void _select(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    _ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final chart = demoCharts[_index];
    final songs = _cache[chart.id] ?? const <Song>[];
    final compact = MediaQuery.of(context).size.width < 760;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    chart.colors.first.withOpacity(0.16),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: '返回',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '排行榜',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.update_rounded, size: 12, color: AppColors.textTertiary),
                            SizedBox(width: 5),
                            Text(
                              '实时更新',
                              style: TextStyle(fontSize: 9.5, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(compact ? 20 : 40, 16, compact ? 20 : 40, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ChartHero(
                              chart: chart,
                              songs: songs,
                              compact: compact,
                              onPlay: songs.isEmpty
                                  ? null
                                  : () {
                                      context.read<PlayerService>().playQueue(songs);
                                      openPlayerScreen(context);
                                    },
                            ),
                            const SizedBox(height: 22),
                            _ChartTabs(selected: _index, onSelect: _select),
                            const SizedBox(height: 18),
                            if (_loading)
                              const SizedBox(
                                height: 240,
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else
                              GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < songs.length; i++)
                                      SongTile(
                                        song: songs[i],
                                        index: i + 1,
                                        showNumber: true,
                                        showCover: true,
                                        showSource: true,
                                        isCurrent:
                                            context.watch<PlayerService>().current?.uid == songs[i].uid,
                                        isPlaying: context.read<PlayerService>().isPlaying,
                                        onTap: () =>
                                            playSong(context, songs[i], queue: songs, index: i),
                                        onMore: () =>
                                            showSongMenu(context, songs[i], queue: songs, index: i),
                                      ),
                                  ],
                                ),
                              ),
                            if (songs.isNotEmpty && songs.first.isDemo) ...[
                              const SizedBox(height: 14),
                              const Center(
                                child: Text(
                                  '当前展示离线示例榜单 · 联网后将自动同步真实热歌',
                                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            const Center(
                              child: Text(
                                '榜单数据来自公开接口 · 每小时更新',
                                style: TextStyle(fontSize: 9.5, color: AppColors.textTertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartHero extends StatelessWidget {
  const _ChartHero({
    required this.chart,
    required this.songs,
    required this.compact,
    required this.onPlay,
  });

  final ChartSummary chart;
  final List<Song> songs;
  final bool compact;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final covers = songs.take(3).map((song) => song.cover).where((c) => c.isNotEmpty).toList();
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            chart.colors.first.withOpacity(0.3),
            AppColors.surface.withOpacity(0.8),
            chart.colors.last.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: chart.colors.first.withOpacity(0.26)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MUSEFLOW CHARTS',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w600,
                    color: chart.colors.first.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chart.name,
                  style: TextStyle(
                    fontFamily: 'InterDisplay',
                    fontSize: compact ? 28 : 38,
                    height: 1.1,
                    letterSpacing: -0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${chart.tag} · ${songs.isEmpty ? '加载中' : '${songs.length} 首' }',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: '播放榜单',
                  icon: Icons.play_arrow_rounded,
                  height: 40,
                  onPressed: onPlay,
                ),
              ],
            ),
          ),
          if (!compact && covers.isNotEmpty)
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < covers.length; i++)
                    Positioned(
                      left: i * 22.0,
                      top: i * 10.0,
                      child: Transform.rotate(
                        angle: (i - 1) * 0.08,
                        child: Artwork(
                          url: covers[i],
                          size: 108,
                          radius: 16,
                          seed: covers[i],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartTabs extends StatelessWidget {
  const _ChartTabs({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < demoCharts.length; i++)
            GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: selected == i ? Colors.white.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  demoCharts[i].name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected == i ? FontWeight.w600 : FontWeight.w500,
                    color: selected == i ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
