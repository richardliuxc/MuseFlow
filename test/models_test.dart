import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/models/song.dart';

void main() {
  test('Song JSON round trip keeps metadata', () {
    const song = Song(
      id: '186016',
      source: 'netease',
      name: '晴天',
      artist: '周杰伦',
      album: '叶惠美',
      cover: 'https://example.com/cover.jpg',
      durationMs: 269000,
      bitrate: 320,
      extra: {'song_id': '186016', 'quality': 'high'},
    );
    final restored = Song.fromJson(song.toJson());
    expect(restored, isNotNull);
    expect(restored!.id, song.id);
    expect(restored.name, '晴天');
    expect(restored.sourceLabel, '网易云');
    expect(restored.subtitle, '周杰伦 · 叶惠美');
  });

  test('Playlist JSON round trip keeps songs and editorial flag', () {
    const playlist = Playlist(
      id: 'pl_1',
      name: '夜晚',
      description: 'chill',
      cover: 'assets/x.jpg',
      songs: [
        Song(id: '1', source: 'demo', name: '潮汐', artist: 'LUMA'),
        Song(id: '2', source: 'demo', name: '夜航', artist: 'ASTER'),
      ],
      createdAt: 1700000000000,
      isEditorial: true,
    );
    final restored = Playlist.fromJson(playlist.toJson());
    expect(restored, isNotNull);
    expect(restored!.name, '夜晚');
    expect(restored.songs, hasLength(2));
    expect(restored.totalDurationMs, 0);
    expect(restored.artwork, 'assets/x.jpg');
  });

  test('Song.fromJson tolerates malformed payloads', () {
    expect(Song.fromJson(null), isNull);
    expect(Song.fromJson({'id': 'x'})?.name, '');
    expect(Song.fromJson({'id': 1, 'name': 'A', 'source': 'demo'})?.id, '1');
  });
}
