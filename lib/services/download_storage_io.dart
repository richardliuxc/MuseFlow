import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadStorage {
  bool get supported => true;

  Future<Directory> _directory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}MuseFlow'
        '${Platform.pathSeparator}Downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> saveBytes(String filename, List<int> bytes) async {
    final dir = await _directory();
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> saveStream(
    String filename,
    http.StreamedResponse response, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await _directory();
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    final sink = file.openWrite();
    var received = 0;
    final total = response.contentLength ?? 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return file.path;
  }

  Future<bool> exists(String path) => File(path).exists();

  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
