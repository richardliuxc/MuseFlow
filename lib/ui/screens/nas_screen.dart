import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/nas_server.dart';
import '../../models/song.dart';
import '../../services/library_store.dart';
import '../../services/nas_service.dart';
import '../../services/nas_store.dart';
import '../../services/player_service.dart';
import '../actions.dart';
import '../widgets/common.dart';

class NasScreen extends StatelessWidget {
  const NasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NasStore>();
    final compact = MediaQuery.of(context).size.width < 760;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(compact ? 20 : 36, compact ? 10 : 22, compact ? 20 : 36, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          size: 36,
                          iconSize: 18,
                          tooltip: '返回',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        PrimaryButton(
                          label: '添加 NAS',
                          icon: Icons.add_rounded,
                          height: 38,
                          onPressed: () => _add(context, store),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      children: [
                        Icon(Icons.cloud_queue_rounded, size: 26, color: AppColors.cyan),
                        SizedBox(width: 10),
                        Text(
                          '本地网络',
                          style: TextStyle(
                            fontFamily: 'InterDisplay',
                            fontSize: 32,
                            height: 1.1,
                            letterSpacing: -1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '连接 NAS 上的音乐，WebDAV 或 SMB，私人曲库不必上传云端。',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 22),
                    if (store.servers.isEmpty)
                      EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: '还没有连接 NAS',
                        message: '支持群晖、威联通、TrueNAS、Windows 共享与任意 WebDAV 服务。\n音频会在播放时按需缓存到本机。',
                        action: '添加第一个服务器',
                        onAction: () => _add(context, store),
                      )
                    else ...[
                      for (final server in store.servers) ...[
                        _NasServerCard(
                          server: server,
                          compact: compact,
                          onBrowse: () => _browse(context, server),
                          onEdit: () => _edit(context, store, server),
                          onDelete: () => _delete(context, store, server),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 14),
                      const _NasNotice(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, NasStore store) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NasServerDialog(store: store),
    );
  }

  Future<void> _edit(BuildContext context, NasStore store, NasServer server) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NasServerDialog(store: store, existing: server),
    );
  }

  void _browse(BuildContext context, NasServer server) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NasBrowserScreen(server: server)),
    );
  }

  Future<void> _delete(BuildContext context, NasStore store, NasServer server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('移除 NAS？'),
        content: Text('将移除「${server.name}」的连接信息，不会删除 NAS 上的文件。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('移除', style: TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await store.remove(server);
      if (context.mounted) showToast(context, '已移除 ${server.name}');
    }
  }
}

class _NasServerCard extends StatelessWidget {
  const _NasServerCard({
    required this.server,
    required this.compact,
    required this.onBrowse,
    required this.onEdit,
    required this.onDelete,
  });

  final NasServer server;
  final bool compact;
  final VoidCallback onBrowse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  (server.isWebDav ? AppColors.cyan : AppColors.violet).withOpacity(0.25),
                  AppColors.surfaceHigh,
                ],
              ),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(
              server.isWebDav ? Icons.cloud_rounded : Icons.dns_rounded,
              size: 23,
              color: server.isWebDav ? AppColors.cyan : AppColors.violet,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        server.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        server.protocol.label,
                        style: const TextStyle(
                          fontSize: 7.5,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  server.shortAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          if (compact)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textTertiary),
              padding: EdgeInsets.zero,
              tooltip: '更多',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'delete', child: Text('移除')),
              ],
            )
          else ...[
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 17),
              color: AppColors.textTertiary,
              tooltip: '编辑',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              color: AppColors.textTertiary,
              tooltip: '移除',
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(width: 2),
          FilledButton(
            onPressed: onBrowse,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mint.withOpacity(0.12),
              foregroundColor: AppColors.mint,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('浏览', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _NasNotice extends StatelessWidget {
  const _NasNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.line),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 15, color: AppColors.textTertiary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '密码保存在系统安全存储中，不会写入歌曲或云端。MuseFlow 仅读取你选择的音频文件，播放时自动缓存到本机临时目录。',
              style: TextStyle(fontSize: 9.5, height: 1.6, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class NasBrowserScreen extends StatefulWidget {
  const NasBrowserScreen({super.key, required this.server});

  final NasServer server;

  @override
  State<NasBrowserScreen> createState() => _NasBrowserScreenState();
}

class _NasBrowserScreenState extends State<NasBrowserScreen> {
  String _path = '';
  List<NasEntry> _entries = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  Future<void> _load(String path) async {
    setState(() {
      _loading = true;
      _error = null;
      _path = path;
    });
    try {
      final service = context.read<NasService>();
      final entries = await service.list(widget.server, path);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<NasEntry> get _audioEntries => _entries.where((entry) => entry.isAudio).toList();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;
    final folders = _entries.where((entry) => entry.isDirectory).toList();
    final audio = _audioEntries;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(compact ? 12 : 24, 8, compact ? 14 : 30, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_path.isEmpty) {
                          Navigator.of(context).maybePop();
                        } else {
                          _load(_parentPath(_path));
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 19),
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.server.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _breadcrumb(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9.5, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : () => _load(_path),
                      icon: const Icon(Icons.refresh_rounded, size: 19),
                      color: AppColors.textTertiary,
                      tooltip: '刷新',
                    ),
                    if (audio.isNotEmpty)
                      TextButton.icon(
                        onPressed: _busy ? null : () => _play(audio.first),
                        icon: const Icon(Icons.play_arrow_rounded, size: 17),
                        label: const Text('播放全部', style: TextStyle(fontSize: 10.5)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.mint),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _error != null
                        ? _ErrorState(
                            message: _error!,
                            onRetry: () => _load(_path),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _load(_path),
                            child: folders.isEmpty && audio.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 120),
                                      EmptyState(
                                        icon: Icons.folder_open_rounded,
                                        title: '这个目录是空的',
                                        message: '换一个文件夹，或把音乐放入 NAS 共享目录。',
                                      ),
                                    ],
                                  )
                                : ListView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(
                                        compact ? 14 : 30, 12, compact ? 14 : 30, 30),
                                    children: [
                                      for (final folder in folders) ...[
                                        _EntryTile(
                                          entry: folder,
                                          onTap: () => _load(folder.path),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      if (folders.isNotEmpty && audio.isNotEmpty)
                                        const SizedBox(height: 12),
                                      for (final entry in audio) ...[
                                        _EntryTile(
                                          entry: entry,
                                          onTap: () => _play(entry),
                                          trailing: _FavoriteButton(
                                            song: _song(entry),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      const SizedBox(height: 12),
                                      Center(
                                        child: Text(
                                          '${folders.length} 个文件夹 · ${audio.length} 首音频',
                                          style: const TextStyle(
                                              fontSize: 9, color: AppColors.textTertiary),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _parentPath(String path) {
    final clean = path.replaceAll(RegExp(r'/+$'), '');
    final index = clean.lastIndexOf('/');
    if (index <= 0) return '';
    return clean.substring(0, index);
  }

  String _breadcrumb() {
    if (_path.isEmpty) return '/';
    return _path;
  }

  Song _song(NasEntry entry) {
    return Song(
      id: 'nas:${widget.server.id}:${entry.path}',
      source: 'nas',
      name: entry.title,
      artist: widget.server.name,
      album: _path.isEmpty ? '本地网络' : _path,
      cover: '',
      durationMs: 0,
      extra: {
        'nas': '1',
        'nasServer': widget.server.id,
        'nasPath': entry.path,
        'nasName': entry.name,
        'nasSize': '${entry.size}',
        'nasProtocol': widget.server.protocol.wireName,
      },
    );
  }

  Future<void> _play(NasEntry entry) async {
    if (_busy) return;
    final songs = _audioEntries.map(_song).toList();
    final index = _audioEntries.indexOf(entry);
    setState(() => _busy = true);
    try {
      showToast(context, '正在从 NAS 加载音频…');
      final future = context
          .read<PlayerService>()
          .playQueue(songs, startIndex: index < 0 ? 0 : index);
      if (mounted) openPlayerScreen(context);
      await future;
    } catch (error) {
      if (mounted) showToast(context, 'NAS 播放失败：$error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onTap, this.trailing});

  final NasEntry entry;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.035),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (entry.isDirectory ? AppColors.amber : AppColors.cyan).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  entry.isDirectory ? Icons.folder_rounded : Icons.audio_file_rounded,
                  size: 20,
                  color: entry.isDirectory ? AppColors.amber : AppColors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.isDirectory ? entry.name : entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                    if (!entry.isDirectory) ...[
                      const SizedBox(height: 3),
                      Text(
                        [entry.extension.replaceFirst('.', '').toUpperCase(), entry.formattedSize]
                            .where((value) => value.isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              const SizedBox(width: 4),
              Icon(
                entry.isDirectory ? Icons.chevron_right_rounded : Icons.play_arrow_rounded,
                size: 20,
                color: entry.isDirectory ? AppColors.textTertiary : AppColors.mint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final favorite = library.isFavorite(song);
    return IconButton(
      onPressed: () async {
        await context.read<LibraryStore>().toggleFavorite(song);
        if (context.mounted) {
          showToast(context, favorite ? '已取消收藏' : '已收藏');
        }
      },
      icon: Icon(
        favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 17,
        color: favorite ? AppColors.pink : AppColors.textTertiary,
      ),
      visualDensity: VisualDensity.compact,
      tooltip: favorite ? '取消收藏' : '收藏',
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 32, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text('连接失败', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, height: 1.6, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: '重试', icon: Icons.refresh_rounded, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _NasServerDialog extends StatefulWidget {
  const _NasServerDialog({required this.store, this.existing});

  final NasStore store;
  final NasServer? existing;

  @override
  State<_NasServerDialog> createState() => _NasServerDialogState();
}

class _NasServerDialogState extends State<_NasServerDialog> {
  late NasProtocol _protocol;
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _root;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _domain;
  bool _useHttps = true;
  bool _allowSelfSigned = false;
  bool _obscure = true;
  bool _testing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _protocol = existing?.protocol ?? NasProtocol.webdav;
    _name = TextEditingController(text: existing?.name ?? '');
    _host = TextEditingController(text: existing?.host ?? '');
    _port = TextEditingController(text: '${existing?.port ?? 443}');
    _root = TextEditingController(text: existing?.rootPath ?? '');
    _username = TextEditingController(text: existing?.username ?? '');
    _password = TextEditingController();
    _domain = TextEditingController(text: existing?.domain ?? 'WORKGROUP');
    _useHttps = existing?.useHttps ?? true;
    _allowSelfSigned = existing?.allowSelfSigned ?? false;
    if (existing != null) {
      widget.store.passwordFor(existing).then((password) {
        if (mounted && password != null && password.isNotEmpty) {
          _password.text = password;
        }
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _root.dispose();
    _username.dispose();
    _password.dispose();
    _domain.dispose();
    super.dispose();
  }

  NasServer _buildServer() {
    final host = _host.text.trim().replaceFirst(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), '');
    final port = int.tryParse(_port.text.trim()) ??
        (_protocol == NasProtocol.smb ? 445 : (_useHttps ? 443 : 80));
    return NasServer(
      id: widget.existing?.id ?? NasServer.newId(),
      name: _name.text.trim().isEmpty ? host : _name.text.trim(),
      protocol: _protocol,
      host: host,
      port: _protocol == NasProtocol.smb ? 445 : port,
      rootPath: _root.text.trim(),
      username: _username.text,
      domain: _domain.text.trim().isEmpty ? 'WORKGROUP' : _domain.text.trim(),
      useHttps: _useHttps,
      allowSelfSigned: _allowSelfSigned,
    );
  }

  Future<void> _test() async {
    final server = _buildServer();
    if (server.host.isEmpty) {
      showToast(context, '请填写服务器地址', error: true);
      return;
    }
    setState(() => _testing = true);
    try {
      final service = context.read<NasService>();
      final password = _password.text.isEmpty && widget.existing != null
          ? (await widget.store.passwordFor(widget.existing!)) ?? ''
          : _password.text;
      final ok = await service.test(server, password);
      if (mounted) showToast(context, ok ? '连接成功，可以读取目录' : '连接失败', error: !ok);
    } catch (error) {
      if (mounted) showToast(context, '连接失败：$error', error: true);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final server = _buildServer();
    if (server.host.isEmpty) {
      showToast(context, '请填写服务器地址', error: true);
      return;
    }
    if (server.name.isEmpty) {
      showToast(context, '请填写一个名称', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.store.save(server, password: _password.text);
      if (mounted) {
        showToast(context, widget.existing == null ? 'NAS 已添加' : 'NAS 已更新');
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 560;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: compact ? 14 : 32, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 530, maxHeight: 720),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_queue_rounded, size: 20, color: AppColors.cyan),
                  const SizedBox(width: 8),
                  Text(
                    widget.existing == null ? '连接 NAS' : '编辑 NAS',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '音频会在播放时缓存到本机；连接信息只保存在这台设备。',
                style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ProtocolTab(
                      label: 'WebDAV',
                      icon: Icons.cloud_rounded,
                      selected: _protocol == NasProtocol.webdav,
                      onTap: () {
                        setState(() {
                          _protocol = NasProtocol.webdav;
                          if (_port.text == '445') _port.text = '443';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProtocolTab(
                      label: 'SMB',
                      icon: Icons.dns_rounded,
                      selected: _protocol == NasProtocol.smb,
                      onTap: () {
                        setState(() {
                          _protocol = NasProtocol.smb;
                          _port.text = '445';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _NasField(controller: _name, label: '显示名称', hint: '例如：客厅 NAS'),
              const SizedBox(height: 10),
              _NasField(
                controller: _host,
                label: '主机 / IP',
                hint: '例如：192.168.1.20 或 nas.local',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              if (_protocol == NasProtocol.webdav)
                Row(
                  children: [
                    Expanded(
                      child: _NasField(
                        controller: _port,
                        label: '端口',
                        hint: '443',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _NasField(
                        controller: _root,
                        label: '路径',
                        hint: '例如 /dav 或留空',
                      ),
                    ),
                  ],
                )
              else
                _NasField(
                  controller: _root,
                  label: '共享名 / 子目录',
                  hint: '例如 media 或 media/Music',
                ),
              const SizedBox(height: 10),
              _NasField(controller: _username, label: '用户名', hint: '可留空'),
              const SizedBox(height: 10),
              _NasField(
                controller: _password,
                label: '密码',
                hint: widget.existing == null ? '可留空' : '留空则保持不变',
                obscureText: _obscure,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 16,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (_protocol == NasProtocol.smb) ...[
                const SizedBox(height: 10),
                _NasField(controller: _domain, label: '域 / 工作组', hint: 'WORKGROUP'),
                const SizedBox(height: 6),
                const Text(
                  'SMB 使用 445 端口，支持 SMB 1 / 2 / 2.1；部分强制 SMB 3 的 NAS 可能无法连接。',
                  style: TextStyle(fontSize: 9, height: 1.5, color: AppColors.textTertiary),
                ),
              ],
              const SizedBox(height: 8),
              if (_protocol == NasProtocol.webdav) ...[
                _DialogSwitch(
                  title: '使用 HTTPS',
                  subtitle: '建议在公网或启用证书的 NAS 上开启',
                  value: _useHttps,
                  onChanged: (value) => setState(() {
                    _useHttps = value;
                    if (_port.text == '443' || _port.text == '80') {
                      _port.text = value ? '443' : '80';
                    }
                  }),
                ),
                _DialogSwitch(
                  title: '允许自签名证书',
                  subtitle: '仅在你信任的家庭 NAS 上开启',
                  value: _allowSelfSigned,
                  onChanged: (value) => setState(() => _allowSelfSigned = value),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing || _saving ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            )
                          : const Icon(Icons.wifi_tethering_rounded, size: 16),
                      label: Text(_testing ? '连接中…' : '测试连接', style: const TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _testing ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mint,
                        foregroundColor: const Color(0xFF04141A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_saving ? '保存中…' : '保存', style: const TextStyle(fontSize: 11.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolTab extends StatelessWidget {
  const _ProtocolTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan.withOpacity(0.1) : Colors.white.withOpacity(0.025),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? AppColors.cyan.withOpacity(0.35) : AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.cyan : AppColors.textTertiary),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NasField extends StatelessWidget {
  const _NasField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
        hintStyle: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
        suffixIcon: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.035),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.cyan.withOpacity(0.5)),
        ),
      ),
    );
  }
}

class _DialogSwitch extends StatelessWidget {
  const _DialogSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 11.5)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.mint,
    );
  }
}
