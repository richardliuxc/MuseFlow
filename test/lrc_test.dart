import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/lrc.dart';

void main() {
  group('parseLrc', () {
    test('parses timestamps, multiple tags and metadata', () {
      const raw = '''
[ti:晴天]
[00:00.00]晴天 - 周杰伦
[00:12.340]故事的小黄花
[00:20.5][00:30.25]从出生那年就飘着
''';
      final lines = parseLrc(raw);
      expect(lines, hasLength(4));
      expect(lines[0].text, '晴天 - 周杰伦');
      expect(lines[1].time, const Duration(milliseconds: 12340));
      expect(lines[2].time, const Duration(milliseconds: 20500));
      expect(lines[3].time, const Duration(milliseconds: 30250));
    });

    test('applies offset', () {
      final lines = parseLrc('[offset:-500]\n[00:01.00]hello');
      expect(lines.single.time, const Duration(milliseconds: 500));
    });

    test('merges translation by close timestamp', () {
      const main = '[00:01.00]Hello\n[00:05.00]World';
      const translation = '[00:01.00]你好\n[00:05.10]世界';
      final lines = parseLrc(main, translationRaw: translation);
      expect(lines[0].translation, '你好');
      expect(lines[1].translation, '世界');
    });

    test('ignores malformed lines and empty input', () {
      expect(parseLrc(null), isEmpty);
      expect(parseLrc('not a lyric'), isEmpty);
      expect(parseLrc('[00:01.00]'), isEmpty);
    });
  });

  group('activeLyricIndex', () {
    final lines = parseLrc('[00:00.00]a\n[00:10.00]b\n[00:20.00]c');

    test('finds active line', () {
      expect(activeLyricIndex(lines, const Duration(seconds: 5)), 0);
      expect(activeLyricIndex(lines, const Duration(seconds: 10)), 1);
      expect(activeLyricIndex(lines, const Duration(seconds: 25)), 2);
    });

    test('returns -1 before first line and for empty list', () {
      expect(activeLyricIndex(lines, const Duration(seconds: -1)), -1);
      expect(activeLyricIndex(const [], Duration.zero), -1);
    });
  });
}
