import 'song.dart';

class RadioStation {
  const RadioStation({
    required this.id,
    required this.name,
    required this.url,
    this.homepage = '',
    this.favicon = '',
    this.tags = const [],
    this.country = '',
    this.countryCode = '',
    this.language = '',
    this.region = '世界',
    this.genre = '综合',
    this.votes = 0,
    this.codec = '',
    this.bitrate = 0,
    this.hls = 0,
    this.featured = false,
  });

  final String id;
  final String name;
  final String url;
  final String homepage;
  final String favicon;
  final List<String> tags;
  final String country;
  final String countryCode;
  final String language;
  final String region;
  final String genre;
  final int votes;
  final String codec;
  final int bitrate;
  final int hls;
  final bool featured;

  bool get isHls => hls == 1;

  String get subtitle =>
      [country, genre].where((value) => value.isNotEmpty).join(' · ');

  Song toSong() => Song(
        id: id,
        source: 'radio',
        name: name,
        artist: subtitle,
        album: 'MuseFlow Radio',
        cover: favicon,
        durationMs: 0,
        bitrate: bitrate,
        extra: {
          'radio': '1',
          'stream': url,
          if (homepage.isNotEmpty) 'homepage': homepage,
          if (region.isNotEmpty) 'region': region,
          if (genre.isNotEmpty) 'genre': genre,
          if (country.isNotEmpty) 'country': country,
          if (countryCode.isNotEmpty) 'countryCode': countryCode,
          if (codec.isNotEmpty) 'codec': codec,
          if (hls == 1) 'hls': '1',
          'votes': '$votes',
        },
      );

  static RadioStation? fromJson(dynamic value) {
    if (value is! Map) return null;
    final id = value['id']?.toString();
    final name = value['name']?.toString();
    final url = value['url']?.toString();
    if (id == null ||
        id.isEmpty ||
        name == null ||
        name.isEmpty ||
        url == null ||
        url.isEmpty) {
      return null;
    }
    return RadioStation(
      id: id,
      name: name,
      url: url,
      homepage: value['homepage']?.toString() ?? '',
      favicon: value['favicon']?.toString() ?? '',
      tags: (value['tags'] as List? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      country: value['country']?.toString() ?? '',
      countryCode: value['countryCode']?.toString() ?? '',
      language: value['language']?.toString() ?? '',
      region: value['region']?.toString() ?? '世界',
      genre: value['genre']?.toString() ?? '综合',
      votes: int.tryParse(value['votes']?.toString() ?? '') ?? 0,
      codec: value['codec']?.toString() ?? '',
      bitrate: int.tryParse(value['bitrate']?.toString() ?? '') ?? 0,
      hls: int.tryParse(value['hls']?.toString() ?? '') ?? 0,
      featured: value['featured'] == true,
    );
  }
}
