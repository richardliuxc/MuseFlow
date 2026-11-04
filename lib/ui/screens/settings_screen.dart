import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/demo_catalog.dart';
import '../../models/song.dart';
import '../../services/download_service.dart';
import '../../services/library_store.dart';
import '../../services/music_repository.dart';
import '../../services/music_source.dart';
import '../../services/nas_store.dart';
import '../../services/settings_store.dart';
import '../actions.dart';
import '../widgets/common.dart';
import 'nas_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final library = context.watch<LibraryStore>();
    final downloads = context.watch<DownloadService>();
    final nas = context.watch<NasStore>();
    final compact = MediaQuery.of(context).size.width < 760;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(compact ? 20 : 36, compact ? 10 : 22, compact ? 20 : 36, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                const BrandLockup(compact: true),
                const SizedBox(height: 24),
              ],
              Text(
                '设置',
                style: TextStyle(
                  fontFamily: 'InterDisplay',
                  fontSize: compact ? 30 : 38,
                  height: 1.1,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                '把 MuseFlow 调成你习惯的样子。',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              _ProfileCard(
                favoriteCount: library.favorites.length,
                playlistCount: library.playlists.length,
                downloadCount: library.downloads.length,
              ),
              const SizedBox(height: 28),
              const _SectionLabel('播放与音质', 'PLAYBACK'),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _QualitySelector(settings: settings),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _SwitchTile(
                      icon: Icons.swap_horiz_rounded,
                      title: '播放失败时自动换源',
                      subtitle: '当前音源不可用时，自动到其它平台寻找可播放版本',
                      value: settings.autoSwitchSource,
                      onChanged: settings.setAutoSwitchSource,
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _SwitchTile(
                      icon: Icons.animation_rounded,
                      title: '极光封面光环',
                      subtitle: '播放页显示极光光环，可随时关闭',
                      value: settings.animatedCover,
                      onChanged: settings.setAnimatedCover,
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _SwitchTile(
                      icon: Icons.translate_rounded,
                      title: '显示歌词翻译',
                      subtitle: '当音源提供翻译歌词时，一并展示',
                      value: settings.showTranslation,
                      onChanged: settings.setShowTranslation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('音乐源', 'SOURCES'),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < sourceDescriptors.length; i++) ...[
                      _SourceTile(
                        descriptor: sourceDescriptors[i],
                        enabled: settings.isSourceEnabled(sourceDescriptors[i].id),
                        onChanged: (value) =>
                            settings.setSourceEnabled(sourceDescriptors[i].id, value),
                      ),
                      if (i != sourceDescriptors.length - 1)
                        const Divider(height: 1, indent: 18, endIndent: 18),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '咪咕仅提供搜索与元数据，播放时会自动切换到其它音源。所有接口来自对应平台的公开服务。',
                  style: TextStyle(fontSize: 10, height: 1.6, color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('本地网络', 'NAS'),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                child: _NasSettingsTile(
                  count: nas.servers.length,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const NasScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('数据与存储', 'STORAGE'),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.download_done_rounded,
                      title: '离线下载',
                      subtitle: downloads.isSupported
                          ? '${library.downloads.length} 首歌曲已缓存到本机'
                          : '当前平台暂不支持离线下载',
                      onTap: () => showToast(
                        context,
                        downloads.isSupported
                            ? '可在「音乐库 → 下载」中管理离线歌曲'
                            : '请使用 App 或桌面端下载歌曲',
                      ),
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _ActionTile(
                      icon: Icons.search_off_rounded,
                      title: '清空搜索历史',
                      subtitle: '${library.searches.length} 条本地记录',
                      onTap: () async {
                        await library.clearSearches();
                        if (context.mounted) showToast(context, '搜索历史已清空');
                      },
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _ActionTile(
                      icon: Icons.cleaning_services_rounded,
                      title: '清理榜单缓存',
                      subtitle: '释放内存中的榜单数据，下次进入时重新获取',
                      onTap: () {
                        context.read<MusicRepository>().clearCharts();
                        showToast(context, '缓存已清理');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('关于', 'ABOUT'),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const _ActionTile(
                      icon: Icons.info_outline_rounded,
                      title: 'MuseFlow 沐声',
                      subtitle: '版本 1.0.0 (Build 1)',
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _ActionTile(
                      icon: Icons.privacy_tip_outlined,
                      title: '隐私与免责声明',
                      subtitle: '本地优先 · 不收集个人数据',
                      onTap: () => _showDisclaimer(context),
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _ActionTile(
                      icon: Icons.auto_awesome_rounded,
                      title: '关于示例曲库',
                      subtitle: '${demoTracks.length} 首原创氛围音乐，由 MuseFlow Studio 合成',
                      onTap: () => showToast(context, '示例曲目为程序合成，可自由用于体验与演示'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    const BrandMark(size: 30, glow: false),
                    const SizedBox(height: 10),
                    Text(
                      'MuseFlow · 让声音自然流动',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: AppColors.textTertiary.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '© 2026 MuseFlow Studio',
                      style: TextStyle(fontSize: 8.5, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('隐私与免责声明'),
        content: const SingleChildScrollView(
          child: Text(
            '1. MuseFlow 是本地音乐聚合客户端，不存储、不传播任何音频文件，也不提供破解或付费内容。\n\n'
            '2. 搜索与播放通过各音乐平台的公开接口完成，音频版权归原平台及版权方所有。\n\n'
            '3. 本应用仅供个人学习、研究与技术交流，请勿用于商业用途；请支持正版音乐。\n\n'
            '4. 收藏、歌单、搜索历史与设置仅保存在本机，卸载应用后会一并删除。\n\n'
            '5. 因版权、地区限制或平台策略调整导致的部分歌曲不可用，属于正常现象。',
            style: TextStyle(fontSize: 12, height: 1.8, color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.favoriteCount,
    required this.playlistCount,
    required this.downloadCount,
  });

  final int favoriteCount;
  final int playlistCount;
  final int downloadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withOpacity(0.18),
            AppColors.surface.withOpacity(0.8),
            AppColors.cyan.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: AppColors.violet.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
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
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  fontFamily: 'InterDisplay',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF071018),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      '音乐旅人',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 8),
                    _LocalBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '本地账户 · 无需登录，数据只属于你',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ProfileStat(label: '收藏', value: favoriteCount),
                    const SizedBox(width: 18),
                    _ProfileStat(label: '歌单', value: playlistCount),
                    const SizedBox(width: 18),
                    _ProfileStat(label: '下载', value: downloadCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.mint.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.mint.withOpacity(0.25)),
      ),
      child: const Text(
        'LOCAL',
        style: TextStyle(
          fontSize: 7.5,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: AppColors.mint,
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, this.english);

  final String title;
  final String english;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(
            english,
            style: const TextStyle(
              fontSize: 8,
              letterSpacing: 1.6,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleSwitch extends StatelessWidget {
  const _StyleSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.mint,
      activeTrackColor: AppColors.mint.withOpacity(0.35),
      inactiveThumbColor: AppColors.textTertiary,
      inactiveTrackColor: Colors.white.withOpacity(0.08),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, height: 1.4, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StyleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.descriptor,
    required this.enabled,
    required this.onChanged,
  });

  final SourceDescriptor descriptor;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: descriptor.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: descriptor.color.withOpacity(0.25)),
              ),
              child: Icon(
                descriptor.id == 'demo' ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                size: 17,
                color: descriptor.color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        descriptor.label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        descriptor.streaming ? '可播放' : '仅搜索',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: descriptor.streaming
                              ? AppColors.mint.withOpacity(0.8)
                              : AppColors.amber.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descriptor.description,
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            _StyleSwitch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            _TileIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.line),
      ),
      child: Icon(icon, size: 16, color: AppColors.textSecondary),
    );
  }
}

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TileIcon(icon: Icons.high_quality_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '默认音质',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      settings.quality.label,
                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final quality in AudioQuality.values) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => settings.setQuality(quality),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: settings.quality == quality
                            ? Colors.white.withOpacity(0.09)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: settings.quality == quality
                              ? AppColors.mint.withOpacity(0.4)
                              : AppColors.line,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          quality.shortLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: settings.quality == quality
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: settings.quality == quality
                                ? AppColors.mint
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (quality != AudioQuality.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}


class _NasSettingsTile extends StatelessWidget {
  const _NasSettingsTile({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            const _TileIcon(icon: Icons.cloud_queue_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NAS 服务器',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(
                    count == 0 ? '通过 WebDAV 或 SMB 接入本地音乐库' : '已连接 $count 个服务器',
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 19, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
