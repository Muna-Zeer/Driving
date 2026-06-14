import 'dart:convert';
import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:http/http.dart' as http;

class CategoryAPI {
  final baseUrl = APIService.getBaseUrl();
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
}
