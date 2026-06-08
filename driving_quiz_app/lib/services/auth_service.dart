import 'dart:convert';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:driving_quiz_app/widgets/drivingAlerts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final baseUrl = APIService.getBaseUrl();
  final _storage = const FlutterSecureStorage();
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'role': role
          }));
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'user_role', value: data['role']);
        return {'status': 'success', 'role': data['role']};
      } else {
        return {'status': 'fail', 'message': data['errors'] ?? data['message']};
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'تعذر الاتصال بالخادم، تحقق من شبكة الإنترنت.'
      };
    }
  }
}
