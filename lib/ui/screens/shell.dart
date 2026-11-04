import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/showcase.dart';
import '../../core/theme.dart';
import '../../data/demo_catalog.dart';
import '../../models/song.dart';
import '../../services/library_store.dart';
import '../../services/player_service.dart';
import '../../services/settings_store.dart';
import '../actions.dart';
import '../widgets/common.dart';
import '../widgets/mini_player.dart';
import '../widgets/now_playing_rail.dart';
import '../widgets/sidebar.dart';
import 'charts_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'playlist_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  late final PlayerService _player;
  int _lastNotice = 0;

  @override
  void initState() {
    super.initState();
    _player = context.read<PlayerService>();
    _player.addListener(_onPlayerUpdate);
    if (showcaseMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runShowcase());
    }
  }

  Future<void> _runShowcase() async {
    final preview = Uri.base.queryParameters['preview'];
    if (preview == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    if (preview == 'search') {
      setState(() => _tab = 1);
      return;
    }
    if (preview == 'library') {
      final library = context.read<LibraryStore>();
      if (library.playlists.isEmpty) {
        await library.createPlaylist(
          name: '夜色收藏',
          description: '深夜循环的 8 首歌，给还没睡的你。',
          cover: demoTracks.first.cover,
          songs: demoTracks,
        );
      }
      for (var i = 0; i < 3; i++) {
        if (!library.isFavorite(demoTracks[i])) {
          await library.toggleFavorite(demoTracks[i]);
        }
      }
      if (mounted) setState(() => _tab = 2);
      return;
    }
    if (preview == 'playlist') {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistDetailScreen(playlist: editorialPlaylists.first),
        ),
      );
      return;
    }
    if (preview == 'charts') {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChartsScreen(initialChart: demoCharts.first),
        ),
      );
      return;
    }
    if (preview == 'player') {
      await _player.playQueue(demoTracks, autoPlay: true);
      if (!mounted) return;
      openPlayerScreen(context);
    }
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  void _onPlayerUpdate() {
    if (!mounted) return;
    if (_player.noticeSeq == _lastNotice) return;
    _lastNotice = _player.noticeSeq;
    final notice = _player.notice;
    if (notice == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showToast(context, notice);
      _player.clearNotice();
    });
  }

  void _setTab(int value) {
    if (value == _tab) return;
    setState(() => _tab = value);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final player = context.watch<PlayerService>();
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1000;
    final showRail = width >= 1280;

    final screens = <Widget>[
      HomeScreen(onOpenSearch: () => _setTab(1)),
      const SearchScreen(),
      LibraryScreen(onOpenSearch: () => _setTab(0)),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: compact
              ? Column(
                  children: [
                    Expanded(child: IndexedStack(index: _tab, children: screens)),
                    if (player.hasTrack) const MiniPlayer(compact: true),
                    _MobileNav(tab: _tab, onTab: _setTab),
                  ],
                )
              : Row(
                  children: [
                    Sidebar(tab: _tab, onTab: _setTab),
                    Expanded(
                      child: Column(
                        children: [
                          _DesktopTopBar(
                            onSearch: () => _setTab(1),
                            onProfile: () => _setTab(3),
                            quality: settings.quality.shortLabel,
                          ),
                          Expanded(
                            child: IndexedStack(index: _tab, children: screens),
                          ),
                          if (player.hasTrack) const MiniPlayer(),
                        ],
                      ),
                    ),
                    if (showRail) const NowPlayingRail(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.onSearch,
    required this.onProfile,
    required this.quality,
  });

  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final String quality;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<LibraryStore>().history;
    return Container(
      height: 66,
      padding: const EdgeInsets.fromLTRB(36, 12, 30, 0),
      child: Row(
        children: [
          InkWell(
            onTap: onSearch,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Container(
              width: 280,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.line),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, size: 16, color: AppColors.textTertiary),
                  SizedBox(width: 9),
                  Text(
                    '搜索音乐、歌手或专辑',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mint.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq_rounded, size: 11, color: AppColors.mint),
                const SizedBox(width: 5),
                Text(
                  quality,
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          CircleIconButton(
            icon: Icons.notifications_none_rounded,
            size: 36,
            iconSize: 18,
            tooltip: '通知',
            onTap: () => showToast(
              context,
              history.isEmpty ? '还没有播放记录，去发现页听一首吧' : '最近听过：${history.first.name}',
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onProfile,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.aurora,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    fontFamily: 'InterDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF071018),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.explore_outlined, Icons.explore_rounded, '发现'),
      (Icons.search_rounded, Icons.search_rounded, '搜索'),
      (Icons.library_music_outlined, Icons.library_music_rounded, '音乐库'),
      (Icons.person_outline_rounded, Icons.person_rounded, '我的'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft.withOpacity(0.96),
        border: const Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTab(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                            decoration: BoxDecoration(
                              color: tab == i ? Colors.white.withOpacity(0.08) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tab == i ? items[i].$2 : items[i].$1,
                              size: 21,
                              color: tab == i ? AppColors.mint : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].$3,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: tab == i ? FontWeight.w600 : FontWeight.w400,
                              color: tab == i ? AppColors.textPrimary : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
