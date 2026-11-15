import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment Configuration for RETRO MARKET (izithrift).
class EnvConfig {
  EnvConfig._();

  static const String appName = 'izithrift';
  static const String projectCodename = 'RETRO MARKET';
  static const String appVersion = '1.0.0';
  static const bool defaultDemoMode = true;

  /// Determine the base API URL based on runtime platform or compile-time variable.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    if (Platform.isAndroid) {
      // Android Emulator maps host localhost to 10.0.2.2
      return 'http://10.0.2.2:8000/api/v1';
    }

    // iOS Simulator, macOS, Windows desktop, Linux
    return 'http://127.0.0.1:8000/api/v1';
  }
}
