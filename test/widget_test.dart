import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/theme.dart';
import 'package:museflow/models/song.dart';
import 'package:museflow/ui/widgets/song_tile.dart';

void main() {
  const song = Song(
    id: 'demo_01',
    source: 'demo',
    name: '潮汐',
    artist: 'LUMA',
    album: 'Aurora Sessions',
    cover: 'assets/images/covers/cover_01.jpg',
    durationMs: 44700,
  );

  testWidgets('SongTile shows title, subtitle and duration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: SongTile(
            song: song,
            index: 1,
            showCover: false,
            showNumber: true,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('潮汐'), findsOneWidget);
    expect(find.text('LUMA · Aurora Sessions'), findsOneWidget);
    expect(find.text('0:45'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
  });

  testWidgets('SongTile fires tap callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SongTile(
            song: song,
            showCover: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('潮汐'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
