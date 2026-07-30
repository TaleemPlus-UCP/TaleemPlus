import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for the TaleemPlus Node.js backend.
///
/// Override at build/run time with `--dart-define=API_BASE_URL=http://<host>:4000/api/v1`
/// (required for a physical device, which can't reach `localhost` on the
/// dev machine — use the machine's LAN IP instead).
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // The Android emulator's `10.0.2.2` is a special alias for the host
    // machine's `localhost`; every other target (web, desktop, iOS
    // simulator) can reach the dev backend via `localhost` directly.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:4000/api/v1';
    return 'http://localhost:4000/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
