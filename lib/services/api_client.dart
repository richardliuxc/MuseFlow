import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MusicApiException implements Exception {
  MusicApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const mobileUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0 Safari/537.36';

  static const _forbiddenOnWeb = {
    'user-agent',
    'referer',
    'cookie',
    'origin',
    'host',
  };

  Map<String, String> _headers(Map<String, String>? headers) {
    final result = <String, String>{
      'Accept': 'application/json, text/plain, */*',
      'User-Agent': mobileUserAgent,
    };
    if (headers != null) result.addAll(headers);
    if (kIsWeb) {
      result.removeWhere((key, _) => _forbiddenOnWeb.contains(key.toLowerCase()));
    }
    return result;
  }

  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      return await _client
          .get(Uri.parse(url), headers: _headers(headers))
          .timeout(timeout);
    } on TimeoutException {
      throw MusicApiException('请求超时，请检查网络');
    } on http.ClientException catch (error) {
      throw MusicApiException(_networkMessage(error));
    } catch (error) {
      throw MusicApiException(_networkMessage(error));
    }
  }

  Future<http.Response> postJson(
    String url, {
    required Object body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      return await _client
          .post(
            Uri.parse(url),
            headers: _headers({
              'Content-Type': 'application/json',
              ...?headers,
            }),
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw MusicApiException('请求超时，请检查网络');
    } on http.ClientException catch (error) {
      throw MusicApiException(_networkMessage(error));
    } catch (error) {
      throw MusicApiException(_networkMessage(error));
    }
  }

  Future<http.Response> postForm(
    String url, {
    required Map<String, String> form,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      return await _client
          .post(
            Uri.parse(url),
            headers: _headers({
              'Content-Type': 'application/x-www-form-urlencoded',
              ...?headers,
            }),
            body: Uri(queryParameters: form).query,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw MusicApiException('请求超时，请检查网络');
    } on http.ClientException catch (error) {
      throw MusicApiException(_networkMessage(error));
    } catch (error) {
      throw MusicApiException(_networkMessage(error));
    }
  }

  /// Issues a HEAD request to validate a stream URL without downloading it.
  Future<bool> isPlayable(String url) async {
    try {
      final response = await _client
          .head(Uri.parse(url), headers: _headers(null))
          .timeout(const Duration(seconds: 8));
      final type = response.headers['content-type'] ?? '';
      if (response.statusCode >= 400) return false;
      if (type.contains('text/html')) return false;
      return type.contains('audio') ||
          type.contains('octet-stream') ||
          type.contains('mpeg') ||
          response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> getText(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final response = await get(url, headers: headers, timeout: timeout);
    _ensureOk(response);
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final text = await getText(url, headers: headers, timeout: timeout);
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      throw MusicApiException('接口返回格式异常');
    } on FormatException {
      throw MusicApiException('接口返回格式异常');
    }
  }

  Future<Map<String, dynamic>> postJsonForMap(
    String url, {
    required Object body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final response = await postJson(url, body: body, headers: headers, timeout: timeout);
    _ensureOk(response);
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      throw MusicApiException('接口返回格式异常');
    } on FormatException {
      throw MusicApiException('接口返回格式异常');
    }
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 400) {
      throw MusicApiException('音源暂时不可用（${response.statusCode}）');
    }
  }

  String _networkMessage(Object error) {
    final raw = error.toString();
    if (kIsWeb) {
      return '浏览器跨域限制：该音源仅支持 App / 桌面端';
    }
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return '网络连接失败，请检查网络';
    }
    if (raw.contains('Connection closed') || raw.contains('Connection reset')) {
      return '连接被中断，请稍后重试';
    }
    return '音源请求失败，请稍后重试';
  }

  void dispose() => _client.close();
}
