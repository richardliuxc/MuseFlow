import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createNasHttpClient({required bool allowSelfSigned}) {
  if (!allowSelfSigned) return http.Client();
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..badCertificateCallback = (cert, host, port) => true;
  return IOClient(client);
}
