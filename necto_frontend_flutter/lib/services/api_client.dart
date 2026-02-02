import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiClient {
  ApiClient({this.token});

  String? token;
  final String _base = kApiBaseUrl;

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  Future<ApiResponse> get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$_base$path'),
        headers: _headers,
      );
      return _handleResponse(res);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> post(String path, Map<String, dynamic>? body) async {
    try {
      final res = await http.post(
        Uri.parse('$_base$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(res);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  ApiResponse _handleResponse(http.Response res) {
    final decoded = res.body.isNotEmpty
        ? (jsonDecode(res.body) as Map<String, dynamic>?)
        : null;
    final errorMsg = decoded?['error'] as String?;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ApiResponse(data: decoded, statusCode: res.statusCode);
    }
    return ApiResponse.error(
      errorMsg ?? 'Request failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }
}

class ApiResponse {
  ApiResponse({this.data, this.statusCode});

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      data: {'error': message},
      statusCode: statusCode ?? 0,
    );
  }

  final Map<String, dynamic>? data;
  final int? statusCode;

  bool get isOk => statusCode != null && statusCode! >= 200 && statusCode! < 300;
  String? get error => data?['error'] as String?;
}
