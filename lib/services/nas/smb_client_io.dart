import 'dart:async';
import 'dart:typed_data';

import 'package:smb_connect/smb_connect.dart';

import '../../models/nas_server.dart';
import 'nas_client.dart';

NasRemoteClient createSmbClient(NasServer server, String password) =>
    SmbNasClient(server: server, password: password);

class SmbNasClient implements NasRemoteClient {
  SmbNasClient({required this.server, required this.password});

  final NasServer server;
  final String password;
  SmbConnect? _connect;

  Future<SmbConnect> _connection() async {
    if (_connect != null) return _connect!;
    try {
      _connect = await SmbConnect.connectAuth(
        host: server.host.trim(),
        domain: server.domain.trim().isEmpty ? 'WORKGROUP' : server.domain.trim(),
        username: server.username,
        password: password,
      );
      return _connect!;
    } catch (error) {
      throw NasException('SMB 连接失败：$error');
    }
  }

  @override
  Future<List<NasEntry>> list(String path) async {
    final connect = await _connection();
    try {
      final target = server.smbPath(path);
      if (target.isEmpty) {
        final shares = await connect.listShares();
        return shares
            .where((share) => share.name.isNotEmpty && share.name != '.' && share.name != '..')
            .map((share) => NasEntry(
                  name: share.name,
                  path: share.path.startsWith('/') ? share.path : '/${share.path}',
                  isDirectory: true,
                  size: share.size,
                ))
            .toList();
      }
      final folder = await connect.file(target);
      if (!folder.isExists) {
        throw const NasException('SMB 路径不存在');
      }
      final files = await connect.listFiles(folder);
      final entries = files
          .where((file) => file.name.isNotEmpty && file.name != '.' && file.name != '..')
          .map((file) => NasEntry(
                name: file.name,
                path: file.path.startsWith('/') ? file.path : '/${file.path}',
                isDirectory: file.isDirectory(),
                size: file.size,
              ))
          .toList();
      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return entries;
    } catch (error) {
      if (error is NasException) rethrow;
      throw NasException('读取 SMB 目录失败：$error');
    }
  }

  @override
  Future<Stream<List<int>>> read(String path) async {
    final connect = await _connection();
    try {
      final target = server.smbPath(path);
      final file = await connect.file(target);
      if (!file.isExists || file.isDirectory()) {
        throw const NasException('SMB 音频文件不存在');
      }
      final stream = await connect.openRead(file);
      return stream.map<List<int>>((chunk) => Uint8List.fromList(chunk));
    } catch (error) {
      if (error is NasException) rethrow;
      throw NasException('读取 SMB 文件失败：$error');
    }
  }

  @override
  Future<void> close() async {
    final connect = _connect;
    _connect = null;
    if (connect != null) {
      try {
        await connect.close();
      } catch (_) {}
    }
  }
}
