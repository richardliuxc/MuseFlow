import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/song.dart';
import '../../services/library_store.dart';
import '../../services/player_service.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/common.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});

  final Playlist playlist;

  Playlist _currentPlaylist(BuildContext context) {
    final library = context.watch<LibraryStore>();
    for (final item in library.playlists) {
      if (item.id == playlist.id) return item;
    }
    return playlist;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentPlaylist(context);
    final library = context.watch<LibraryStore>();
    final isUserPlaylist = library.playlists.any((item) => item.id == playlist.id);
    final width = MediaQuery.of(context).size.width;
    final compact = width < 760;
    final songs = current.songs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.violet.withOpacity(0.12),
                    AppColors.background,
                    AppColors.background,
                  ],
                  stops: const [0, 0.35, 1],
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
                        '歌单',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      if (isUserPlaylist)
                        CircleIconButton(
                          icon: Icons.more_horiz_rounded,
                          tooltip: '歌单设置',
                          onTap: () => _showPlaylistMenu(context, current),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(compact ? 20 : 40, 14, compact ? 20 : 40, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (compact)
                              Column(
                                children: [
                                  Artwork(
                                    url: current.artwork,
                                    size: 210,
                                    radius: 24,
                                    seed: current.name,
                                    glow: true,
                                  ),
                                  const SizedBox(height: 20),
                                  _PlaylistInfo(
                                    playlist: current,
                                    isUserPlaylist: isUserPlaylist,
                                    compact: true,
                                  ),
                                ],
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Artwork(
                                    url: current.artwork,
                                    size: 210,
                                    radius: 24,
                                    seed: current.name,
                                    glow: true,
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(
                                    child: _PlaylistInfo(
                                      playlist: current,
                                      isUserPlaylist: isUserPlaylist,
                                      compact: false,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 26),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                PrimaryButton(
                                  label: '播放全部',
                                  icon: Icons.play_arrow_rounded,
                                  onPressed: songs.isEmpty
                                      ? null
                                      : () {
                                          context.read<PlayerService>().playQueue(songs);
                                          openPlayerScreen(context);
                                        },
                                ),
                                GhostButton(
                                  label: '随机播放',
                                  icon: Icons.shuffle_rounded,
                                  onPressed: songs.isEmpty
                                      ? null
                                      : () {
                                          context
                                              .read<PlayerService>()
                                              .playQueue(shuffledCopy(songs));
                                          openPlayerScreen(context);
                                        },
                                ),
                                if (isUserPlaylist)
                                  GhostButton(
                                    label: '添加歌曲',
                                    icon: Icons.add_rounded,
                                    onPressed: () => showToast(context, '可在搜索结果或播放器中添加歌曲'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Text(
                                  '歌曲列表',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${songs.length} 首',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const Spacer(),
                                if (isUserPlaylist && songs.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () => _confirmDelete(context, current),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                                    label: const Text('删除歌单', style: TextStyle(fontSize: 11)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.textTertiary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (songs.isEmpty)
                              EmptyState(
                                icon: Icons.queue_music_rounded,
                                title: '歌单还是空的',
                                message: '在搜索或播放器中点击「…」，把喜欢的歌加进来。',
                                action: '去搜索',
                                onAction: () {
                                  Navigator.pop(context);
                                },
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
                                        showCover: false,
                                        showSource: true,
                                        onTap: () =>
                                            playSong(context, songs[i], queue: songs, index: i),
                                        onMore: () => showSongMenu(
                                          context,
                                          songs[i],
                                          queue: songs,
                                          index: i,
                                          onRemove: isUserPlaylist
                                              ? () async {
                                                  await library.removeFromPlaylist(
                                                    current.id,
                                                    songs[i],
                                                  );
                                                  if (context.mounted) {
                                                    showToast(context, '已从歌单移除');
                                                  }
                                                }
                                              : null,
                                        ),
                                      ),
                                  ],
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

  Future<void> _showPlaylistMenu(BuildContext context, Playlist playlist) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, size: 19),
                  title: const Text('重命名歌单', style: TextStyle(fontSize: 13.5)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _rename(context, playlist);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.danger),
                  title: const Text(
                    '删除歌单',
                    style: TextStyle(fontSize: 13.5, color: AppColors.danger),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDelete(context, playlist);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rename(BuildContext context, Playlist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名歌单'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(counterText: '', hintText: '歌单名称'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      await context.read<LibraryStore>().renamePlaylist(playlist.id, name);
      if (context.mounted) showToast(context, '已重命名');
    }
  }

  Future<void> _confirmDelete(BuildContext context, Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除歌单？'),
        content: Text(
          '「${playlist.name}」将从本地移除，歌曲不会从收藏中删除。',
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
      await context.read<LibraryStore>().deletePlaylist(playlist.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _PlaylistInfo extends StatelessWidget {
  const _PlaylistInfo({
    required this.playlist,
    required this.isUserPlaylist,
    required this.compact,
  });

  final Playlist playlist;
  final bool isUserPlaylist;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            isUserPlaylist ? '我的歌单 · LOCAL' : 'MUSEFLOW · CURATED',
            style: const TextStyle(
              fontSize: 8,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          playlist.name,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontFamily: 'InterDisplay',
            fontSize: compact ? 30 : 44,
            height: 1.1,
            letterSpacing: -1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          playlist.description.isEmpty ? '这是一张属于你的歌单。' : playlist.description,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 12, height: 1.7, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Artwork(
              url: playlist.artwork,
              size: 20,
              radius: 6,
              seed: playlist.name,
            ),
            const SizedBox(width: 7),
            Text(
              '${playlist.songs.length} 首 · ${formatMs(playlist.totalDurationMs)}',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
            ),
            const SizedBox(width: 10),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              playlist.createdAt == 0
                  ? '由编辑部精选'
                  : formatDate(DateTime.fromMillisecondsSinceEpoch(playlist.createdAt)),
              style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}
