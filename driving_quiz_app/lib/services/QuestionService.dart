import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driving_quiz_app/services/APIService.dart';

class QuestionService {
  final baseUrl = APIService.getBaseUrl();
  final _storage = const FlutterSecureStorage();

  Future<List<dynamic>> fetchQuestionForLevel(String levelId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/levels/$levelId/questions'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['data'] ?? [];
    }
    throw Exception('Failed to load questions for level ');
  }
}
