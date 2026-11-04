import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

class LibraryStore extends ChangeNotifier {
  LibraryStore._(this._prefs);

  static const _key = 'museflow.library.v1';
  final SharedPreferences _prefs;

  final List<Song> _favorites = [];
  final List<Playlist> _playlists = [];
  final List<Song> _history = [];
  final List<DownloadedTrack> _downloads = [];
  final List<String> _searches = [];

  List<Song> get favorites => List.unmodifiable(_favorites);
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Song> get history => List.unmodifiable(_history);
  List<DownloadedTrack> get downloads => List.unmodifiable(_downloads);
  List<String> get searches => List.unmodifiable(_searches);

  bool get isEmpty => _favorites.isEmpty && _playlists.isEmpty && _history.isEmpty;

  static Future<LibraryStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore._(prefs);
    store._restore();
    return store;
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _favorites
        ..clear()
        ..addAll(
          (json['favorites'] as List? ?? const [])
              .map(Song.fromJson)
              .whereType<Song>(),
        );
      _playlists
        ..clear()
        ..addAll(
          (json['playlists'] as List? ?? const [])
              .map(Playlist.fromJson)
              .whereType<Playlist>(),
        );
      _history
        ..clear()
        ..addAll(
          (json['history'] as List? ?? const [])
              .map(Song.fromJson)
              .whereType<Song>(),
        );
      _downloads
        ..clear()
        ..addAll(
          (json['downloads'] as List? ?? const [])
              .map(DownloadedTrack.fromJson)
              .whereType<DownloadedTrack>(),
        );
      _searches
        ..clear()
        ..addAll((json['searches'] as List? ?? const []).map((e) => e.toString()));
    } catch (_) {
      // Corrupted store: start fresh rather than blocking the app.
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'favorites': _favorites.map((song) => song.toJson()).toList(),
        'playlists': _playlists.map((playlist) => playlist.toJson()).toList(),
        'history': _history.map((song) => song.toJson()).toList(),
        'downloads': _downloads.map((track) => track.toJson()).toList(),
        'searches': _searches,
      }),
    );
  }

  bool isFavorite(Song song) => _favorites.any((item) => item.uid == song.uid);

  Future<bool> toggleFavorite(Song song) async {
    final exists = isFavorite(song);
    if (exists) {
      _favorites.removeWhere((item) => item.uid == song.uid);
    } else {
      _favorites.insert(0, song);
    }
    notifyListeners();
    await _persist();
    return !exists;
  }

  Future<void> removeFavorite(Song song) async {
    _favorites.removeWhere((item) => item.uid == song.uid);
    notifyListeners();
    await _persist();
  }

  Future<void> recordPlay(Song song) async {
    _history.removeWhere((item) => item.uid == song.uid);
    _history.insert(0, song);
    if (_history.length > 50) {
      _history.removeRange(50, _history.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await _persist();
  }

  Future<Playlist> createPlaylist({
    required String name,
    String description = '',
    String cover = '',
    List<Song> songs = const [],
  }) async {
    final playlist = Playlist(
      id: 'pl_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999)}',
      name: name.trim().isEmpty ? '我的歌单' : name.trim(),
      description: description.trim(),
      cover: cover,
      songs: List.of(songs),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _playlists.insert(0, playlist);
    notifyListeners();
    await _persist();
    return playlist;
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((playlist) => playlist.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> renamePlaylist(String id, String name) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index < 0) return;
    _playlists[index] = _playlists[index].copyWith(name: name.trim());
    notifyListeners();
    await _persist();
  }

  Future<int> addToPlaylist(String playlistId, List<Song> songs) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index < 0) return 0;
    final existing = _playlists[index].songs.map((song) => song.uid).toSet();
    final incoming = songs.where((song) => !existing.contains(song.uid)).toList();
    if (incoming.isEmpty) return 0;
    final updated = _playlists[index].copyWith(
      songs: [..._playlists[index].songs, ...incoming],
      cover: _playlists[index].cover.isEmpty ? incoming.first.cover : null,
    );
    _playlists[index] = updated;
    notifyListeners();
    await _persist();
    return incoming.length;
  }

  Future<void> removeFromPlaylist(String playlistId, Song song) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index < 0) return;
    final songs = List<Song>.of(_playlists[index].songs)
      ..removeWhere((item) => item.uid == song.uid);
    _playlists[index] = _playlists[index].copyWith(songs: songs);
    notifyListeners();
    await _persist();
  }

  Future<void> recordSearch(String keyword) async {
    final value = keyword.trim();
    if (value.isEmpty) return;
    _searches.remove(value);
    _searches.insert(0, value);
    if (_searches.length > 10) {
      _searches.removeRange(10, _searches.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clearSearches() async {
    _searches.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> addDownload(DownloadedTrack track) async {
    _downloads.removeWhere((item) => item.song.uid == track.song.uid);
    _downloads.insert(0, track);
    notifyListeners();
    await _persist();
  }

  Future<void> removeDownload(DownloadedTrack track) async {
    _downloads.removeWhere((item) => item.path == track.path);
    notifyListeners();
    await _persist();
  }
}
