import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/song.dart';
import '../services/download_service.dart';
import '../services/library_store.dart';
import '../services/player_service.dart';
import '../services/settings_store.dart';
import 'screens/player_screen.dart';

void showToast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              size: 17,
              color: error ? AppColors.danger : AppColors.mint,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

Future<void> playSong(
  BuildContext context,
  Song song, {
  List<Song>? queue,
  int? index,
}) async {
  final player = context.read<PlayerService>();
  unawaited(player.playSong(song, queue: queue, index: index));
}

Future<void> toggleFavorite(BuildContext context, Song song) async {
  final library = context.read<LibraryStore>();
  final added = await library.toggleFavorite(song);
  if (context.mounted) {
    showToast(context, added ? '已添加到「我喜欢的音乐」' : '已取消收藏');
  }
}

Future<void> downloadSong(BuildContext context, Song song) async {
  if (song.isRadio) {
    showToast(context, '直播电台不支持下载', error: true);
    return;
  }
  final service = context.read<DownloadService>();
  if (!service.isSupported) {
    showToast(context, 'Web 端暂不支持离线下载，请使用 App 或桌面端', error: true);
    return;
  }
  if (service.isDownloaded(song)) {
    showToast(context, '该歌曲已在下载列表中');
    return;
  }
  if (service.isDownloading(song)) {
    showToast(context, '正在下载，请稍候');
    return;
  }
  showToast(context, '开始下载《${song.name}》');
  try {
    await service.download(song);
    if (context.mounted) showToast(context, '《${song.name}》已保存到本地');
  } catch (error) {
    if (context.mounted) showToast(context, '下载失败：$error', error: true);
  }
}

Future<Playlist?> createPlaylistDialog(BuildContext context, {List<Song> songs = const []}) {
  final controller = TextEditingController();
  return showDialog<Playlist>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('新建歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 30,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: '给歌单起个名字',
                counterText: '',
                filled: true,
                fillColor: Color(0x0AFFFFFF),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _submitPlaylist(dialogContext, controller, songs),
            ),
            const SizedBox(height: 10),
            const Text(
              '歌单会保存在本机，可随时添加歌曲。',
              style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => _submitPlaylist(dialogContext, controller, songs),
            child: const Text('创建'),
          ),
        ],
      );
    },
  );
}

Future<void> _submitPlaylist(
  BuildContext context,
  TextEditingController controller,
  List<Song> songs,
) async {
  final name = controller.text.trim();
  if (name.isEmpty) return;
  final library = context.read<LibraryStore>();
  final playlist = await library.createPlaylist(
    name: name,
    songs: songs,
    cover: songs.isNotEmpty ? songs.first.cover : '',
  );
  if (context.mounted) Navigator.pop(context, playlist);
}

Future<void> addSongToPlaylist(BuildContext context, Song song) async {
  final library = context.read<LibraryStore>();
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _SheetShell(
        title: '添加到歌单',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetAction(
              icon: Icons.add_rounded,
              title: '新建歌单',
              subtitle: '创建一个新的本地歌单',
              onTap: () async {
                Navigator.pop(sheetContext);
                final playlist = await createPlaylistDialog(context, songs: [song]);
                if (playlist != null && context.mounted) {
                  showToast(context, '已创建「${playlist.name}」');
                }
              },
            ),
            if (library.playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  '还没有本地歌单，先创建一个吧',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: library.playlists.length,
                itemBuilder: (context, index) {
                  final playlist = library.playlists[index];
                  return _SheetAction(
                    icon: Icons.queue_music_rounded,
                    title: playlist.name,
                    subtitle: '${playlist.songs.length} 首歌曲',
                    onTap: () => Navigator.pop(sheetContext, playlist.id),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
  if (result == null) return;
  if (result == '__create__') return;
  final added = await library.addToPlaylist(result, [song]);
  if (context.mounted) {
    showToast(context, added > 0 ? '已添加到歌单' : '歌曲已在歌单中');
  }
}

void showSongMenu(
  BuildContext context,
  Song song, {
  List<Song>? queue,
  int? index,
  VoidCallback? onRemove,
}) {
  final library = context.read<LibraryStore>();
  final player = context.read<PlayerService>();
  final downloads = context.read<DownloadService>();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final favorite = library.isFavorite(song);
      final downloaded = downloads.isDownloaded(song);
      return _SheetShell(
        title: song.name,
        subtitle: song.artist,
        headerCover: song.cover,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetAction(
              icon: Icons.play_arrow_rounded,
              title: '立即播放',
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(playSong(context, song, queue: queue, index: index));
              },
            ),
            if (player.hasTrack)
              _SheetAction(
                icon: Icons.playlist_play_rounded,
                title: '下一首播放',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await player.addToQueue(song, next: true);
                  if (context.mounted) showToast(context, '已加入播放队列');
                },
              ),
            _SheetAction(
              icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              title: favorite ? '取消收藏' : '收藏到我喜欢',
              onTap: () async {
                Navigator.pop(sheetContext);
                await toggleFavorite(context, song);
              },
            ),
            _SheetAction(
              icon: Icons.playlist_add_rounded,
              title: '添加到歌单',
              onTap: () async {
                Navigator.pop(sheetContext);
                await addSongToPlaylist(context, song);
              },
            ),
            _SheetAction(
              icon: song.isRadio
                  ? Icons.podcasts_rounded
                  : (downloaded ? Icons.check_circle_outline_rounded : Icons.download_rounded),
              title: song.isRadio
                  ? '直播不可下载'
                  : (downloaded ? '已下载' : '下载到本地'),
              subtitle: song.isRadio
                  ? '广播为实时流媒体'
                  : (downloads.isSupported ? null : 'Web 端暂不支持'),
              enabled: !song.isRadio && downloads.isSupported && !downloaded,
              onTap: () async {
                Navigator.pop(sheetContext);
                await downloadSong(context, song);
              },
            ),
            if (onRemove != null)
              _SheetAction(
                icon: Icons.delete_outline_rounded,
                title: '从歌单中移除',
                danger: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  onRemove();
                },
              ),
          ],
        ),
      );
    },
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.child,
    this.subtitle,
    this.headerCover,
  });

  final String title;
  final String? subtitle;
  final String? headerCover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        border: Border(top: BorderSide(color: AppColors.lineStrong)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
              child: Row(
                children: [
                  if (headerCover != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: headerCover!.startsWith('assets/')
                            ? Image.asset(headerCover!, fit: BoxFit.cover)
                            : Image.network(headerCover!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.music_note)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.line),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: enabled ? color : AppColors.textTertiary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: enabled ? color : AppColors.textTertiary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textTertiary,
                      ),
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

class QualitySheet extends StatelessWidget {
  const QualitySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
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
            const Text('音质选择', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final quality in AudioQuality.values)
              RadioListTile<AudioQuality>(
                value: quality,
                groupValue: settings.quality,
                onChanged: (value) {
                  if (value != null) {
                    settings.setQuality(value);
                    Navigator.pop(context);
                  }
                },
                activeColor: AppColors.mint,
                title: Text(quality.label, style: const TextStyle(fontSize: 13.5)),
                subtitle: Text(
                  switch (quality) {
                    AudioQuality.standard => '节省流量，适合移动网络',
                    AudioQuality.high => '推荐设置，兼顾音质与速度',
                    AudioQuality.lossless => '需要音源支持，文件较大',
                  },
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

void openQualitySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const QualitySheet(),
  );
}

void openPlayerScreen(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => const PlayerScreen(),
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curve),
            child: child,
          ),
        );
      },
    ),
  );
}
