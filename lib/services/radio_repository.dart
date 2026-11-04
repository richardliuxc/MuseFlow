import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/radio_station.dart';

/// A compact, curated snapshot generated from the RadioHub SQLite database.
/// The 58 MB source database is intentionally not bundled into the app.
class RadioRepository {
  Future<List<RadioStation>>? _cache;
  List<String> _regions = const ['华语', '欧美', '日韩', '世界'];
  List<String> _genres = const [];

  Future<List<RadioStation>> all() => _cache ??= _load();

  Future<List<RadioStation>> featured() async {
    final stations = await all();
    final featured = stations.where((station) => station.featured).toList();
    return featured.isEmpty ? stations.take(8).toList() : featured;
  }

  List<String> get regions => _regions;
  List<String> get genres => _genres;

  Future<List<RadioStation>> filter({
    String query = '',
    String? region,
    String? genre,
  }) async {
    final stations = await all();
    final q = query.trim().toLowerCase();
    return stations.where((station) {
      if (region != null && region.isNotEmpty && station.region != region)
        return false;
      if (genre != null && genre.isNotEmpty && station.genre != genre)
        return false;
      if (q.isEmpty) return true;
      final haystack =
          '${station.name} ${station.country} ${station.genre} ${station.tags.join(' ')}'
              .toLowerCase();
      return q.split(RegExp(r'\s+')).every(haystack.contains);
    }).toList();
  }

  Future<List<RadioStation>> _load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/radio_stations.json');
      final json = jsonDecode(raw);
      if (json is! Map) return const [];
      final list = (json['stations'] as List? ?? const [])
          .map(RadioStation.fromJson)
          .whereType<RadioStation>()
          .toList();
      final regions = (json['regions'] as List? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList();
      final genres = (json['genres'] as List? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList();
      if (regions.isNotEmpty) _regions = regions;
      if (genres.isNotEmpty) _genres = genres;
      return list;
    } catch (_) {
      return const [];
    }
  }
}
