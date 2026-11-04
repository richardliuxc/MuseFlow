import '../../models/nas_server.dart';
import 'nas_client.dart';

NasRemoteClient createSmbClient(NasServer server, String password) => _UnsupportedSmbClient();

class _UnsupportedSmbClient implements NasRemoteClient {
  @override
  Future<List<NasEntry>> list(String path) async {
    throw const NasException('当前平台不支持 SMB，请使用 Android / iOS / macOS 客户端');
  }

  @override
  Future<Stream<List<int>>> read(String path) async {
    throw const NasException('当前平台不支持 SMB，请使用 Android / iOS / macOS 客户端');
  }

  @override
  Future<void> close() async {}
}
