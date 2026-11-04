import 'package:http/http.dart' as http;

/// Web fallback: offline downloads are not supported by the browser build.
class DownloadStorage {
  bool get supported => false;

  Future<String> saveBytes(String filename, List<int> bytes) async {
    throw UnsupportedError('当前平台不支持离线下载');
  }

  Future<String> saveStream(
    String filename,
    http.StreamedResponse response, {
    void Function(int received, int total)? onProgress,
  }) async {
    throw UnsupportedError('当前平台不支持离线下载');
  }

  Future<bool> exists(String path) async => false;

  Future<void> delete(String path) async {}
}
