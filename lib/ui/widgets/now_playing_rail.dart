import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/demo_catalog.dart';
import '../../services/library_store.dart';
import '../../services/player_service.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/common.dart';

class NowPlayingRail extends StatelessWidget {
  const NowPlayingRail({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final library = context.watch<LibraryStore>();
    final song = player.current;

    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(20, 24, 18, 18),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.line)),
      ),
      child: song == null
          ? _EmptyRail(player: player)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '正在播放',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    CircleIconButton(
                      icon: Icons.open_in_full_rounded,
                      size: 30,
                      iconSize: 15,
                      tooltip: '沉浸播放',
                      onTap: () => openPlayerScreen(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Artwork(
                    url: song.cover,
                    size: 248,
                    radius: 22,
                    seed: song.uid,
                    glow: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  song.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'InterDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ValueListenableBuilder<Duration>(
                  valueListenable: player.position,
                  builder: (context, position, _) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: player.duration,
                      builder: (context, duration, __) {
                        final max = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: (position.inMilliseconds / max).clamp(0.0, 1.0),
                                minHeight: 3,
                                backgroundColor: Colors.white.withOpacity(0.09),
                                valueColor: const AlwaysStoppedAnimation(AppColors.mint),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatMs(position.inMilliseconds),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                Text(
                                  formatMs(duration.inMilliseconds),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircleIconButton(
                      icon: Icons.skip_previous_rounded,
                      size: 36,
                      iconSize: 22,
                      onTap: () => player.previous(),
                    ),
                    GestureDetector(
                      onTap: player.toggle,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.aurora,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.violet.withOpacity(0.3),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: player.isBuffering
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: Color(0xFF04141A),
                                ),
                              )
                            : Icon(
                                player.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: const Color(0xFF04141A),
                                size: 29,
                              ),
                      ),
                    ),
                    CircleIconButton(
                      icon: Icons.skip_next_rounded,
                      size: 36,
                      iconSize: 22,
                      onTap: () => player.next(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => toggleFavorite(context, song),
                      icon: Icon(
                        library.isFavorite(song)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 17,
                        color: library.isFavorite(song) ? AppColors.pink : AppColors.textTertiary,
                      ),
                      splashRadius: 18,
                      visualDensity: VisualDensity.compact,
                      tooltip: '收藏',
                    ),
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: () => showSongMenu(context, song),
                      icon: const Icon(Icons.more_horiz_rounded, size: 17),
                      label: const Text('更多', style: TextStyle(fontSize: 10)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.line),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      '接下来播放',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${player.queue.length - player.currentIndex - 1} 首',
                      style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: _UpNext(player: player)),
                if (library.history.isNotEmpty) ...[
                  const Divider(color: AppColors.line),
                  const SizedBox(height: 10),
                  const Text(
                    '刚刚听过',
                    style: TextStyle(fontSize: 9, letterSpacing: 1.6, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => openPlayerScreen(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '${library.history.first.name} · ${library.history.first.artist}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final queue = player.queue;
    final start = player.currentIndex + 1;
    if (start >= queue.length) {
      return Center(
        child: Text(
          '已是队列最后一首',
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary.withOpacity(0.8)),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: (queue.length - start).clamp(0, 4).toInt(),
      itemBuilder: (context, i) {
        final index = start + i;
        final song = queue[index];
        return InkWell(
          onTap: () => player.playAt(index),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Artwork(url: song.cover, size: 30, radius: 6, seed: song.uid),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 8.5, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyRail extends StatelessWidget {
  const _EmptyRail({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MUSEFLOW',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 20),
        const Artwork(url: 'assets/images/covers/cover_04.jpg', size: 248, radius: 22, seed: 'rail'),
        const SizedBox(height: 20),
        const Text(
          '让声音\n自然流动',
          style: TextStyle(
            fontFamily: 'InterDisplay',
            fontSize: 26,
            height: 1.15,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '选择一首歌，开始今天的聆听。',
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        const Spacer(),
        PrimaryButton(
          label: '播放每日推荐',
          icon: Icons.play_arrow_rounded,
          expand: true,
          onPressed: () => player.playQueue(demoTracks.take(6).toList()),
        ),
        const SizedBox(height: 12),
        const Text(
          '原创示例曲库 · 无需网络',
          style: TextStyle(fontSize: 9, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
