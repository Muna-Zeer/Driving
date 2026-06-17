import 'dart:convert';
import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CategoryAPI {
  final baseUrl = APIService.getBaseUrl();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        if (decodedData['status'] == true && decodedData['data'] != null) {
          List<dynamic> list = decodedData['data'];
          print(response.body);
          return list.map((item) => CategoryModel.fromJson(item)).toList();
        } else {
          throw Exception('Failed to parse active data structure');
        }
      } else {
        throw Exception(
            'Failed to load categories: Server status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Connection Error: $e');
    }
  }

  Future<http.Response> sendCategoryToAPI(
      Map<String, dynamic> categoryData) async {
    final accessToken = await _storage.read(key: 'auth_token');

    if (accessToken == null) {
      print("No access token found in secure storage");
      throw Exception("User not authenticated");
    }

    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(categoryData),
    );

    return response;
  }
}
