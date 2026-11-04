import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/library_store.dart';
import '../../services/player_service.dart';
import '../actions.dart';
import 'artwork.dart';
import 'common.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final song = player.current;
    if (song == null) return const SizedBox.shrink();
    final library = context.watch<LibraryStore>();
    final favorite = library.isFavorite(song);
    final width = MediaQuery.of(context).size.width;
    final minimal = compact && width < 420;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 24, 6, compact ? 12 : 24, compact ? 6 : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: AppColors.surfaceHigh.withOpacity(0.92),
          child: InkWell(
            onTap: () => openPlayerScreen(context),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 9),
                  child: Row(
                    children: [
                      Artwork(
                        url: song.cover,
                        size: compact ? 44 : 48,
                        radius: 10,
                        seed: song.uid,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    song.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (player.isPlaying) ...[
                                  const SizedBox(width: 8),
                                  const EqBars(size: 12, color: AppColors.mint),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                                if (!compact && song.source != 'demo') ...[
                                  const SizedBox(width: 8),
                                  SourceBadge(song: song, dense: true),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!minimal)
                        IconButton(
                          onPressed: () => toggleFavorite(context, song),
                          icon: Icon(
                            favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: favorite ? AppColors.pink : AppColors.textTertiary,
                          ),
                          splashRadius: 18,
                          visualDensity: VisualDensity.compact,
                          tooltip: '收藏',
                        ),
                      if (!minimal)
                        IconButton(
                          onPressed: () => player.previous(),
                          icon: const Icon(Icons.skip_previous_rounded, size: 22),
                          splashRadius: 18,
                          color: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                          tooltip: '上一首',
                        ),
                      _MiniPlayButton(player: player),
                      IconButton(
                        onPressed: () => player.next(),
                        icon: const Icon(Icons.skip_next_rounded, size: 22),
                        splashRadius: 18,
                        color: AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                        tooltip: '下一首',
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ValueListenableBuilder<Duration>(
                    valueListenable: player.position,
                    builder: (context, position, _) {
                      return ValueListenableBuilder<Duration>(
                        valueListenable: player.duration,
                        builder: (context, duration, __) {
                          final max = duration.inMilliseconds <= 0
                              ? 1
                              : duration.inMilliseconds;
                          final progress = (position.inMilliseconds / max).clamp(0.0, 1.0);
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 2,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.auroraHorizontal,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
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

class _MiniPlayButton extends StatelessWidget {
  const _MiniPlayButton({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: player.toggle,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: player.isBuffering
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Color(0xFF071018),
                ),
              )
            : Icon(
                player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 22,
                color: const Color(0xFF071018),
              ),
      ),
    );
  }
}
