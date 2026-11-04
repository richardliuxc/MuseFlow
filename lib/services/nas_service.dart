import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/nas_server.dart';
import '../models/song.dart';
import 'nas/nas_cache_stub.dart'
    if (dart.library.io) 'nas/nas_cache_io.dart';
import 'nas/nas_client.dart';
import 'nas/smb_client_stub.dart'
    if (dart.library.io) 'nas/smb_client_io.dart';
import 'nas/webdav_client.dart';
import 'nas_store.dart';

class NasService {
  NasService({required this.store});

  final NasStore store;
  final NasCache _cache = NasCache();
  final Map<String, Future<String>> _inflight = {};

  NasServer? serverById(String id) {
    for (final server in store.servers) {
      if (server.id == id) return server;
    }
    return null;
  }

  NasRemoteClient _client(NasServer server, String password) {
    if (server.isSmb) return createSmbClient(server, password);
    return WebDavNasClient(server: server, password: password);
  }

  Future<List<NasEntry>> list(NasServer server, String path) async {
    final password = await store.passwordFor(server) ?? '';
    final client = _client(server, password);
    try {
      return await client.list(path);
    } finally {
      await client.close();
    }
  }

  Future<bool> test(NasServer server, String password) async {
    final client = _client(server, password);
    try {
      await client.list('/');
      return true;
    } finally {
      await client.close();
    }
  }

  Future<String> materialize(Song song) {
    final serverId = song.extra['nasServer'];
    final path = song.extra['nasPath'];
    if (serverId == null || path == null) {
      throw const NasException('NAS 音频信息不完整');
    }
    final server = serverById(serverId);
    if (server == null) {
      throw const NasException('NAS 服务器已被移除，请在音乐库重新连接');
    }
    return materializePath(
      server,
      path,
      name: song.extra['nasName'] ?? song.name,
      size: int.tryParse(song.extra['nasSize'] ?? '') ?? 0,
    );
  }

  Future<String> materializePath(
    NasServer server,
    String path, {
    String? name,
    int size = 0,
  }) async {
    if (kIsWeb) {
      throw const NasException('Web 端暂不支持 NAS 音频缓存，请使用 App 或桌面端');
    }
    final fileName = name ?? path.split('/').last;
    final dot = fileName.lastIndexOf('.');
    final extension = dot > 0 ? fileName.substring(dot).toLowerCase() : '.mp3';
    final safeExtension = RegExp(r'^\.[a-z0-9]{1,6}$').hasMatch(extension) ? extension : '.mp3';
    final key = sha1
        .convert(utf8.encode('${server.id}|$path|$size'))
        .toString()
        .substring(0, 32);
    final existing = await _cache.existing(key, safeExtension);
    if (existing != null) return existing;
    return _inflight.putIfAbsent(key, () async {
      final password = await store.passwordFor(server) ?? '';
      final client = _client(server, password);
      try {
        final stream = await client.read(path);
        return await _cache.save(key, safeExtension, stream);
      } finally {
        await client.close();
        _inflight.remove(key);
      }
    });
  }

  Future<void> clearCache() => _cache.clear();
}
