import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
  }) : _auth = authService;

  final AuthService _auth;
  AppUser? _user;
  bool _loading = true;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  String? get role => _user?.role;

  ApiClient get apiClient => _auth.apiClient;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _user = await _auth.loadSession();
    _loading = false;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    final res = await _auth.login(email, password);
    if (res.isOk) {
      _user = await _auth.loadSession();
      notifyListeners();
      return null;
    }
    return res.error ?? 'Login failed';
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required bool agreeTerms,
  }) async {
    final res = await _auth.register(
      name: name,
      email: email,
      password: password,
      role: role,
      agreeTerms: agreeTerms,
    );
    if (res.isOk) return null;
    return res.error ?? 'Registration failed';
  }

  Future<String?> forgotPassword(String email) async {
    final res = await _auth.forgotPassword(email);
    if (res.isOk) return null;
    return res.error ?? 'Request failed';
  }

  Future<String?> resetPassword(String email, String password) async {
    final res = await _auth.resetPassword(email, password);
    if (res.isOk) return null;
    return res.error ?? 'Reset failed';
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    notifyListeners();
  }
}
