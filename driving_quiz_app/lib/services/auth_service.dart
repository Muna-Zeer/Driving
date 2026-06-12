import 'dart:convert';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:driving_quiz_app/widgets/drivingAlerts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final baseUrl = APIService.getBaseUrl();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'name': name, 'email': email, 'password': password, 'role': role}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _storage.write(
            key: 'auth_token', value: data['token']?.toString());
        await _storage.write(key: 'user_role', value: data['role']?.toString());

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

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(
            key: 'auth_token', value: data['token']?.toString());
        await _storage.write(key: 'user_role', value: data['role']?.toString());

        return {'status': 'success', 'role': data['role']};
      } else {
        return {
          'status': 'fail',
          'message': data['message'] ?? 'بيانات الدخول غير صحيحة'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'تعذر الاتصال بالخادم، تحقق من الشبكة.'
      };
    }
  }

  Future<Map<String, dynamic>> loginAsGuest(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'user_role', value: data['role']);
        return {'status': 'success', 'role': data['role']};
      } else {
        return {'status': 'fail', 'message': 'فشل الدخول كزائر'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'تعذر الاتصال بالخادم.'};
    }
  }
}
