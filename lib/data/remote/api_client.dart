import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Override the API origin at build/run time without editing source:
  ///   flutter run -d chrome --dart-define=API_BASE_URL=https://api.example.com/api/v2
  /// During local development the per-platform defaults below are used.
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');
  static const Duration _requestTimeout = Duration(seconds: 20);

  // On Android emulator, localhost is 10.0.2.2; on web/iOS/desktop, it's localhost.
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.endsWith('/')
          ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
          : _configuredBaseUrl;
    }
    if (kIsWeb) return 'http://localhost:5000/api/v2';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000/api/v2'
        : 'http://localhost:5000/api/v2';
  }

  static const String _accessTokenKey = 'tp_access_token';
  static const String _refreshTokenKey = 'tp_refresh_token';
  Future<bool>? _refreshInProgress;

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getStoredRefreshToken() => _getRefreshToken();

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> setTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
    _refreshToken = refresh;
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    _refreshToken = null;
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

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'The API request timed out. Check that the TaleemPlus backend is '
        'running at $baseUrl and try again.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Could not reach the TaleemPlus API at $baseUrl. Make sure the '
        'backend is running and that CORS allows this origin. (${e.message})',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Network error while contacting the TaleemPlus API at $baseUrl: $e',
      );
    }
  }

  Future<dynamic> get(String endpoint, {bool withAuth = true}) async {
    return _request('GET', endpoint, withAuth: withAuth);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body,
      {bool withAuth = true}) async {
    return _request('POST', endpoint, body: body, withAuth: withAuth);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body,
      {bool withAuth = true}) async {
    return _request('PUT', endpoint, body: body, withAuth: withAuth);
  }

  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    return _request('DELETE', endpoint, withAuth: withAuth);
  }

  Future<dynamic> _request(String method, String endpoint,
      {Map<String, dynamic>? body, required bool withAuth}) async {
    Future<http.Response> send() async {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _headers(withAuth: withAuth);
      final encoded = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'POST':
          return _send(http.post(uri, headers: headers, body: encoded));
        case 'PUT':
          return _send(http.put(uri, headers: headers, body: encoded));
        case 'DELETE':
          return _send(http.delete(uri, headers: headers));
        default:
          return _send(http.get(uri, headers: headers));
      }
    }

    var response = await send();
    final mayRefresh = withAuth &&
        response.statusCode == 401 &&
        !endpoint.startsWith('/auth/refresh') &&
        !endpoint.startsWith('/auth/login') &&
        !endpoint.startsWith('/auth/register');
    if (mayRefresh && await _refreshSession()) response = await send();
    return _handleResponse(response);
  }

  Future<bool> _refreshSession() async {
    final pending = _refreshInProgress;
    if (pending != null) return pending;
    final refresh = _refreshToken;
    final future = _refreshWithToken(refresh);
    _refreshInProgress = future;
    try {
      return await future;
    } finally {
      _refreshInProgress = null;
    }
  }

  String? _refreshToken;

  Future<bool> _refreshWithToken(String? currentRefresh) async {
    final token = currentRefresh ?? await _getRefreshToken();
    if (token == null || token.isEmpty) return false;
    try {
      final response = await _send(http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: await _headers(withAuth: false),
        body: jsonEncode({'refreshToken': token}),
      ));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await clearTokens();
        return false;
      }
      dynamic decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is Map) decoded = decoded['data'];
      if (decoded is! Map ||
          decoded['accessToken'] is! String ||
          decoded['refreshToken'] is! String) {
        await clearTokens();
        return false;
      }
      await setTokens(decoded['accessToken'], decoded['refreshToken']);
      _refreshToken = decoded['refreshToken'];
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'The API returned an unexpected response (HTTP ${response.statusCode}).',
        );
      }
    } else {
      body = <String, dynamic>{};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map ? (body['data'] ?? body) : body;
    }

    final msg = body is Map
        ? (body['message'] ??
            'API request failed (HTTP ${response.statusCode}).')
        : 'API request failed (HTTP ${response.statusCode}).';
    throw ApiException(msg.toString());
  }
}
