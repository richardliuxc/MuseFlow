import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/lrc.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/song.dart';
import '../../services/download_service.dart';
import '../../services/library_store.dart';
import '../../services/player_service.dart';
import '../../services/settings_store.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/common.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final song = player.current;
    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 64),
              const SizedBox(height: 24),
              const Text('还没有正在播放的歌曲', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              GhostButton(
                label: '返回发现',
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(song: player.playbackSong ?? song),
          const _Vignette(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                return Column(
                  children: [
                    _TopBar(player: player),
                    Expanded(
                      child: wide
                          ? _WideBody(player: player, song: song, constraints: constraints)
                          : _CompactBody(player: player, song: song),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final overlay = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withOpacity(0.26),
            AppColors.background.withOpacity(0.86),
            AppColors.background,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
    );

    Widget base;
    if (song.cover.startsWith('assets/')) {
      base = Image.asset(
        song.cover,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        color: Colors.black.withOpacity(0.5),
        colorBlendMode: BlendMode.darken,
        errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.background),
      );
    } else if (song.cover.startsWith('http')) {
      base = Image(
        image: CachedNetworkImageProvider(song.cover),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        color: Colors.black.withOpacity(0.5),
        colorBlendMode: BlendMode.darken,
        errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.background),
      );
    } else {
      base = DecoratedBox(
        decoration: BoxDecoration(gradient: artworkGradient(song.uid)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        base,
        ColoredBox(color: Colors.black.withOpacity(0.42)),
        overlay,
      ],
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.1,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.28),
              Colors.black.withOpacity(0.55),
            ],
            stops: const [0.45, 0.8, 1],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final song = player.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 42,
            iconSize: 26,
            tooltip: '收起播放器',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          if (song != null) ...[
            Artwork(url: song.cover, size: 34, radius: 8, seed: song.uid),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '正在播放',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song == null ? 'MuseFlow' : (song.album.isEmpty ? 'MuseFlow Sessions' : song.album),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _SleepTimerChip(player: player),
          const SizedBox(width: 6),
          CircleIconButton(
            icon: Icons.queue_music_rounded,
            tooltip: '播放队列',
            onTap: () => _showQueue(context, player),
          ),
          const SizedBox(width: 2),
          CircleIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: '更多',
            onTap: () => _showMore(context, player),
          ),
        ],
      ),
    );
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody({
    required this.player,
    required this.song,
    required this.constraints,
  });

  final PlayerService player;
  final Song song;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final artSize = math.min(constraints.maxHeight * 0.46, 380.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 12, 56, 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: artSize + 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ArtworkStage(song: song, size: artSize),
                const SizedBox(height: 30),
                _TrackMeta(song: song, player: player, centered: true),
              ],
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _LyricsPanel(player: player)),
                if (player.error != null) _ErrorBanner(player: player),
                const SizedBox(height: 8),
                _Controls(player: player, compact: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({
    required this.player,
    required this.song,
  });

  final PlayerService player;
  final Song song;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final artSize = math.min(width * 0.62, 252.0);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(
        children: [
          _ArtworkStage(song: song, size: artSize),
          const SizedBox(height: 24),
          _TrackMeta(song: song, player: player, centered: true),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: _LyricsPanel(player: player, compact: true),
          ),
          if (player.error != null) _ErrorBanner(player: player),
          const SizedBox(height: 4),
          _Controls(player: player, compact: true),
        ],
      ),
    );
  }
}

class _ArtworkStage extends StatelessWidget {
  const _ArtworkStage({required this.song, required this.size});

  final Song song;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 48,
      height: size + 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (context.watch<SettingsStore>().animatedCover)
            Container(
              width: size + 34,
              height: size + 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.violet.withOpacity(0.0),
                    AppColors.violet.withOpacity(0.4),
                    AppColors.cyan.withOpacity(0.22),
                    AppColors.mint.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
              ),
            )
          else
            SizedBox(width: size + 34, height: size + 34),
          Container(
            width: size + 22,
            height: size + 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
          ),
          Artwork(
            url: song.cover,
            size: size,
            radius: 24,
            seed: song.uid,
            glow: true,
          ),
          Positioned(
            left: 8,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.graphic_eq_rounded, size: 12, color: AppColors.mint),
                  const SizedBox(width: 6),
                  Text(
                    song.bitrate > 0 ? '${song.bitrate} kbps' : 'HIGH QUALITY',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackMeta extends StatelessWidget {
  const _TrackMeta({required this.song, required this.player, this.centered = false});

  final Song song;
  final PlayerService player;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final favorite = library.isFavorite(song);
    final settings = context.watch<SettingsStore>();
    final actualSource = player.playbackSource;
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                song.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  fontFamily: 'InterDisplay',
                  fontSize: 27,
                  height: 1.15,
                  letterSpacing: -0.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => toggleFavorite(context, song),
              icon: Icon(
                favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: favorite ? AppColors.pink : AppColors.textTertiary,
              ),
              splashRadius: 20,
              visualDensity: VisualDensity.compact,
              tooltip: favorite ? '取消收藏' : '收藏',
            ),
          ],
        ),
        Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _MetaPill(
              icon: Icons.album_outlined,
              label: song.album.isEmpty ? 'MuseFlow' : song.album,
            ),
            _MetaPill(
              icon: Icons.graphic_eq_rounded,
              label: settings.quality.shortLabel,
              color: AppColors.mint,
              onTap: () => openQualitySheet(context),
            ),
            if (actualSource != null && actualSource != song.source)
              _MetaPill(
                icon: Icons.swap_horiz_rounded,
                label: '已换源 · ${player.playbackSong?.sourceLabel ?? ''}',
                color: AppColors.cyan,
              )
            else
              _MetaPill(
                icon: Icons.verified_rounded,
                label: song.sourceLabel,
                color: song.sourceColor,
              ),
          ],
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.color, this.onTap});

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? AppColors.textTertiary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}

class _LyricsPanel extends StatefulWidget {
  const _LyricsPanel({required this.player, this.compact = false});

  final PlayerService player;
  final bool compact;

  @override
  State<_LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<_LyricsPanel> {
  final ScrollController _controller = ScrollController();
  int _active = -1;
  static const double _itemExtent = 62;

  @override
  void initState() {
    super.initState();
    widget.player.position.addListener(_onPosition);
    _syncActive(autoScroll: false);
  }

  @override
  void didUpdateWidget(covariant _LyricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      oldWidget.player.position.removeListener(_onPosition);
      widget.player.position.addListener(_onPosition);
    }
    if (oldWidget.player.current?.uid != widget.player.current?.uid) {
      _active = -1;
      _syncActive(autoScroll: false);
      if (_controller.hasClients) {
        _controller.jumpTo(0);
      }
    } else {
      _syncActive(autoScroll: true);
    }
  }

  @override
  void dispose() {
    widget.player.position.removeListener(_onPosition);
    _controller.dispose();
    super.dispose();
  }

  void _onPosition() => _syncActive(autoScroll: true);

  void _syncActive({required bool autoScroll}) {
    final lines = widget.player.lyrics;
    if (!mounted || lines.isEmpty) {
      if (_active != -1) setState(() => _active = -1);
      return;
    }
    final index = activeLyricIndex(lines, widget.player.position.value);
    if (index == _active) return;
    setState(() => _active = index);
    if (autoScroll && _controller.hasClients) {
      final target = (index * _itemExtent - 120).clamp(0.0, _controller.position.maxScrollExtent);
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final lines = player.lyrics;
    final settings = context.watch<SettingsStore>();

    if (player.lyricsLoading) {
      return _LyricsPlaceholder(compact: widget.compact, loading: true);
    }
    if (lines.isEmpty) {
      return _LyricsPlaceholder(compact: widget.compact, loading: false);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Stack(
          children: [
            ListView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 20 : 28,
                vertical: widget.compact ? 48 : 62,
              ),
              itemExtent: _itemExtent,
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final isActive = index == _active;
                final translation = settings.showTranslation ? line.translation : null;
                return InkWell(
                  onTap: () => player.seek(line.time),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 240),
                    style: TextStyle(
                      fontSize: isActive ? 18 : 16,
                      height: 1.35,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: isActive ? 0.1 : 0.3,
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(line.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (translation != null && translation.isNotEmpty)
                          Text(
                            translation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                              color: isActive
                                  ? Colors.white.withOpacity(0.55)
                                  : Colors.white.withOpacity(0.22),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 20,
              left: widget.compact ? 20 : 28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lyrics_outlined, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    'LYRICS · 歌词',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 44,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background.withOpacity(0.9),
                        AppColors.background.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 44,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.background.withOpacity(0.9),
                        AppColors.background.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LyricsPlaceholder extends StatelessWidget {
  const _LyricsPlaceholder({required this.compact, required this.loading});

  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lyrics_outlined,
                    size: compact ? 26 : 30,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '暂无歌词，享受旋律',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.player, required this.compact});

  final PlayerService player;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final narrow = compact || width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SeekBar(player: player),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleIconButton(
              icon: Icons.shuffle_rounded,
              tooltip: '随机播放',
              active: player.shuffle,
              onTap: player.toggleShuffle,
            ),
            SizedBox(width: narrow ? 12 : 26),
            CircleIconButton(
              icon: Icons.skip_previous_rounded,
              size: 46,
              iconSize: 26,
              onTap: () => player.previous(),
            ),
            SizedBox(width: narrow ? 10 : 20),
            _PlayButton(player: player, size: narrow ? 64 : 70),
            SizedBox(width: narrow ? 10 : 20),
            CircleIconButton(
              icon: Icons.skip_next_rounded,
              size: 46,
              iconSize: 26,
              onTap: () => player.next(),
            ),
            SizedBox(width: narrow ? 12 : 26),
            CircleIconButton(
              icon: switch (player.repeat) {
                RepeatMode.off => Icons.repeat_rounded,
                RepeatMode.all => Icons.repeat_rounded,
                RepeatMode.one => Icons.repeat_one_rounded,
              },
              tooltip: switch (player.repeat) {
                RepeatMode.off => '列表循环已关闭',
                RepeatMode.all => '列表循环',
                RepeatMode.one => '单曲循环',
              },
              active: player.repeat != RepeatMode.off,
              onTap: player.cycleRepeat,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (!narrow) ...[
              const Icon(Icons.volume_down_rounded, size: 18, color: AppColors.textTertiary),
              SizedBox(
                width: 100,
                child: Slider(
                  value: player.volume,
                  onChanged: (value) => player.setVolume(value),
                  activeColor: Colors.white70,
                  inactiveColor: Colors.white.withOpacity(0.12),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Spacer(),
            _ActionIcon(
              icon: Icons.lyrics_outlined,
              label: '歌词',
              onTap: () => _showLyricsInfo(context),
            ),
            const SizedBox(width: 4),
            _ActionIcon(
              icon: Icons.timer_outlined,
              label: '定时',
              onTap: () => _showSleepTimer(context, player),
            ),
            const SizedBox(width: 4),
            _ActionIcon(
              icon: Icons.queue_music_rounded,
              label: '队列',
              onTap: () => _showQueue(context, player),
            ),
            if (!narrow) const Spacer(),
            if (!narrow) _DownloadAction(player: player),
          ],
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.player, required this.size});

  final PlayerService player;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.aurora,
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withOpacity(0.42),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.18),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: player.toggle,
          child: Center(
            child: player.isBuffering
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF04141A),
                    ),
                  )
                : Icon(
                    player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: size * 0.46,
                    color: const Color(0xFF04141A),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.player});

  final PlayerService player;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.player.position,
      builder: (context, position, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: widget.player.duration,
          builder: (context, duration, __) {
            final max = math.max(duration.inMilliseconds, widget.player.current?.durationMs ?? 0);
            final total = math.max(max, 1);
            final current = (_drag ?? position.inMilliseconds.toDouble()).clamp(0.0, total.toDouble());
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.12),
                    secondaryActiveTrackColor: Colors.white.withOpacity(0.24),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: current,
                    max: total.toDouble(),
                    secondaryTrackValue: math.min(
                      widget.player.buffered.value.inMilliseconds.toDouble(),
                      total.toDouble(),
                    ),
                    onChanged: (value) => setState(() => _drag = value),
                    onChangeEnd: (value) {
                      setState(() => _drag = null);
                      widget.player.seek(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatMs(current.toInt()),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textTertiary,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        formatMs(total.toInt()),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textTertiary,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textTertiary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadAction extends StatelessWidget {
  const _DownloadAction({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadService>();
    final song = player.current;
    if (song == null) return const SizedBox.shrink();
    final isLoading = downloads.isDownloading(song);
    final done = downloads.isDownloaded(song);
    return TextButton.icon(
      onPressed: done ? null : () => downloadSong(context, song),
      icon: isLoading
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.textSecondary),
            )
          : Icon(
              done ? Icons.check_circle_outline_rounded : Icons.download_rounded,
              size: 16,
              color: done ? AppColors.mint : AppColors.textSecondary,
            ),
      label: Text(
        done ? '已下载' : '下载',
        style: TextStyle(
          fontSize: 11,
          color: done ? AppColors.mint : AppColors.textSecondary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.error ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppColors.danger, height: 1.4),
            ),
          ),
          TextButton(
            onPressed: player.retry,
            child: const Text('重试', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _SleepTimerChip extends StatelessWidget {
  const _SleepTimerChip({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    if (!player.isSleepTimerActive) return const SizedBox.shrink();
    return ValueListenableBuilder<Duration?>(
      valueListenable: player.sleepRemaining,
      builder: (context, remaining, _) {
        if (remaining == null) return const SizedBox.shrink();
        final minutes = (remaining.inSeconds / 60).ceil();
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 12, color: AppColors.mint),
                const SizedBox(width: 5),
                Text(
                  '$minutes 分钟后暂停',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  const _SleepTimerSheet({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
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
            const Text('睡眠定时', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              '到时间后自动暂停播放',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 10),
            for (final minutes in const [15, 30, 45, 60, 90])
              ListTile(
                leading: const Icon(Icons.nightlight_outlined, size: 18),
                title: Text('$minutes 分钟', style: const TextStyle(fontSize: 13)),
                trailing: player.isSleepTimerActive && player.sleepRemaining.value != null
                    ? Text(
                        '${(player.sleepRemaining.value!.inSeconds / 60).ceil()} 分钟',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      )
                    : null,
                onTap: () {
                  player.startSleepTimer(Duration(minutes: minutes));
                  Navigator.pop(context);
                },
              ),
            if (player.isSleepTimerActive)
              ListTile(
                leading: const Icon(Icons.timer_off_outlined, size: 18, color: AppColors.danger),
                title: const Text('关闭定时', style: TextStyle(fontSize: 13, color: AppColors.danger)),
                onTap: () {
                  player.cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

void _showSleepTimer(BuildContext context, PlayerService player) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SleepTimerSheet(player: player),
  );
}

void _showLyricsInfo(BuildContext context) {
  showToast(context, '歌词自动滚动 · 点击歌词可跳转播放位置');
}

void _showQueue(BuildContext context, PlayerService player) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _QueueSheet(player: player),
  );
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.66,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
            border: Border(top: BorderSide(color: AppColors.lineStrong)),
          ),
          child: Column(
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
                padding: const EdgeInsets.fromLTRB(22, 16, 12, 10),
                child: Row(
                  children: [
                    const Text(
                      '播放队列',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${player.queue.length} 首',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        player.clearQueue();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '清空',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.line),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: player.queue.length,
                  itemBuilder: (context, index) {
                    final song = player.queue[index];
                    final isCurrent = index == player.currentIndex;
                    return _QueueTile(
                      song: song,
                      index: index,
                      isCurrent: isCurrent,
                      isPlaying: player.isPlaying,
                      onTap: () async {
                        Navigator.pop(context);
                        await player.playAt(index);
                      },
                      onRemove: () => player.removeFromQueue(index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.song,
    required this.index,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  });

  final Song song;
  final int index;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent ? Colors.white.withOpacity(0.04) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: isCurrent
                    ? EqBars(playing: isPlaying, size: 14, color: AppColors.mint)
                    : Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      ),
              ),
              const SizedBox(width: 8),
              Artwork(url: song.cover, size: 38, radius: 8, seed: song.uid),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? AppColors.mint : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 16),
                splashRadius: 16,
                color: AppColors.textTertiary,
                tooltip: '移出队列',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showMore(BuildContext context, PlayerService player) {
  final song = player.current;
  if (song == null) return;
  showModalBottomSheet<void>(
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
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('添加到歌单', style: TextStyle(fontSize: 13.5)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  addSongToPlaylist(context, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('下载这首歌', style: TextStyle(fontSize: 13.5)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  downloadSong(context, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('歌曲信息', style: TextStyle(fontSize: 13.5)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showToast(
                    context,
                    '${song.name} · ${song.artist} · ${song.sourceLabel}',
                  );
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
