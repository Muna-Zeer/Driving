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

  Future<bool> createQuestion(Map<String, dynamic> questionData) async {
    final accessToken = await _storage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/question'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode(questionData),
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> updateQuestion(String questionId, Map<String,dynamic>payload)async{
    final accessToken = await _storage.read(key: 'auth_token');
    final response = await http.put(
      Uri.parse('$baseUrl/question'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode(payload),
    );
    return  response.statusCode == 200;
  }

  Future <bool> deleteQuestion( String questionId)async{
   final token = await _storage.read(key: 'auth_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/question/$questionId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
    
  }
}
