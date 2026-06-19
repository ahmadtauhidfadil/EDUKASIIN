import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2/edukasin_api';

  static Future<http.Response> post(String path, Map<String, String> body) {
    final uri = Uri.parse('$baseUrl/$path');
    return http.post(uri, body: body).timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> get(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse('$baseUrl/$path').replace(queryParameters: queryParameters);
    return http.get(uri).timeout(const Duration(seconds: 10));
  }
}
