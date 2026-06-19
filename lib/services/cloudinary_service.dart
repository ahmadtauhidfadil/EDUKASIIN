import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dgbczkxwg';
  static const String _uploadPreset = 'flutter_upload';

  static Future<String?> uploadFile(File file) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body = await http.Response.fromStream(response);
      if (body.statusCode >= 200 && body.statusCode < 300) {
        final parsed = jsonDecode(body.body) as Map<String, dynamic>?;
        if (parsed != null && parsed.containsKey('secure_url')) {
          return parsed['secure_url'] as String?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
