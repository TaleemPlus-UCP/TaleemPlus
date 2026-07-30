import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure on-device storage for the JWT access/refresh token pair.
///
/// Replaces the legacy app's plaintext-in-`shared_preferences` caching of
/// the user's actual password for biometric re-login (see security.md's
/// "known accepted risk" note on `saved_pass_v1`) — only an opaque,
/// individually revocable refresh token is ever persisted now, in the
/// platform keystore/keychain instead of a plain preferences file.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> saveAccessToken(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
