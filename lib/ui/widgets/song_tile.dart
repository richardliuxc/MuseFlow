import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/song.dart';
import 'artwork.dart';
import 'common.dart';

class SongTile extends StatefulWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.onMore,
    this.index,
    this.showCover = true,
    this.showNumber = false,
    this.dense = false,
    this.isCurrent = false,
    this.isPlaying = false,
    this.showAlbum = true,
    this.showSource = false,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
  });

  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final int? index;
  final bool showCover;
  final bool showNumber;
  final bool dense;
  final bool isCurrent;
  final bool isPlaying;
  final bool showAlbum;
  final bool showSource;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final color = widget.isCurrent ? AppColors.mint : AppColors.textPrimary;
    final coverSize = widget.dense ? 42.0 : 48.0;
    final subtitle = widget.showAlbum ? song.subtitle : song.artist;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _hover
              ? Colors.white.withOpacity(0.045)
              : (widget.isCurrent
                  ? Colors.white.withOpacity(0.035)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Padding(
              padding: widget.padding,
              child: Row(
                children: [
                  if (widget.showNumber && widget.index != null) ...[
                    TrackNumberBadge(
                      number: widget.index!,
                      playing: widget.isCurrent && widget.isPlaying,
                    ),
                    const SizedBox(width: 12),
                  ] else if (widget.showCover) ...[
                    Stack(
                      children: [
                        Artwork(
                          url: song.cover,
                          size: coverSize,
                          radius: widget.dense ? 8 : 10,
                          seed: song.uid,
                        ),
                        if (widget.isCurrent)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    widget.dense ? 8 : 10),
                                color: Colors.black.withOpacity(0.35),
                              ),
                              child: Center(
                                child: EqBars(
                                  playing: widget.isPlaying,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 13),
                  ],
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
                                style: TextStyle(
                                  fontSize: widget.dense ? 13.5 : 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                  color: color,
                                ),
                              ),
                            ),
                            if (widget.showSource) ...[
                              const SizedBox(width: 8),
                              SourceBadge(song: song, dense: widget.dense),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (song.isRadio)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.pink,
                        ),
                      ),
                    )
                  else if (song.durationMs > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        formatMs(song.durationMs),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  if (widget.trailing != null) widget.trailing!,
                  if (widget.onMore != null)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _hover ? 1 : 0.35,
                      child: IconButton(
                        onPressed: widget.onMore,
                        icon: const Icon(Icons.more_horiz_rounded, size: 19),
                        color: AppColors.textSecondary,
                        splashRadius: 18,
                        visualDensity: VisualDensity.compact,
                        tooltip: '更多',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
