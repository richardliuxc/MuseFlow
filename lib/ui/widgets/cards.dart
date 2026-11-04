import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/song.dart';
import 'artwork.dart';

class PlaylistCard extends StatefulWidget {
  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.onPlay,
    this.width = 196,
    this.showDescription = true,
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final double width;
  final bool showDescription;

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: _hover ? 1.025 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Stack(
                  children: [
                    Artwork(
                      url: widget.playlist.artwork,
                      size: widget.width,
                      radius: AppRadii.md,
                      seed: widget.playlist.name,
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(_hover ? 0.5 : 0.28),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.onPlay != null)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: AnimatedOpacity(
                          opacity: _hover ? 1 : 0.82,
                          duration: const Duration(milliseconds: 180),
                          child: _RoundPlayButton(onTap: widget.onPlay!),
                        ),
                      ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.playlist_play_rounded, size: 11, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.playlist.songs.length} 首',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              if (widget.showDescription) ...[
                const SizedBox(height: 4),
                Text(
                  widget.playlist.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundPlayButton extends StatelessWidget {
  const _RoundPlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.aurora,
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF04141A), size: 26),
      ),
    );
  }
}

class ChartCard extends StatefulWidget {
  const ChartCard({
    super.key,
    required this.chart,
    required this.onTap,
    this.width = 300,
  });

  final ChartSummary chart;
  final VoidCallback onTap;
  final double width;

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final songs = widget.chart.songs;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: widget.width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.chart.colors.first.withOpacity(_hover ? 0.3 : 0.2),
                AppColors.surface.withOpacity(0.9),
                widget.chart.colors.last.withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: widget.chart.colors.first.withOpacity(_hover ? 0.4 : 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.chart.tag,
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(_hover ? 0.9 : 0.35),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.chart.name,
                style: const TextStyle(
                  fontFamily: 'InterDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              if (songs.isNotEmpty)
                ...songs.take(3).toList().asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: widget.chart.colors.first,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          entry.value.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                })
              else
                const Text(
                  '进入查看完整榜单',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoodCard extends StatelessWidget {
  const MoodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.first.withOpacity(0.24),
              AppColors.surface.withOpacity(0.7),
            ],
          ),
          border: Border.all(color: colors.first.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.first.withOpacity(0.2),
              ),
              child: Icon(icon, size: 17, color: colors.first),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
