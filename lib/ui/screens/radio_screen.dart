import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/radio_station.dart';
import '../../services/library_store.dart';
import '../../services/player_service.dart';
import '../../services/radio_repository.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/common.dart';
import '../widgets/radio_cards.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  final TextEditingController _controller = TextEditingController();
  late final Future<List<RadioStation>> _future;
  String _query = '';
  String _region = '全部';
  String _genre = '全部类型';
  int _visibleCount = 60;

  @override
  void initState() {
    super.initState();
    _future = context.read<RadioRepository>().all();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play(List<RadioStation> list, RadioStation station) {
    final songs = list.map((item) => item.toSong()).toList();
    final index = list.indexOf(station);
    context
        .read<PlayerService>()
        .playQueue(songs, startIndex: index < 0 ? 0 : index);
    showToast(context, '正在收听「${station.name}」');
  }

  List<RadioStation> _filter(List<RadioStation> stations) {
    final query = _query.trim().toLowerCase();
    return stations.where((station) {
      if (_region != '全部' && station.region != _region) return false;
      if (_genre != '全部类型' && station.genre != _genre) return false;
      if (query.isEmpty) return true;
      final haystack =
          '${station.name} ${station.country} ${station.genre} ${station.tags.join(' ')}'
              .toLowerCase();
      return query.split(RegExp(r'\s+')).every(haystack.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final width = MediaQuery.of(context).size.width;
    final compact = width < 760;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          compact ? 20 : 36, compact ? 10 : 22, compact ? 20 : 36, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
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
                        Row(
                          children: [
                            Text(
                              '世界广播',
                              style: TextStyle(
                                fontFamily: 'InterDisplay',
                                fontSize: compact ? 30 : 38,
                                height: 1.1,
                                letterSpacing: -1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.pink.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: AppColors.pink.withOpacity(0.25)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PulseDot(),
                                  SizedBox(width: 5),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: AppColors.pink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          '来自 190+ 个国家与地区的实时电台，24 小时不断线。',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!compact)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.035),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.public_rounded,
                              size: 13, color: AppColors.cyan),
                          SizedBox(width: 6),
                          Text(
                            '520 STATIONS',
                            style: TextStyle(
                              fontSize: 8.5,
                              letterSpacing: 1.1,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.045),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 19, color: AppColors.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (value) => setState(() {
                          _query = value;
                          _visibleCount = 60;
                        }),
                        style: const TextStyle(fontSize: 13),
                        cursorColor: AppColors.cyan,
                        decoration: const InputDecoration(
                          hintText: '搜索电台、国家、音乐类型',
                          hintStyle: TextStyle(
                              fontSize: 12.5, color: AppColors.textTertiary),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                            _visibleCount = 60;
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        splashRadius: 16,
                        color: AppColors.textTertiary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _RegionChip(
                      label: '全部',
                      selected: _region == '全部',
                      onTap: () => setState(() {
                        _region = '全部';
                        _visibleCount = 60;
                      }),
                    ),
                    for (final region in const ['华语', '欧美', '日韩', '世界'])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _RegionChip(
                          label: region,
                          selected: _region == region,
                          onTap: () => setState(() {
                            _region = region;
                            _visibleCount = 60;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _GenreChip(
                      label: '全部类型',
                      selected: _genre == '全部类型',
                      onTap: () => setState(() {
                        _genre = '全部类型';
                        _visibleCount = 60;
                      }),
                    ),
                    for (final genre in const [
                      '音乐',
                      '新闻',
                      '谈话',
                      '流行',
                      '爵士',
                      '古典',
                      '电子',
                      '怀旧',
                      '文化',
                      '综合',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _GenreChip(
                          label: genre,
                          selected: _genre == genre,
                          onTap: () => setState(() {
                            _genre = genre;
                            _visibleCount = 60;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FutureBuilder<List<RadioStation>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 280,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  final all = snapshot.data ?? const <RadioStation>[];
                  final filtered = _filter(all);
                  final visible = filtered.take(_visibleCount).toList();
                  final showHero =
                      _query.isEmpty && _region == '全部' && _genre == '全部类型';
                  final featured =
                      all.where((station) => station.featured).take(6).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHero && featured.isNotEmpty) ...[
                        _RadioHero(
                          station: featured.first,
                          count: all.length,
                          onPlay: () => _play(featured, featured.first),
                        ),
                        const SizedBox(height: 26),
                      ],
                      Row(
                        children: [
                          Text(
                            showHero ? '全部电台' : '筛选结果',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${filtered.length} 个',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.textTertiary),
                          ),
                          const Spacer(),
                          Text(
                            '按热度排序',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textTertiary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        EmptyState(
                          icon: Icons.radio_outlined,
                          title: '没有找到相关电台',
                          message: '试试其他国家、类型或关键词。',
                          action: '清空筛选',
                          onAction: () {
                            _controller.clear();
                            setState(() {
                              _query = '';
                              _region = '全部';
                              _genre = '全部类型';
                              _visibleCount = 60;
                            });
                          },
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 940 ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: visible.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 94,
                              ),
                              itemBuilder: (context, index) {
                                final station = visible[index];
                                final song = station.toSong();
                                return RadioStationCard(
                                  station: station,
                                  dense: true,
                                  favorite: library.isFavorite(song),
                                  onPlay: () => _play(filtered, station),
                                  onFavorite: () async {
                                    await library.toggleFavorite(song);
                                    if (context.mounted) {
                                      showToast(
                                        context,
                                        library.isFavorite(song)
                                            ? '已收藏电台'
                                            : '已取消收藏',
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      if (filtered.length > visible.length) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _visibleCount += 60),
                            icon:
                                const Icon(Icons.expand_more_rounded, size: 16),
                            label: Text(
                              '加载更多 · 还有 ${filtered.length - visible.length} 个',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          '电台流由公开目录提供 · 版权归各电台所有',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textTertiary.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioHero extends StatelessWidget {
  const _RadioHero(
      {required this.station, required this.count, required this.onPlay});

  final RadioStation station;
  final int count;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.pink.withOpacity(0.17),
            AppColors.violet.withOpacity(0.13),
            AppColors.surface.withOpacity(0.85),
          ],
        ),
        border: Border.all(color: AppColors.pink.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Artwork(
            url: station.favicon,
            size: 110,
            radius: 22,
            seed: station.name,
            glow: true,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _PulseDot(),
                    const SizedBox(width: 7),
                    const Text(
                      'LIVE NOW · 正在直播',
                      style: TextStyle(
                        fontSize: 8.5,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$count STATIONS',
                      style: const TextStyle(
                        fontSize: 8,
                        letterSpacing: 1.2,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'InterDisplay',
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  station.subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: '收听直播',
                  icon: Icons.play_arrow_rounded,
                  height: 38,
                  onPressed: onPlay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: 5,
        height: 5,
        decoration:
            const BoxDecoration(shape: BoxShape.circle, color: AppColors.pink),
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.pink.withOpacity(0.13)
              : Colors.white.withOpacity(0.035),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? AppColors.pink.withOpacity(0.38) : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.pink : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.09) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
              color:
                  selected ? Colors.white.withOpacity(0.22) : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: selected ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
