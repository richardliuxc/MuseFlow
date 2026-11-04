/// Minimal, dependency-free LRC parser with optional translation merging.
class LyricLine {
  const LyricLine({required this.time, required this.text, this.translation});

  final Duration time;
  final String text;
  final String? translation;

  LyricLine copyWith({String? translation}) => LyricLine(
        time: time,
        text: text,
        translation: translation ?? this.translation,
      );

  @override
  String toString() => '[$time] $text';
}

final _tagPattern = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final _offsetPattern = RegExp(r'\[offset:([+-]?\d+)\]', caseSensitive: false);

List<LyricLine> parseLrc(String? raw, {String? translationRaw}) {
  if (raw == null || raw.trim().isEmpty) return const [];
  var offset = 0;
  final offsetMatch = _offsetPattern.firstMatch(raw);
  if (offsetMatch != null) {
    offset = int.tryParse(offsetMatch.group(1) ?? '') ?? 0;
  }
  final main = _parseLines(raw, offset);
  if (translationRaw == null || translationRaw.trim().isEmpty) {
    return main;
  }
  final translated = _parseLines(translationRaw, offset);
  final byMs = <int, String>{};
  for (final line in translated) {
    byMs[line.time.inMilliseconds] = line.text;
  }
  return main
      .map((line) => line.copyWith(
            translation: _closestTranslation(byMs, line.time.inMilliseconds),
          ))
      .toList();
}

String? _closestTranslation(Map<int, String> byMs, int ms) {
  if (byMs.isEmpty) return null;
  final exact = byMs[ms];
  if (exact != null) return exact;
  int? best;
  var bestGap = 1 << 30;
  for (final key in byMs.keys) {
    final gap = (key - ms).abs();
    if (gap < bestGap) {
      bestGap = gap;
      best = key;
    }
  }
  if (best != null && bestGap <= 700) return byMs[best];
  return null;
}

List<LyricLine> _parseLines(String raw, int offsetMs) {
  final result = <LyricLine>[];
  for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final matches = _tagPattern.allMatches(line).toList();
    if (matches.isEmpty) continue;
    final text = line.replaceAll(_tagPattern, '').trim();
    if (text.isEmpty) continue;
    for (final match in matches) {
      final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
      final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
      var fraction = 0;
      final fracRaw = match.group(3);
      if (fracRaw != null) {
        fraction = int.parse(fracRaw.padRight(3, '0').substring(0, 3));
      }
      final ms = minutes * 60000 + seconds * 1000 + fraction + offsetMs;
      result.add(LyricLine(time: Duration(milliseconds: ms), text: text));
    }
  }
  result.sort((a, b) => a.time.compareTo(b.time));
  return result;
}

int activeLyricIndex(List<LyricLine> lines, Duration position) {
  if (lines.isEmpty) return -1;
  var low = 0;
  var high = lines.length - 1;
  var answer = -1;
  while (low <= high) {
    final mid = (low + high) >> 1;
    if (lines[mid].time <= position) {
      answer = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  return answer;
}
