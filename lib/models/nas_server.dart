import 'dart:convert';

enum NasProtocol { webdav, smb }

extension NasProtocolInfo on NasProtocol {
  String get label => this == NasProtocol.webdav ? 'WebDAV' : 'SMB';
  String get shortLabel => this == NasProtocol.webdav ? 'DAV' : 'SMB';
  String get wireName => this == NasProtocol.webdav ? 'webdav' : 'smb';

  static NasProtocol fromWire(String value) =>
      value == 'smb' ? NasProtocol.smb : NasProtocol.webdav;
}

class NasServer {
  const NasServer({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.rootPath,
    this.username = '',
    this.domain = 'WORKGROUP',
    this.useHttps = true,
    this.allowSelfSigned = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final NasProtocol protocol;
  final String host;
  final int port;

  /// WebDAV base path (e.g. `/dav`) or the SMB share/path (e.g. `media/Music`).
  final String rootPath;
  final String username;
  final String domain;
  final bool useHttps;
  final bool allowSelfSigned;
  final DateTime? createdAt;

  bool get isWebDav => protocol == NasProtocol.webdav;
  bool get isSmb => protocol == NasProtocol.smb;

  String get normalizedRoot {
    var value = rootPath.trim();
    if (value.isEmpty || value == '/') return '';
    if (!value.startsWith('/')) value = '/$value';
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  String get shortAddress {
    final suffix = normalizedRoot.isEmpty ? '' : normalizedRoot;
    return isSmb ? '$host$suffix' : '$host:$port$suffix';
  }

  String get displayHost {
    final hostname = host.trim();
    if (isSmb) return '$hostname${normalizedRoot.isEmpty ? '' : ' · ${normalizedRoot.substring(1)}'}';
    final scheme = useHttps ? 'https' : 'http';
    return '$scheme://$hostname:$port${normalizedRoot.isEmpty ? '' : normalizedRoot}';
  }

  Uri webDavBaseUri() {
    final path = normalizedRoot.isEmpty ? '/' : normalizedRoot;
    return Uri(
      scheme: useHttps ? 'https' : 'http',
      host: host.trim(),
      port: port,
      path: path,
    );
  }

  Uri webDavUri(String path) {
    final base = webDavBaseUri();
    final clean = path.trim().isEmpty ? '/' : (path.startsWith('/') ? path : '/$path');
    final basePath = base.path.replaceAll(RegExp(r'/+$'), '');
    final fullPath = '$basePath$clean'.replaceAll(RegExp(r'/+'), '/');
    return base.replace(path: fullPath);
  }

  /// Path below the configured WebDAV root, e.g. `/Music/album/track.mp3`.
  String relativeToRoot(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    final root = normalizedRoot;
    if (root.isNotEmpty && clean.startsWith(root)) {
      final rest = clean.substring(root.length);
      return rest.isEmpty ? '/' : rest;
    }
    return clean;
  }

  String smbPath(String path) {
    final clean = path.trim();
    if (clean.isEmpty || clean == '/') return normalizedRoot.isEmpty ? '' : normalizedRoot;
    return clean.startsWith('/') ? clean : '/$clean';
  }

  NasServer copyWith({
    String? name,
    NasProtocol? protocol,
    String? host,
    int? port,
    String? rootPath,
    String? username,
    String? domain,
    bool? useHttps,
    bool? allowSelfSigned,
  }) {
    return NasServer(
      id: id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      host: host ?? this.host,
      port: port ?? this.port,
      rootPath: rootPath ?? this.rootPath,
      username: username ?? this.username,
      domain: domain ?? this.domain,
      useHttps: useHttps ?? this.useHttps,
      allowSelfSigned: allowSelfSigned ?? this.allowSelfSigned,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'protocol': protocol.wireName,
        'host': host,
        'port': port,
        'rootPath': rootPath,
        'username': username,
        'domain': domain,
        'useHttps': useHttps,
        'allowSelfSigned': allowSelfSigned,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  static NasServer? fromJson(dynamic value) {
    if (value is! Map) return null;
    final id = value['id']?.toString() ?? '';
    final host = value['host']?.toString() ?? '';
    if (id.isEmpty || host.isEmpty) return null;
    return NasServer(
      id: id,
      name: value['name']?.toString() ?? host,
      protocol: NasProtocolInfo.fromWire(value['protocol']?.toString() ?? 'webdav'),
      host: host,
      port: int.tryParse(value['port']?.toString() ?? '') ??
          (value['protocol']?.toString() == 'smb' ? 445 : 443),
      rootPath: value['rootPath']?.toString() ?? '',
      username: value['username']?.toString() ?? '',
      domain: value['domain']?.toString() ?? 'WORKGROUP',
      useHttps: value['useHttps'] != false,
      allowSelfSigned: value['allowSelfSigned'] == true,
      createdAt: DateTime.tryParse(value['createdAt']?.toString() ?? ''),
    );
  }

  static String newId() => 'nas_${DateTime.now().microsecondsSinceEpoch}';

  String toDebugJson() => jsonEncode(toJson());
}

class NasEntry {
  const NasEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.modified,
    this.contentType = '',
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modified;
  final String contentType;

  static const audioExtensions = {
    '.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg', '.opus', '.wma', '.ape', '.alac', '.aiff', '.m4b'
  };

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot).toLowerCase();
  }

  bool get isAudio => !isDirectory && audioExtensions.contains(extension);

  String get title {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  String get formattedSize {
    if (size <= 0) return '';
    if (size > 1024 * 1024 * 1024) return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    if (size > 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (size > 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '$size B';
  }
}
