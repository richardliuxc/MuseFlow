import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/radio_station.dart';
import 'artwork.dart';

class RadioStationCard extends StatefulWidget {
  const RadioStationCard({
    super.key,
    required this.station,
    required this.favorite,
    required this.onPlay,
    required this.onFavorite,
    this.width,
    this.dense = false,
  });

  final RadioStation station;
  final bool favorite;
  final VoidCallback onPlay;
  final VoidCallback onFavorite;
  final double? width;
  final bool dense;

  @override
  State<RadioStationCard> createState() => _RadioStationCardState();
}

class _RadioStationCardState extends State<RadioStationCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final coverSize = widget.dense ? 52.0 : 58.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onPlay,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: widget.width,
          padding: EdgeInsets.all(widget.dense ? 11 : 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(_hover ? 0.075 : 0.045),
                AppColors.surface.withOpacity(0.55),
              ],
            ),
            border: Border.all(
              color: _hover ? AppColors.pink.withOpacity(0.35) : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Artwork(
                    url: station.favicon,
                    size: coverSize,
                    radius: widget.dense ? 12 : 14,
                    seed: station.name,
                  ),
                  Positioned(
                    left: 5,
                    bottom: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.58),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LiveDot(),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 6.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.dense ? 13 : 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (station.bitrate > 0)
                          Text(
                            '${station.bitrate}k',
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        if (station.bitrate > 0) const SizedBox(width: 8),
                        Text(
                          '${formatCount(station.votes)} 次收听',
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (station.isHls) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'HLS',
                            style: TextStyle(
                              fontSize: 7.5,
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onFavorite,
                icon: Icon(
                  widget.favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 17,
                  color:
                      widget.favorite ? AppColors.pink : AppColors.textTertiary,
                ),
                splashRadius: 17,
                visualDensity: VisualDensity.compact,
                tooltip: widget.favorite ? '取消收藏' : '收藏',
              ),
              GestureDetector(
                onTap: widget.onPlay,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.aurora,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pink.withOpacity(0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 21,
                    color: Color(0xFF071018),
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

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
      child: Container(
        width: 4,
        height: 4,
        decoration:
            const BoxDecoration(shape: BoxShape.circle, color: AppColors.pink),
      ),
    );
  }
}
