import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin wrapper around a configured [Dio] instance shared by every REST
/// service in the app: attaches the access token to every request and
/// transparently refreshes it exactly once on a 401 before retrying,
/// rather than making every caller special-case token expiry.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    // A separate, interceptor-free client for the refresh call itself —
    // routing it through `_dio` would recurse into this same 401 handler.
    _refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRetry = error.requestOptions.extra['retried'] == true;
          final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');

          if (isUnauthorized && !isRetry && !isAuthEndpoint) {
            final refreshed = await _refreshAccessToken();
            if (refreshed != null) {
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $refreshed';
              retryOptions.extra['retried'] = true;
              try {
                final response = await _dio.fetch(retryOptions);
                handler.resolve(response);
                return;
              } on DioException catch (retryError) {
                handler.next(retryError);
                return;
              }
            }
            // Refresh failed (or no refresh token at all) — the session is
            // dead; let whoever is listening react (typically: sign out and
            // navigate to Login).
            await TokenStorage.instance.clear();
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  late final Dio _refreshDio;

  /// Guards concurrent 401s from all triggering their own refresh call.
  Future<String?>? _inFlightRefresh;

  /// Set by whoever owns the app's session state (see AuthProvider) to be
  /// notified when a refresh attempt fails and the user must sign in again.
  void Function()? onSessionExpired;

  Future<String?> _refreshAccessToken() {
    return _inFlightRefresh ??= _doRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final tokens = response.data['data']['tokens'];
      final newAccessToken = tokens['accessToken'] as String;
      final newRefreshToken = tokens['refreshToken'] as String;
      await TokenStorage.instance.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters}) =>
      _request(() => _dio.get<T>(path, queryParameters: queryParameters));

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _request(() => _dio.post<T>(path, data: data));

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _request(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _request(() => _dio.put<T>(path, data: data));

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _request(() => _dio.delete<T>(path, data: data));

  Future<Response<T>> _request<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        (data['message'] as String?) ??
            'Something went wrong. Please try again.',
        statusCode: e.response?.statusCode,
        errors: data['errors'],
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException('No internet connection. Please try again.',
          statusCode: e.response?.statusCode);
    }
    return ApiException(e.message ?? 'Something went wrong. Please try again.',
        statusCode: e.response?.statusCode);
  }
}
