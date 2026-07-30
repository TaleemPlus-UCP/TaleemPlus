/// Thrown for any non-2xx response from the TaleemPlus backend, carrying
/// the server's own `message` (and optional validation `errors`) instead of
/// a raw Dio/HTTP error, so callers can show it directly in the UI.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}
