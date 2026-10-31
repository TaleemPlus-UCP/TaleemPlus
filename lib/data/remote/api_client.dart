import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // On Android emulator, localhost is 10.0.2.2; on web/iOS/desktop, it's localhost
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api/v2';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000/api/v2'
        : 'http://localhost:5000/api/v2';
  }

  static const String _accessTokenKey = 'tp_access_token';
  static const String _refreshTokenKey = 'tp_refresh_token';

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<void> setTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {bool withAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers(withAuth: withAuth);
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool withAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers(withAuth: withAuth);
    final response = await http.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body, {bool withAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers(withAuth: withAuth);
    final response = await http.put(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers(withAuth: withAuth);
    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'] ?? body;
    } else {
      final msg = body is Map ? (body['message'] ?? 'API Request failed.') : 'API Request failed.';
      throw Exception(msg);
    }
  }
}
