import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'nas_client.dart';

class NasCache {
  Future<Directory> _directory() async {
    final temp = await getTemporaryDirectory();
    final directory = Directory('${temp.path}/nas_cache');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<String?> existing(String key, String extension) async {
    final directory = await _directory();
    final file = File('${directory.path}/$key$extension');
    if (await file.exists() && await file.length() > 0) return file.path;
    return null;
  }

  Future<String> save(String key, String extension, Stream<List<int>> data) async {
    final directory = await _directory();
    final target = File('${directory.path}/$key$extension');
    final part = File('${target.path}.part');
    final sink = part.openWrite();
    try {
      await sink.addStream(data);
      await sink.flush();
    } catch (error) {
      await sink.close();
      if (await part.exists()) await part.delete();
      throw NasException('NAS 文件缓存失败：$error');
    }
    await sink.close();
    if (await target.exists()) await target.delete();
    await part.rename(target.path);
    return target.path;
  }

  Future<void> clear() async {
    final directory = await _directory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
