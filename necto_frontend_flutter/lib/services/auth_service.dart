import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_client.dart';

class AuthService {
  AuthService({required ApiClient api, required SharedPreferences prefs})
      : _api = api,
        _prefs = prefs;

  final ApiClient _api;
  final SharedPreferences _prefs;

  ApiClient get apiClient => _api;

  static const _keyToken = 'necto_token';
  static const _keyUserId = 'necto_user_id';
  static const _keyEmail = 'necto_email';
  static const _keyRole = 'necto_role';
  static const _keyName = 'necto_name';

  Future<void> saveSession({
    required String token,
    required int userId,
    required String email,
    required String role,
    String? name,
  }) async {
    _api.token = token;
    await _prefs.setString(_keyToken, token);
    await _prefs.setInt(_keyUserId, userId);
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyRole, role);
    if (name != null) await _prefs.setString(_keyName, name);
  }

  Future<AppUser?> loadSession() async {
    final token = _prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return null;
    final userId = _prefs.getInt(_keyUserId);
    final email = _prefs.getString(_keyEmail);
    final role = _prefs.getString(_keyRole);
    if (userId == null || email == null || role == null) return null;
    _api.token = token;
    return AppUser(
      id: userId,
      email: email,
      role: role,
      name: _prefs.getString(_keyName),
    );
  }

  Future<void> logout() async {
    _api.token = null;
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyRole);
    await _prefs.remove(_keyName);
  }

  // --- API calls ---

  Future<ApiResponse> login(String email, String password) async {
    final res = await _api.post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    if (res.isOk && res.data != null) {
      final token = res.data!['token'] as String?;
      final role = res.data!['role'] as String?;
      final id = res.data!['id'];
      if (token != null && role != null && id != null) {
        await saveSession(
          token: token,
          userId: id is int ? id : int.tryParse(id.toString()) ?? 0,
          email: email.trim(),
          role: role,
        );
      }
    }
    return res;
  }

  Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required bool agreeTerms,
  }) async {
    return _api.post('/api/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'role': role,
      'agree_terms': agreeTerms,
    });
  }

  Future<ApiResponse> forgotPassword(String email) async {
    return _api.post('/api/auth/forgot-password', {'email': email.trim()});
  }

  Future<ApiResponse> resetPassword(String email, String password) async {
    return _api.post('/api/auth/reset-password', {
      'email': email.trim(),
      'password': password,
    });
  }
}
