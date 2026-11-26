import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthSessionAlertType {
  unauthenticated,
  accountSuspended,
}

class AuthSessionAlert {
  final AuthSessionAlertType type;
  final String message;

  const AuthSessionAlert({
    required this.type,
    required this.message,
  });
}

/// SecureTokenStorage manages JWT Bearer token and authenticated user credentials.
/// Uses flutter_secure_storage with hardware-backed encryption on mobile and
/// falls back to SharedPreferences on Flutter Web to avoid WebCrypto crashes.
/// Supports inMemory() constructor for fast and reliable unit/widget testing.
class SecureTokenStorage {
  static const String keyAccessToken = 'access_token';
  static const String keyUserId = 'auth_user_id';
  static const String keyUserRole = 'auth_user_role';
  static const String keyUserEmail = 'auth_user_email';

  final FlutterSecureStorage? _secureStorage;
  final Map<String, String>? _inMemoryStore;
  final StreamController<AuthSessionAlert> _alertController =
      StreamController<AuthSessionAlert>.broadcast();

  SecureTokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = kIsWeb
            ? null
            : (secureStorage ??
                const FlutterSecureStorage(
                  aOptions: AndroidOptions(encryptedSharedPreferences: true),
                  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
                )),
        _inMemoryStore = null;

  /// In-memory storage for test isolation without requiring platform channel mocks
  SecureTokenStorage.inMemory([Map<String, String>? initialData])
      : _secureStorage = null,
        _inMemoryStore = initialData ?? {};

  /// Stream of session alerts (e.g. 401 unauthenticated, 403 account suspended)
  Stream<AuthSessionAlert> get sessionAlerts => _alertController.stream;

  /// Saves authenticated session tokens and profile identifiers
  Future<void> saveTokens({
    required String accessToken,
    required int userId,
    required String role,
    required String email,
  }) async {
    if (_inMemoryStore != null) {
      _inMemoryStore[keyAccessToken] = accessToken;
      _inMemoryStore[keyUserId] = userId.toString();
      _inMemoryStore[keyUserRole] = role;
      _inMemoryStore[keyUserEmail] = email;
      return;
    }

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(keyAccessToken, accessToken),
        prefs.setString(keyUserId, userId.toString()),
        prefs.setString(keyUserRole, role),
        prefs.setString(keyUserEmail, email),
      ]);
      return;
    }

    final storage = _secureStorage!;
    await Future.wait([
      storage.write(key: keyAccessToken, value: accessToken),
      storage.write(key: keyUserId, value: userId.toString()),
      storage.write(key: keyUserRole, value: role),
      storage.write(key: keyUserEmail, value: email),
    ]);
  }

  /// Safely reads a value from the active backing store without crashing on decryption/storage errors
  Future<String?> _readValue(String key) async {
    if (_inMemoryStore != null) {
      return _inMemoryStore[key];
    }
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
      return await _secureStorage!.read(key: key);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves current Sanctum access token
  Future<String?> getAccessToken() {
    return _readValue(keyAccessToken);
  }

  /// Retrieves authenticated user id
  Future<int?> getUserId() async {
    final raw = await _readValue(keyUserId);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  /// Retrieves authenticated user role
  Future<String?> getUserRole() {
    return _readValue(keyUserRole);
  }

  /// Retrieves authenticated user email
  Future<String?> getUserEmail() {
    return _readValue(keyUserEmail);
  }

  /// Checks if valid access token exists
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears all stored session credentials (logout or session expiry)
  Future<void> clearTokens() async {
    if (_inMemoryStore != null) {
      _inMemoryStore.clear();
      return;
    }
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.remove(keyAccessToken),
          prefs.remove(keyUserId),
          prefs.remove(keyUserRole),
          prefs.remove(keyUserEmail),
        ]);
        return;
      }
      final storage = _secureStorage!;
      await Future.wait([
        storage.delete(key: keyAccessToken),
        storage.delete(key: keyUserId),
        storage.delete(key: keyUserRole),
        storage.delete(key: keyUserEmail),
      ]);
    } catch (_) {
      // Tolerate storage errors when clearing corrupted or unavailable entries
    }
  }

  /// Broadcasts an authentication session alert to subscribers
  void notifySessionAlert(AuthSessionAlert alert) {
    if (!_alertController.isClosed) {
      _alertController.add(alert);
    }
  }

  void dispose() {
    _alertController.close();
  }
}

/// Riverpod provider for SecureTokenStorage
final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  final storage = SecureTokenStorage();
  ref.onDispose(() => storage.dispose());
  return storage;
});
