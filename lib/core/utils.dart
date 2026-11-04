import 'dart:math';

import 'package:flutter/material.dart';

String formatMs(int milliseconds, {bool showHours = false}) {
  final total = (milliseconds / 1000).round().clamp(0, 359999);
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  if (h > 0 || showHours) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatSeconds(int seconds) => formatMs(seconds * 1000);

String formatCount(int value) {
  if (value >= 100000000) return '${(value / 100000000).toStringAsFixed(1)}亿';
  if (value >= 10000) return '${(value / 10000).toStringAsFixed(1)}万';
  return '$value';
}

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 5) return '夜深了';
  if (h < 9) return '早上好';
  if (h < 12) return '上午好';
  if (h < 14) return '中午好';
  if (h < 18) return '下午好';
  if (h < 22) return '晚上好';
  return '夜色正好';
}

String subtitleFor(DateTime now) {
  final h = now.hour;
  if (h < 5) return '把世界调成静音，让旋律陪你到天亮。';
  if (h < 9) return '用一段旋律，唤醒今天的自己。';
  if (h < 12) return '阳光正好，来点轻盈的节拍。';
  if (h < 14) return '午间片刻，让耳朵去旅行。';
  if (h < 18) return '把下午的疲惫，交给一首歌。';
  if (h < 22) return '让声音，替你抵达远方。';
  return '夜深了，听一点温柔的声音。';
}

String formatDate(DateTime time) {
  final now = DateTime.now();
  final date = DateTime(time.year, time.month, time.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(date).inDays;
  if (diff <= 0) return '今天';
  if (diff == 1) return '昨天';
  if (diff < 7) return '$diff 天前';
  return '${time.month} 月 ${time.day} 日';
}

int stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

LinearGradient artworkGradient(String seed, {bool soft = false}) {
  const palettes = [
    [Color(0xFF7C5CFF), Color(0xFF22D3EE)],
    [Color(0xFFF472B6), Color(0xFF8B5CF6)],
    [Color(0xFF34D399), Color(0xFF0EA5E9)],
    [Color(0xFFFBBF24), Color(0xFFFB7185)],
    [Color(0xFF22D3EE), Color(0xFF34D399)],
    [Color(0xFFA78BFA), Color(0xFFF472B6)],
  ];
  final pair = palettes[stableHash(seed) % palettes.length];
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      pair[0].withOpacity(soft ? .7 : 1),
      pair[1].withOpacity(soft ? .7 : 1),
    ],
  );
}

Color accentFor(String seed) {
  const colors = [
    Color(0xFF8B5CF6),
    Color(0xFF22D3EE),
    Color(0xFF34D399),
    Color(0xFFF472B6),
    Color(0xFFFBBF24),
  ];
  return colors[stableHash(seed) % colors.length];
}

String decodeHtml(String input) {
  var out = input
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('\\u0026', '&')
      .replaceAll(RegExp(r'\\&'), '&');
  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1) ?? '');
    return code == null ? m.group(0)! : String.fromCharCode(code);
  });
  out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1) ?? '', radix: 16);
    return code == null ? m.group(0)! : String.fromCharCode(code);
  });
  return out.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String shortNumber(int value) => formatCount(value);

String errorText(Object error) {
  final raw = error.toString();
  if (raw.contains('SocketException') || raw.contains('Connection')) {
    return '网络连接不可用，请检查网络后重试';
  }
  if (raw.contains('TimeoutException') || raw.contains('timed out')) {
    return '请求超时，请稍后再试';
  }
  if (raw.contains('CORS') || raw.contains('XMLHttpRequest')) {
    return '浏览器跨域限制：请使用手机 / 桌面客户端';
  }
  return raw.replaceFirst('Exception: ', '');
}

String truncate(String value, int max) =>
    value.length <= max ? value : '${value.substring(0, max)}…';

List<T> shuffledCopy<T>(List<T> input, [Random? random]) {
  final copy = List<T>.of(input);
  copy.shuffle(random ?? Random());
  return copy;
}
