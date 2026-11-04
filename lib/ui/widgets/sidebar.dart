import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/song.dart';
import '../../services/library_store.dart';
import '../../services/player_service.dart';
import '../actions.dart';
import '../screens/charts_screen.dart';
import '../screens/nas_screen.dart';
import '../screens/playlist_detail_screen.dart';
import 'artwork.dart';
import 'common.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.tab,
    required this.onTab,
  });

  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final player = context.watch<PlayerService>();
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 24, 22, 26),
            child: BrandLockup(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(26, 0, 0, 8),
            child: Text(
              '浏览',
              style: TextStyle(
                fontSize: 8.5,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            label: '发现',
            active: tab == 0,
            onTap: () => onTab(0),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            activeIcon: Icons.search_rounded,
            label: '搜索',
            active: tab == 1,
            onTap: () => onTab(1),
          ),
          _NavItem(
            icon: Icons.radio_outlined,
            activeIcon: Icons.radio_rounded,
            label: '广播',
            active: tab == 2,
            onTap: () => onTab(2),
          ),
          _NavItem(
            icon: Icons.library_music_outlined,
            activeIcon: Icons.library_music_rounded,
            label: '音乐库',
            active: tab == 3,
            onTap: () => onTab(3),
          ),
          _NavItem(
            icon: Icons.cloud_queue_outlined,
            activeIcon: Icons.cloud_queue_rounded,
            label: '本地网络',
            active: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NasScreen()),
              );
            },
          ),
          _NavItem(
            icon: Icons.leaderboard_outlined,
            activeIcon: Icons.leaderboard_rounded,
            label: '排行榜',
            active: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChartsScreen(initialChart: demoChartSummary()),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 18, 8),
            child: Row(
              children: [
                const Text(
                  '我的歌单',
                  style: TextStyle(
                    fontSize: 8.5,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    final playlist = await createPlaylistDialog(context);
                    if (playlist != null && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlaylistDetailScreen(playlist: playlist),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.add_rounded, size: 15, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: library.playlists.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '还没有歌单\n点击 + 创建你的第一张歌单',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.7,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: library.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = library.playlists[index];
                      return _PlaylistLink(
                        playlist: playlist,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlaylistDetailScreen(playlist: playlist),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          if (player.hasTrack)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SidebarNowPlaying(player: player),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
            child: InkWell(
              onTap: () => onTab(4),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.aurora,
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            fontFamily: 'InterDisplay',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF071018),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '音乐旅人',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '本地模式 · 已同步',
                            style: TextStyle(fontSize: 8.5, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.settings_outlined, size: 15, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ChartSummary demoChartSummary() {
  return const ChartSummary(
    id: 'hot',
    name: 'MuseFlow 热歌榜',
    tag: '每天 12:00 更新',
    colors: [AppColors.violet, AppColors.cyan],
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? Colors.white.withOpacity(0.055) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 18,
                  color: active ? AppColors.textPrimary : AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (active)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mint,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistLink extends StatelessWidget {
  const _PlaylistLink({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Artwork(url: playlist.artwork, size: 30, radius: 6, seed: playlist.name),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${playlist.songs.length} 首',
                    style: const TextStyle(fontSize: 8.5, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNowPlaying extends StatelessWidget {
  const _SidebarNowPlaying({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final song = player.current!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Artwork(url: song.cover, size: 32, radius: 7, seed: song.uid),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          EqBars(playing: player.isPlaying, size: 13, color: AppColors.mint),
        ],
      ),
    );
  }
}
