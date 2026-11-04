import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/lrc.dart';
import '../core/utils.dart';
import '../models/song.dart';
import 'library_store.dart';
import 'music_repository.dart';
import 'music_source.dart';

class PlayerService extends ChangeNotifier {
  PlayerService({
    required MusicRepository repository,
    required LibraryStore library,
  })  : _repository = repository,
        _library = library {
    _configure();
  }

  final MusicRepository _repository;
  final LibraryStore _library;
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  final List<Song> _queue = [];
  int _index = -1;
  final List<int> _shuffleHistory = [];

  ResolvedStream? _stream;
  bool _resolving = false;
  String? _error;
  String? _notice;
  int _noticeSeq = 0;
  int _loadToken = 0;

  double _volume = 0.9;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.all;
  List<LyricLine> _lyrics = const [];
  bool _lyricsLoading = false;
  Timer? _sleepTimer;
  Duration? _sleepRemaining;

  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> buffered = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> sleepRemaining = ValueNotifier(null);

  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _index;
  Song? get current => _index >= 0 && _index < _queue.length ? _queue[_index] : null;
  Song? get playbackSong => _stream?.song;
  String? get playbackSource => _stream?.song.source;
  bool get isResolving => _resolving;
  bool get isBuffering => _resolving || _player.processingState == ProcessingState.loading;
  bool get isPlaying => _player.playing;
  bool get hasTrack => current != null;
  String? get error => _error;
  String? get notice => _notice;
  int get noticeSeq => _noticeSeq;
  double get volume => _volume;
  bool get shuffle => _shuffle;
  RepeatMode get repeat => _repeat;
  List<LyricLine> get lyrics => _lyrics;
  bool get lyricsLoading => _lyricsLoading;
  bool get isSleepTimerActive => _sleepTimer != null;
  bool get hasNext => _queue.isNotEmpty;

  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;

  Future<void> _configure() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (_) {
      // Audio session is best-effort; playback still works on most platforms.
    }

    _player.positionStream.listen((value) {
      position.value = value;
    });
    _player.bufferedPositionStream.listen((value) {
      buffered.value = value;
    });
    _player.durationStream.listen((value) {
      if (value != null && value > Duration.zero) {
        duration.value = value;
      }
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onCompleted();
      }
      notifyListeners();
    });
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (_stream != null) {
          _error = '播放失败：网络或版权限制';
          _resolving = false;
          notifyListeners();
        }
      },
    );
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> playQueue(List<Song> songs, {int startIndex = 0, bool autoPlay = true}) async {
    if (songs.isEmpty) return;
    _queue
      ..clear()
      ..addAll(songs);
    _index = startIndex.clamp(0, _queue.length - 1).toInt();
    _shuffleHistory.clear();
    await _loadCurrent(autoPlay: autoPlay);
  }

  Future<void> playSong(Song song, {List<Song>? queue, int? index}) async {
    if (queue != null && queue.isNotEmpty) {
      final start = index ?? queue.indexWhere((item) => item.uid == song.uid);
      await playQueue(queue, startIndex: start < 0 ? 0 : start);
      return;
    }
    final existing = _queue.indexWhere((item) => item.uid == song.uid);
    if (existing >= 0) {
      _index = existing;
      await _loadCurrent(autoPlay: true);
      return;
    }
    _queue.add(song);
    _index = _queue.length - 1;
    await _loadCurrent(autoPlay: true);
  }

  Future<void> _loadCurrent({required bool autoPlay}) async {
    final song = current;
    if (song == null) return;
    final token = ++_loadToken;
    _resolving = true;
    _error = null;
    _lyrics = const [];
    _lyricsLoading = true;
    duration.value = Duration(milliseconds: song.durationMs);
    position.value = Duration.zero;
    buffered.value = Duration.zero;
    notifyListeners();

    try {
      final localPath = song.extra['file'];
      final ResolvedStream stream;
      if (!kIsWeb && localPath != null && localPath.isNotEmpty) {
        stream = ResolvedStream(url: localPath, song: song, note: null);
        await _player.setFilePath(localPath);
      } else {
        stream = await _repository.resolve(song);
        if (token != _loadToken) return;
        _stream = stream;
        if (stream.isAsset) {
          await _player.setAudioSource(AudioSource.asset(stream.url));
        } else {
          await _player.setUrl(stream.url);
        }
      }
      _stream = stream;
      if (token != _loadToken) return;
      _resolving = false;
      _notice = stream.note;
      if (stream.note != null) _noticeSeq++;
      if (autoPlay) unawaited(_player.play());
      unawaited(_library.recordPlay(song));
      notifyListeners();
      unawaited(_loadLyrics(stream.song));
    } catch (error) {
      if (token != _loadToken) return;
      _resolving = false;
      _error = errorText(error);
      notifyListeners();
    }
  }

  Future<void> _loadLyrics(Song song) async {
    _lyricsLoading = true;
    notifyListeners();
    final lines = await _repository.lyrics(song);
    if (_disposed) return;
    _lyrics = lines;
    _lyricsLoading = false;
    notifyListeners();
  }

  bool _disposed = false;

  Future<void> toggle() async {
    if (current == null) return;
    if (_resolving) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      unawaited(_player.play());
    }
    notifyListeners();
  }

  Future<void> seek(Duration value) async {
    try {
      await _player.seek(value);
      position.value = value;
    } catch (_) {}
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0).toDouble();
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> next({bool manual = true}) async {
    if (_queue.isEmpty) return;
    if (_queue.length == 1) {
      if (manual) {
        await _player.seek(Duration.zero);
        unawaited(_player.play());
      }
      return;
    }
    if (_shuffle && _queue.length > 1) {
      _shuffleHistory.add(_index);
      var nextIndex = _index;
      while (nextIndex == _index && _queue.length > 1) {
        nextIndex = _random.nextInt(_queue.length);
      }
      _index = nextIndex;
    } else {
      _index = _index + 1;
      if (_index >= _queue.length) {
        if (_repeat == RepeatMode.all) {
          _index = 0;
        } else {
          _index = _queue.length - 1;
          await _player.pause();
          await _player.seek(duration.value);
          return;
        }
      }
    }
    await _loadCurrent(autoPlay: true);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    final pos = position.value;
    if (pos.inSeconds > 4) {
      await seek(Duration.zero);
      return;
    }
    if (_shuffle && _shuffleHistory.isNotEmpty) {
      _index = _shuffleHistory.removeLast();
      await _loadCurrent(autoPlay: true);
      return;
    }
    _index = _index - 1;
    if (_index < 0) {
      _index = _repeat == RepeatMode.all ? _queue.length - 1 : 0;
    }
    await _loadCurrent(autoPlay: true);
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    await _loadCurrent(autoPlay: true);
  }

  Future<void> addToQueue(Song song, {bool next = false}) async {
    if (_queue.isEmpty) {
      await playSong(song);
      return;
    }
    if (next) {
      _queue.insert(_index + 1, song);
    } else {
      _queue.add(song);
    }
    notifyListeners();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final removingCurrent = index == _index;
    _queue.removeAt(index);
    if (_queue.isEmpty) {
      _index = -1;
      _stream = null;
      await _player.stop();
      position.value = Duration.zero;
      notifyListeners();
      return;
    }
    if (index < _index) {
      _index--;
    } else if (removingCurrent) {
      _index = _index.clamp(0, _queue.length - 1).toInt();
      await _loadCurrent(autoPlay: _player.playing);
      return;
    }
    notifyListeners();
  }

  Future<void> clearQueue() async {
    _queue.clear();
    _index = -1;
    _stream = null;
    _lyrics = const [];
    await _player.stop();
    position.value = Duration.zero;
    duration.value = Duration.zero;
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _shuffleHistory.clear();
    notifyListeners();
  }

  void cycleRepeat() {
    _repeat = switch (_repeat) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    notifyListeners();
  }

  Future<void> retry() async {
    _error = null;
    await _loadCurrent(autoPlay: true);
  }

  void _onCompleted() {
    if (_repeat == RepeatMode.one) {
      unawaited(() async {
        await _player.seek(Duration.zero);
        await _player.play();
      }());
      return;
    }
    if (_queue.isEmpty) return;
    if (_repeat == RepeatMode.off && _index >= _queue.length - 1) {
      _player.pause();
      return;
    }
    unawaited(next(manual: false));
  }

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepRemaining = duration;
    sleepRemaining.value = duration;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _sleepRemaining;
      if (remaining == null) return;
      final next = remaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        _sleepTimer = null;
        _sleepRemaining = null;
        sleepRemaining.value = null;
        unawaited(_player.pause());
        notifyListeners();
        return;
      }
      _sleepRemaining = next;
      sleepRemaining.value = next;
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepRemaining = null;
    sleepRemaining.value = null;
    notifyListeners();
  }

  void clearNotice() {
    _notice = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _sleepTimer?.cancel();
    _player.dispose();
    position.dispose();
    duration.dispose();
    buffered.dispose();
    sleepRemaining.dispose();
    super.dispose();
  }
}
