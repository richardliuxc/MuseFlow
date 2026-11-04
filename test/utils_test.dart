import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/utils.dart';

void main() {
  test('formatMs renders minutes and hours', () {
    expect(formatMs(0), '0:00');
    expect(formatMs(65000), '1:05');
    expect(formatMs(3723000), '1:02:03');
    expect(formatMs(-500), '0:00');
  });

  test('decodeHtml resolves common entities and whitespace', () {
    expect(
      decodeHtml('Guns&nbsp;N&apos;&nbsp;Roses &amp; Friends'),
      "Guns N' Roses & Friends",
    );
    expect(decodeHtml('A\\u0026B'), 'A&B');
  });

  test('stableHash is deterministic and non-negative', () {
    expect(stableHash('MuseFlow'), stableHash('MuseFlow'));
    expect(stableHash('MuseFlow'), greaterThanOrEqualTo(0));
    expect(stableHash('A'), isNot(stableHash('B')));
  });

  test('greeting covers the whole day', () {
    expect(greetingFor(DateTime(2026, 1, 1, 2)), '夜深了');
    expect(greetingFor(DateTime(2026, 1, 1, 8)), '早上好');
    expect(greetingFor(DateTime(2026, 1, 1, 20)), '晚上好');
  });

  test('truncate keeps short strings intact', () {
    expect(truncate('MuseFlow', 10), 'MuseFlow');
    expect(truncate('MuseFlow', 4), 'Muse…');
  });

  test('formatCount compacts large numbers', () {
    expect(formatCount(999), '999');
    expect(formatCount(12345), '1.2万');
  });
}
