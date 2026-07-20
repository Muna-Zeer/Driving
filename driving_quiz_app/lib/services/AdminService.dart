import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  String _userRole = '';
  String get userRole => _userRole;
  bool get isAdmin => _userRole == 'admin' || _userRole == 'super_admin';
  Future<String> loadUserRole() async {
    String? role = await _storage.read(key: 'user_role');
    if (role != null) {
      _userRole = role.trim();
    }
    return _userRole;
  }
}
