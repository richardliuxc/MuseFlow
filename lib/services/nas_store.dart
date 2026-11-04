import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/nas_server.dart';

class NasStore extends ChangeNotifier {
  NasStore._(this._prefs, this._secure, this._servers);

  static const _configKey = 'nas.servers.v1';
  static const _passwordPrefix = 'nas.password.';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;
  final List<NasServer> _servers;
  final Map<String, String> _memoryPasswords = {};

  List<NasServer> get servers => List.unmodifiable(_servers);

  static Future<NasStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    const secure = FlutterSecureStorage();
    final raw = prefs.getString(_configKey);
    final servers = <NasServer>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          servers.addAll(decoded.map(NasServer.fromJson).whereType<NasServer>());
        }
      } catch (_) {}
    }
    return NasStore._(prefs, secure, servers);
  }

  Future<String?> passwordFor(NasServer server) async {
    try {
      final stored = await _secure.read(key: '$_passwordPrefix${server.id}');
      if (stored != null) return stored;
    } catch (_) {}
    return _memoryPasswords[server.id];
  }

  Future<void> save(NasServer server, {String? password}) async {
    final index = _servers.indexWhere((item) => item.id == server.id);
    if (index >= 0) {
      _servers[index] = server;
    } else {
      _servers.add(server);
    }
    if (password != null && password.isNotEmpty) {
      _memoryPasswords[server.id] = password;
      try {
        await _secure.write(key: '$_passwordPrefix${server.id}', value: password);
      } catch (_) {}
    }
    await _prefs.setString(_configKey, jsonEncode(_servers.map((item) => item.toJson()).toList()));
    notifyListeners();
  }

  Future<void> remove(NasServer server) async {
    _servers.removeWhere((item) => item.id == server.id);
    _memoryPasswords.remove(server.id);
    try {
      await _secure.delete(key: '$_passwordPrefix${server.id}');
    } catch (_) {}
    await _prefs.setString(_configKey, jsonEncode(_servers.map((item) => item.toJson()).toList()));
    notifyListeners();
  }
}
