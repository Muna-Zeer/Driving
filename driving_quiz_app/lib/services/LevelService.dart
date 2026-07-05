import 'dart:convert';
import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/models/levelModel.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LevelService {
  final baseUrl = APIService.getBaseUrl();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  Future<List<Level>> fetchLevels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/level'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        if (decodedData['status'] == true && decodedData['data'] != null) {
          List<dynamic> list = decodedData['data'];
          print(response.body);
          return list.map((item) => Level.fromJson(item)).toList();
        } else {
          throw Exception('Failed to parse active data structure');
        }
      } else {
        throw Exception(
            'Failed to load levels: Server status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Connection Error: $e');
    }
  }

  Future<http.Response> sendLevelToAPI(Map<String, dynamic> levelData) async {
    final accessToken = await _storage.read(key: 'auth_token');

    if (accessToken == null) {
      print("No access token found in secure storage");
      throw Exception("User not authenticated");
    }

    final response = await http.post(
      Uri.parse('$baseUrl/level'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(levelData),
    );

    return response;
  }

  Future<http.Response> deleteLevelFromAPI(String hashId) async {
    final accessToken = await _storage.read(key: 'auth_token');
    if (accessToken == null) {
      throw Exception("User not Authorized");
    }
    final $response =
        await http.delete(Uri.parse('$baseUrl/level/$hashId'), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken'
    });

    return $response;
  }
}
