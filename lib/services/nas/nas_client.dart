import '../../models/nas_server.dart';

class NasException implements Exception {
  const NasException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class NasRemoteClient {
  Future<List<NasEntry>> list(String path);
  Future<Stream<List<int>>> read(String path);
  Future<void> close();
}
