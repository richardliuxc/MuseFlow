import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/demo_catalog.dart';
import '../../models/song.dart';
import '../../services/library_store.dart';
import '../../services/music_repository.dart';
import '../../services/music_source.dart';
import '../../services/player_service.dart';
import '../actions.dart';
import '../widgets/common.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  int _requestToken = 0;

  String? _sourceId;
  List<Song> _results = const [];
  Map<String, String> _errors = const {};
  bool _loading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String raw, {bool record = true}) async {
    final query = raw.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _errors = const {};
        _lastQuery = '';
        _loading = false;
      });
      return;
    }
    _debounce?.cancel();
    final token = ++_requestToken;
    setState(() {
      _loading = true;
      _lastQuery = query;
      _errors = const {};
    });
    if (record) {
      unawaited(context.read<LibraryStore>().recordSearch(query));
    }
    try {
      final outcome = await context.read<MusicRepository>().search(
            query,
            sourceId: _sourceId,
          );
      if (!mounted || token != _requestToken) return;
      setState(() {
        _results = outcome.songs;
        _errors = outcome.errors;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        _results = const [];
        _errors = {'搜索失败': errorText(error)};
        _loading = false;
      });
    }
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _search('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 650), () {
      if (mounted && value.trim().length >= 2) _search(value, record: false);
    });
  }

  void _quickSearch(String keyword) {
    _controller.text = keyword;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _search(keyword);
    _focusNode.unfocus();
  }

  void _selectSource(String? sourceId) {
    setState(() => _sourceId = sourceId);
    if (_lastQuery.isNotEmpty) _search(_lastQuery);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 760;
    final library = context.watch<LibraryStore>();
    final player = context.watch<PlayerService>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(compact ? 20 : 36, compact ? 10 : 20, compact ? 20 : 36, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                const BrandLockup(compact: true),
                const SizedBox(height: 24),
              ],
              Text(
                '搜索',
                style: TextStyle(
                  fontFamily: 'InterDisplay',
                  fontSize: compact ? 30 : 38,
                  letterSpacing: -1,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '网易云、酷我、酷狗、QQ、咪咕，一次搜完。',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _SearchField(
                controller: _controller,
                focusNode: _focusNode,
                loading: _loading,
                onChanged: _onChanged,
                onSubmitted: (value) => _search(value),
                onClear: () {
                  _controller.clear();
                  _search('');
                  _focusNode.requestFocus();
                },
              ),
              const SizedBox(height: 14),
              _SourceFilters(selected: _sourceId, onSelect: _selectSource),
              const SizedBox(height: 26),
              if (_lastQuery.isEmpty)
                _IdleView(
                  history: library.searches,
                  onQuickSearch: _quickSearch,
                  onClearHistory: () => library.clearSearches(),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _loading
                            ? '正在全平台搜索「$_lastQuery」'
                            : '「$_lastQuery」的搜索结果',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!_loading)
                      Text(
                        '${_results.length} 首',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const _SkeletonList()
                else if (_results.isEmpty)
                  _SearchEmpty(
                    errors: _errors,
                    query: _lastQuery,
                    onRetry: () => _search(_lastQuery),
                    onDemo: () => _quickSearch('潮汐'),
                  )
                else ...[
                  if (_errors.isNotEmpty) _PartialErrorBanner(errors: _errors),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      children: [
                        for (var i = 0; i < _results.length; i++)
                          SongTile(
                            song: _results[i],
                            index: i + 1,
                            showCover: true,
                            showSource: true,
                            showAlbum: true,
                            isCurrent: player.current?.uid == _results[i].uid,
                            isPlaying: player.isPlaying,
                            onTap: () =>
                                playSong(context, _results[i], queue: _results, index: i),
                            onMore: () =>
                                showSongMenu(context, _results[i], queue: _results, index: i),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '搜索由各音乐平台公开接口提供 · 请支持正版',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textTertiary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.lineStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 21, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              cursorColor: AppColors.cyan,
              decoration: const InputDecoration(
                hintText: '搜索歌曲、歌手、专辑，或粘贴歌名',
                hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.cyan),
            )
          else if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 17),
              color: AppColors.textTertiary,
              visualDensity: VisualDensity.compact,
              splashRadius: 16,
              tooltip: '清空',
            ),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.line,
          ),
          const Icon(Icons.graphic_eq_rounded, size: 16, color: AppColors.mint),
          const SizedBox(width: 6),
          const Text(
            'HI-FI',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.mint,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceFilters extends StatelessWidget {
  const _SourceFilters({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _FilterPill(
            label: '全部音源',
            selected: selected == null,
            color: AppColors.cyan,
            onTap: () => onSelect(null),
          ),
          for (final descriptor in sourceDescriptors)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterPill(
                label: descriptor.label,
                selected: selected == descriptor.id,
                color: descriptor.color,
                onTap: () => onSelect(descriptor.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
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
          color: selected ? color.withOpacity(0.14) : Colors.white.withOpacity(0.035),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? color.withOpacity(0.45) : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.history,
    required this.onQuickSearch,
    required this.onClearHistory,
  });

  final List<String> history;
  final ValueChanged<String> onQuickSearch;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.isNotEmpty) ...[
          Row(
            children: [
              const Text('最近搜索', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: onClearHistory,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '清空',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final keyword in history)
                _Chip(label: keyword, icon: Icons.history_rounded, onTap: () => onQuickSearch(keyword)),
            ],
          ),
          const SizedBox(height: 26),
        ],
        Row(
          children: [
            const Text('热门搜索', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.pink.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'HOT',
                style: TextStyle(fontSize: 7.5, letterSpacing: 1, color: AppColors.pink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 700 ? 3 : 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < hotSearches.length; i++)
                  SizedBox(
                    width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                    child: InkWell(
                      onTap: () => onQuickSearch(hotSearches[i]),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${i + 1}'.padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: i < 3 ? AppColors.cyan : AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hotSearches[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                            if (i < 3)
                              const Icon(Icons.trending_up_rounded, size: 13, color: AppColors.pink),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        const Text('发现更多', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in discoverTags)
              _Chip(label: tag, onTap: () => onQuickSearch(tag)),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.line),
          ),
          child: const Row(
            children: [
              Icon(Icons.public_rounded, size: 18, color: AppColors.violet),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '搜索会同时请求多个平台；部分版权歌曲可能需要会员，播放时会自动尝试换源。',
                  style: TextStyle(fontSize: 10.5, height: 1.6, color: AppColors.textTertiary),
                ),
              ),
              Text(
                'MULTI-SOURCE',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.2,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.04 + _controller.value * 0.05;
        return Column(
          children: [
            for (var i = 0; i < 6; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 160 + (i % 3) * 30,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(opacity),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 90,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(opacity * 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PartialErrorBanner extends StatelessWidget {
  const _PartialErrorBanner({required this.errors});

  final Map<String, String> errors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.amber.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${errors.keys.join('、')} 暂时不可用，已展示其它音源结果',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({
    required this.errors,
    required this.query,
    required this.onRetry,
    required this.onDemo,
  });

  final Map<String, String> errors;
  final String query;
  final VoidCallback onRetry;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 30, color: AppColors.textTertiary),
          const SizedBox(height: 14),
          Text(
            errors.isEmpty ? '没有找到「$query」' : '音源暂时不可用',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            errors.isEmpty
                ? '换个关键词试试，或检查拼写。'
                : '当前网络无法访问音乐平台接口，可先体验内置示例曲库。',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.6),
          ),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final entry in errors.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key} · ${entry.value}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textTertiary),
                ),
              ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GhostButton(label: '重试', icon: Icons.refresh_rounded, onPressed: onRetry, height: 38),
              const SizedBox(width: 10),
              GhostButton(
                label: '试听示例曲',
                icon: Icons.headphones_rounded,
                onPressed: onDemo,
                height: 38,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
