import 'dart:convert';
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
  Future<List<Level>> fetchLevelsForCategory(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId/levels'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic> &&
            decoded['status'] == true &&
            decoded['data'] != null &&
            decoded['data'] is List) {
          // ✅ Safe cast using List.from
          final List<dynamic> list = List<dynamic>.from(decoded['data']);

          return list.map((item) {
            if (item is Map<String, dynamic>) {
              return Level.fromJson(item);
            }
            {
              throw Exception('Invalid item format in levels list');
            }
          }).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Server returned status ${response.statusCode}');
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
