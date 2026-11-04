import 'package:http/http.dart' as http;

http.Client createNasHttpClient({required bool allowSelfSigned}) => http.Client();
