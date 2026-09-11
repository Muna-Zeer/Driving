import 'dart:convert';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
    required XFile
        pickedFile, // Changed from File to XFile for Web compatibility
    required String imageName,
    String category = 'default',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/media-library/upload'),
    );

    request.fields['title'] = imageName;
    request.fields['category'] = category;

    final bytes = await pickedFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: pickedFile.name,
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
  static Future<void> deleteMedia(String id) async{
    final response = await http.delete(Uri.parse('$_baseUrl/media-library/$id'));
    if(response.statusCode !=200){
      throw Exception("Failed to delete media:${response.statusCode}");
    }
  }
 
}

