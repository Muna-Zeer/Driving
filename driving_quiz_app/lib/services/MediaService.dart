import 'dart:convert';
import 'dart:io';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:http/http.dart' as http;

class MediaService {
  static String get _baseUrl => APIService.getBaseUrl();

  static Future<List<dynamic>> fetchMediaLibrary() async {
    final response = await http.get(Uri.parse('$_baseUrl/media-library'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch media library');
    }
  }

  static Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    required String imageName,
    String category = 'default',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/media-library/upload'),
    );

    request.fields['title'] = imageName;
    request.fields['category'] = category;
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  }
}
