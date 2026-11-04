import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/demo_catalog.dart';
import '../../models/song.dart';
import '../../services/download_service.dart';
import '../../services/library_store.dart';
import '../../services/player_service.dart';
import '../actions.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/song_tile.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.onOpenSearch});

  final VoidCallback onOpenSearch;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final player = context.watch<PlayerService>();
    final downloads = context.watch<DownloadService>();
    final compact = MediaQuery.of(context).size.width < 760;
    final padding = compact ? 20.0 : 36.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(padding, compact ? 10 : 22, padding, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                const BrandLockup(compact: true),
                const SizedBox(height: 24),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '音乐库',
                          style: TextStyle(
                            fontFamily: 'InterDisplay',
                            fontSize: compact ? 30 : 38,
                            height: 1.1,
                            letterSpacing: -1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          '收藏、歌单与离线下载，都在这里。',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!compact)
                    PrimaryButton(
                      label: '新建歌单',
                      icon: Icons.add_rounded,
                      height: 40,
                      onPressed: _createPlaylist,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              _TabBar(
                index: _tab,
                onChanged: (index) => setState(() => _tab = index),
                counts: [
                  library.favorites.length,
                  library.playlists.length,
                  library.history.length,
                  library.downloads.length,
                ],
              ),
              const SizedBox(height: 24),
              if (_tab == 0)
                _FavoritesTab(
                  favorites: library.favorites,
                  player: player,
                  onGoSearch: widget.onOpenSearch,
                )
              else if (_tab == 1)
                _PlaylistsTab(
                  library: library,
                  compact: compact,
                  onCreate: _createPlaylist,
                  onOpen: (playlist) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlaylistDetailScreen(playlist: playlist),
                      ),
                    );
                  },
                )
              else if (_tab == 2)
                _HistoryTab(
                  history: library.history,
                  player: player,
                  onGoSearch: widget.onOpenSearch,
                )
              else
                _DownloadsTab(
                  library: library,
                  downloads: downloads,
                  player: player,
                  onGoSearch: widget.onOpenSearch,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final playlist = await createPlaylistDialog(context);
    if (playlist != null && mounted) {
      showToast(context, '已创建「${playlist.name}」');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistDetailScreen(playlist: playlist),
        ),
      );
    }
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onChanged, required this.counts});

  final int index;
  final ValueChanged<int> onChanged;
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    const labels = ['我喜欢的', '我的歌单', '最近播放', '下载'];
    const icons = [
      Icons.favorite_border_rounded,
      Icons.queue_music_rounded,
      Icons.history_rounded,
      Icons.download_done_rounded,
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: index == i ? Colors.white.withOpacity(0.09) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icons[i],
                        size: 14,
                        color: index == i ? Colors.white : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: index == i ? FontWeight.w600 : FontWeight.w500,
                          color: index == i ? Colors.white : AppColors.textTertiary,
                        ),
                      ),
                      if (counts[i] > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${counts[i]}',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: index == i ? AppColors.mint : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab({
    required this.favorites,
    required this.player,
    required this.onGoSearch,
  });

  final List<Song> favorites;
  final PlayerService player;
  final VoidCallback onGoSearch;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border_rounded,
        title: '还没有喜欢的音乐',
        message: '在歌曲上点一下爱心，它们就会出现在这里。',
        action: '去发现音乐',
        onAction: onGoSearch,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('我喜欢的音乐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text(
              '${favorites.length} 首',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
            ),
            const Spacer(),
            PrimaryButton(
              label: '播放全部',
              icon: Icons.play_arrow_rounded,
              height: 38,
              onPressed: () => player.playQueue(favorites),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              for (var i = 0; i < favorites.length; i++)
                SongTile(
                  song: favorites[i],
                  index: i + 1,
                  showCover: true,
                  showSource: true,
                  isCurrent: player.current?.uid == favorites[i].uid,
                  isPlaying: player.isPlaying,
                  onTap: () => playSong(context, favorites[i], queue: favorites, index: i),
                  onMore: () => showSongMenu(context, favorites[i], queue: favorites, index: i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab({
    required this.library,
    required this.compact,
    required this.onCreate,
    required this.onOpen,
  });

  final LibraryStore library;
  final bool compact;
  final VoidCallback onCreate;
  final ValueChanged<Playlist> onOpen;

  @override
  Widget build(BuildContext context) {
    final playlists = library.playlists;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('我的歌单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            GhostButton(
              label: '新建歌单',
              icon: Icons.add_rounded,
              height: 34,
              onPressed: onCreate,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = compact ? 2 : (constraints.maxWidth > 900 ? 4 : 3);
            const spacing = 16.0;
            final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: width,
                  child: _CreatePlaylistCard(onTap: onCreate, height: width),
                ),
                for (final playlist in playlists)
                  SizedBox(
                    width: width,
                    child: PlaylistCard(
                      playlist: playlist,
                      width: width,
                      onTap: () => onOpen(playlist),
                      onPlay: playlist.songs.isEmpty
                          ? null
                          : () => context.read<PlayerService>().playQueue(playlist.songs),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        const Text('MuseFlow 精选', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: editorialPlaylists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final playlist = editorialPlaylists[index];
              return PlaylistCard(
                playlist: playlist,
                width: compact ? 156 : 182,
                onTap: () => onOpen(playlist),
                onPlay: () => context.read<PlayerService>().playQueue(playlist.songs),
              );
            },
          ),
        ),
        if (playlists.isEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            '本地歌单会保存在这台设备上，随时可以编辑。',
            style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }
}

class _CreatePlaylistCard extends StatefulWidget {
  const _CreatePlaylistCard({required this.onTap, required this.height});

  final VoidCallback onTap;
  final double height;

  @override
  State<_CreatePlaylistCard> createState() => _CreatePlaylistCardState();
}

class _CreatePlaylistCardState extends State<_CreatePlaylistCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.height + 58,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_hover ? 0.05 : 0.025),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: _hover ? AppColors.violet.withOpacity(0.4) : AppColors.line,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violet.withOpacity(0.12),
                  border: Border.all(color: AppColors.violet.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.violetSoft, size: 22),
              ),
              const SizedBox(height: 12),
              const Text(
                '新建歌单',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                '收集你的私人歌单',
                style: TextStyle(fontSize: 9.5, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.history, required this.player, required this.onGoSearch});

  final List<Song> history;
  final PlayerService player;
  final VoidCallback onGoSearch;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        title: '还没有播放记录',
        message: '听过的歌曲会自动出现在这里，最多保留 50 首。',
        action: '去听歌',
        onAction: onGoSearch,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('最近播放', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.read<LibraryStore>().clearHistory(),
              icon: const Icon(Icons.delete_sweep_outlined, size: 15),
              label: const Text('清空记录', style: TextStyle(fontSize: 10.5)),
              style: TextButton.styleFrom(foregroundColor: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              for (var i = 0; i < history.length; i++)
                SongTile(
                  song: history[i],
                  index: i + 1,
                  showCover: true,
                  showSource: true,
                  isCurrent: player.current?.uid == history[i].uid,
                  isPlaying: player.isPlaying,
                  onTap: () => playSong(context, history[i], queue: history, index: i),
                  onMore: () => showSongMenu(context, history[i], queue: history, index: i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab({
    required this.library,
    required this.downloads,
    required this.player,
    required this.onGoSearch,
  });

  final LibraryStore library;
  final DownloadService downloads;
  final PlayerService player;
  final VoidCallback onGoSearch;

  Song _localSong(DownloadedTrack track) {
    return track.song.copyWith(extra: {...track.song.extra, 'file': track.path});
  }

  @override
  Widget build(BuildContext context) {
    if (library.downloads.isEmpty) {
      return EmptyState(
        icon: Icons.download_for_offline_outlined,
        title: '暂无离线歌曲',
        message: downloads.isSupported
            ? '在歌曲菜单中选择「下载到本地」，即可离线畅听。'
            : 'Web 端不支持离线下载，使用 App 或桌面端即可缓存歌曲。',
        action: '去发现音乐',
        onAction: onGoSearch,
      );
    }
    final songs = library.downloads.map(_localSong).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('离线下载', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text(
              '${library.downloads.length} 首',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
            ),
            const Spacer(),
            PrimaryButton(
              label: '播放全部',
              icon: Icons.play_arrow_rounded,
              height: 36,
              onPressed: () => player.playQueue(songs),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final track in library.downloads)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              radius: AppRadii.md,
              child: SongTile(
                song: _localSong(track),
                showCover: true,
                dense: true,
                onTap: () {
                  final index = library.downloads.indexOf(track);
                  playSong(context, _localSong(track), queue: songs, index: index);
                },
                trailing: IconButton(
                  onPressed: () => _confirmDelete(context, track),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  color: AppColors.textTertiary,
                  tooltip: '删除下载',
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.folder_outlined, size: 13, color: AppColors.textTertiary),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                '文件保存在应用文档目录/MuseFlow/Downloads',
                style: TextStyle(fontSize: 9.5, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, DownloadedTrack track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除下载文件？'),
        content: Text(
          '将从本机删除《${track.song.name}》，收藏记录不受影响。',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await downloads.remove(track);
      if (context.mounted) showToast(context, '已删除本地文件');
    }
  }
}
