import 'nas_client.dart';

class NasCache {
  Future<String?> existing(String key, String extension) async => null;

  Future<String> save(String key, String extension, Stream<List<int>> data) async {
    throw const NasException('NAS 缓存仅在 App / 桌面端可用');
  }

  Future<void> clear() async {}
}
