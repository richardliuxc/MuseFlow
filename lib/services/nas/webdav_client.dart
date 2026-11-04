import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../models/nas_server.dart';
import 'nas_client.dart';
import 'nas_http_client_stub.dart'
    if (dart.library.io) 'nas_http_client_io.dart' as http_factory;

class WebDavNasClient implements NasRemoteClient {
  WebDavNasClient({
    required this.server,
    required this.password,
  }) : _client = http_factory.createNasHttpClient(allowSelfSigned: server.allowSelfSigned);

  final NasServer server;
  final String password;
  final http.Client _client;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Depth': '1',
      'Content-Type': 'application/xml; charset=utf-8',
      'Accept': 'application/xml, text/xml',
    };
    if (server.username.isNotEmpty) {
      headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('${server.username}:$password'))}';
    }
    return headers;
  }

  static const _propfindBody = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:resourcetype/>
    <d:getcontentlength/>
    <d:getcontenttype/>
    <d:getlastmodified/>
  </d:prop>
</d:propfind>''';

  @override
  Future<List<NasEntry>> list(String path) async {
    final uri = server.webDavUri(path);
    final request = http.Request('PROPFIND', uri)
      ..headers.addAll(_headers)
      ..bodyBytes = utf8.encode(_propfindBody);
    http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(const Duration(seconds: 25));
    } catch (error) {
      throw NasException('无法连接 WebDAV 服务器：$error');
    }
    final body = await response.stream.bytesToString();
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const NasException('WebDAV 认证失败，请检查用户名和密码', statusCode: 401);
    }
    if (response.statusCode == 404) {
      throw const NasException('WebDAV 路径不存在', statusCode: 404);
    }
    if (response.statusCode != 207 && response.statusCode != 200) {
      throw NasException('WebDAV 返回 ${response.statusCode}', statusCode: response.statusCode);
    }

    XmlDocument document;
    try {
      document = XmlDocument.parse(body);
    } catch (_) {
      throw const NasException('WebDAV 返回了无法解析的目录数据');
    }

    final requested = _normalize(_relativePath(uri));
    final entries = <NasEntry>[];
    final responses = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'response');

    for (final responseElement in responses) {
      final href = _text(responseElement, 'href');
      if (href == null || href.isEmpty) continue;
      final hrefUri = Uri.tryParse(href);
      if (hrefUri == null) continue;
      var entryPath = _relativePath(hrefUri);
      if (entryPath == requested) continue;
      final prop = _prop(responseElement);
      if (prop == null) continue;
      final isDirectory = prop.descendants
          .whereType<XmlElement>()
          .any((element) => element.name.local == 'collection');
      final displayName = _text(prop, 'displayname');
      final name = (displayName == null || displayName.isEmpty)
          ? _basename(entryPath)
          : displayName;
      if (name.isEmpty) continue;
      entries.add(
        NasEntry(
          name: name,
          path: entryPath,
          isDirectory: isDirectory,
          size: int.tryParse(_text(prop, 'getcontentlength') ?? '') ?? 0,
          contentType: _text(prop, 'getcontenttype') ?? '',
        ),
      );
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  @override
  Future<Stream<List<int>>> read(String path) async {
    final uri = server.webDavUri(path);
    final request = http.Request('GET', uri);
    if (server.username.isNotEmpty) {
      request.headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('${server.username}:$password'))}';
    }
    final response = await _client.send(request).timeout(const Duration(seconds: 30));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const NasException('WebDAV 认证失败');
    }
    if (response.statusCode != 200) {
      throw NasException('WebDAV 下载失败：HTTP ${response.statusCode}',
          statusCode: response.statusCode);
    }
    return response.stream;
  }

  XmlElement? _prop(XmlElement response) {
    for (final propstat in response.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'propstat')) {
      final status = _text(propstat, 'status') ?? '';
      if (!status.contains(' 200 ')) continue;
      for (final prop in propstat.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'prop')) {
        return prop;
      }
    }
    return null;
  }

  String _relativePath(Uri hrefUri) {
    var path = hrefUri.path;
    final base = server.webDavBaseUri().path.replaceAll(RegExp(r'/+$'), '');
    if (base.isNotEmpty && path.startsWith(base)) {
      path = path.substring(base.length);
    }
    path = Uri.decodeComponent(path);
    if (!path.startsWith('/')) path = '/$path';
    if (path.length > 1) path = path.replaceAll(RegExp(r'/+$'), '');
    return path.isEmpty ? '/' : path;
  }

  String _normalize(String path) {
    var value = path;
    if (value.length > 1) value = value.replaceAll(RegExp(r'/+$'), '');
    return value.isEmpty ? '/' : value;
  }

  String _basename(String path) {
    final clean = path.replaceAll(RegExp(r'/+$'), '');
    final index = clean.lastIndexOf('/');
    return index < 0 ? clean : clean.substring(index + 1);
  }

  String? _text(XmlElement parent, String localName) {
    for (final element in parent.descendants.whereType<XmlElement>()) {
      if (element.name.local == localName) {
        final text = element.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  @override
  Future<void> close() async {
    _client.close();
  }
}

