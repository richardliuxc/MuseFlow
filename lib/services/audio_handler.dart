import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'player_service.dart';

/// Bridges [PlayerService] with the Android media notification and iOS
/// Control Center. The actual audio engine remains `just_audio`.
class MuseAudioHandler extends BaseAudioHandler {
  PlayerService? _player;

  void bind(PlayerService player) {
    _player = player;
  }

  @override
  Future<void> play() async {
    await _player?.resumeFromNotification();
  }

  @override
  Future<void> pause() async {
    await _player?.pauseFromNotification();
  }

  @override
  Future<void> skipToNext() async {
    await _player?.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player?.previous();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player?.stopFromNotification();
    await super.stop();
  }

  void updateNowPlaying(Song song) {
    final artUri = song.cover.startsWith('http') ? Uri.tryParse(song.cover) : null;
    mediaItem.add(
      MediaItem(
        id: song.uid,
        title: song.name,
        artist: song.artist,
        album: song.album.isEmpty ? null : song.album,
        duration: song.durationMs > 0 ? Duration(milliseconds: song.durationMs) : null,
        artUri: artUri,
        extras: const {'source': 'MuseFlow'},
      ),
    );
  }

  void syncPlayback(PlayerService player) {
    final song = player.current;
    if (song == null) {
      playbackState.add(
        PlaybackState(
          processingState: AudioProcessingState.idle,
          playing: false,
        ),
      );
      return;
    }

    final processing = player.isResolving
        ? AudioProcessingState.loading
        : switch (player.processingState) {
            ProcessingState.completed => AudioProcessingState.completed,
            ProcessingState.loading => AudioProcessingState.buffering,
            ProcessingState.buffering => AudioProcessingState.buffering,
            _ => AudioProcessingState.ready,
          };

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          player.isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processing,
        playing: player.isPlaying,
        updatePosition: player.position.value,
        bufferedPosition: player.buffered.value,
        speed: 1.0,
        queueIndex: 0,
        repeatMode: switch (player.repeat) {
          RepeatMode.off => AudioServiceRepeatMode.none,
          RepeatMode.all => AudioServiceRepeatMode.all,
          RepeatMode.one => AudioServiceRepeatMode.one,
        },
        shuffleMode: player.shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      ),
    );
  }

  @visibleForTesting
  bool get isBound => _player != null;
}
