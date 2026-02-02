import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final apiClient = ApiClient();
  final authService = AuthService(api: apiClient, prefs: prefs);

  runApp(
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(authService: authService)..init(),
      child: const NectoApp(),
    ),
  );
}
