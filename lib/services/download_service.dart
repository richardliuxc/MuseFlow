import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/song.dart';
import 'download_storage_stub.dart' if (dart.library.io) 'download_storage_io.dart';
import 'library_store.dart';
import 'music_repository.dart';

class DownloadService extends ChangeNotifier {
  DownloadService({required MusicRepository repository, required LibraryStore library})
      : _repository = repository,
        _library = library;

  final MusicRepository _repository;
  final LibraryStore _library;
  final DownloadStorage _storage = DownloadStorage();
  final Map<String, double> _progress = {};
  final Set<String> _active = {};

  bool get isSupported => _storage.supported;
  Map<String, double> get progress => Map.unmodifiable(_progress);

  bool isDownloading(Song song) => _active.contains(song.uid);
  bool isDownloaded(Song song) => _library.downloads.any((track) => track.song.uid == song.uid);
  double? progressFor(Song song) => _progress[song.uid];

  Future<DownloadedTrack> download(Song song) async {
    if (!_storage.supported) {
      throw UnsupportedError('Web 端暂不支持离线下载，请使用 App 或桌面端');
    }
    if (_active.contains(song.uid)) {
      throw StateError('该歌曲正在下载中');
    }
    final existing = _library.downloads
        .where((track) => track.song.uid == song.uid)
        .toList();
    for (final track in existing) {
      if (await _storage.exists(track.path)) return track;
    }

    _active.add(song.uid);
    _progress[song.uid] = 0;
    notifyListeners();

    try {
      final resolved = await _repository.resolve(song);
      final filename = _filenameFor(song, resolved.url);
      String path;
      if (resolved.isAsset) {
        final data = await rootBundle.load(resolved.url);
        path = await _storage.saveBytes(filename, data.buffer.asUint8List());
      } else {
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(resolved.url));
          request.headers['User-Agent'] = 'MuseFlow/1.0';
          final response = await client
              .send(request)
              .timeout(const Duration(seconds: 30));
          if (response.statusCode >= 400) {
            throw Exception('下载失败（${response.statusCode}）');
          }
          path = await _storage.saveStream(
            filename,
            response,
            onProgress: (received, total) {
              if (total > 0) {
                _progress[song.uid] = (received / total).clamp(0.0, 1.0).toDouble();
                notifyListeners();
              }
            },
          );
        } finally {
          client.close();
        }
      }
      _progress[song.uid] = 1;
      final track = DownloadedTrack(
        song: resolved.song,
        path: path,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _library.addDownload(track);
      return track;
    } finally {
      _active.remove(song.uid);
      _progress.remove(song.uid);
      notifyListeners();
    }
  }

  Future<void> remove(DownloadedTrack track) async {
    await _storage.delete(track.path);
    await _library.removeDownload(track);
    notifyListeners();
  }

  String _filenameFor(Song song, String url) {
    final safe = '${song.artist} - ${song.name}'
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final uri = Uri.tryParse(url);
    final extension = (uri?.path.split('.').last ?? '').toLowerCase();
    final ext = const {'mp3', 'flac', 'm4a', 'aac', 'ogg', 'wav'}.contains(extension)
        ? extension
        : 'mp3';
    final base = safe.isEmpty ? 'MuseFlow_${song.id}' : safe;
    return '$base.$ext';
  }
}
