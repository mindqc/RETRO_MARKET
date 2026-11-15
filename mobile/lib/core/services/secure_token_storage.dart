import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
/// Uses flutter_secure_storage with hardware-backed encryption.
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
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
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

    final storage = _secureStorage!;
    await Future.wait([
      storage.write(key: keyAccessToken, value: accessToken),
      storage.write(key: keyUserId, value: userId.toString()),
      storage.write(key: keyUserRole, value: role),
      storage.write(key: keyUserEmail, value: email),
    ]);
  }

  /// Retrieves current Sanctum access token
  Future<String?> getAccessToken() async {
    if (_inMemoryStore != null) {
      return _inMemoryStore[keyAccessToken];
    }
    return _secureStorage!.read(key: keyAccessToken);
  }

  /// Retrieves authenticated user id
  Future<int?> getUserId() async {
    final raw = _inMemoryStore != null
        ? _inMemoryStore[keyUserId]
        : await _secureStorage!.read(key: keyUserId);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  /// Retrieves authenticated user role
  Future<String?> getUserRole() async {
    if (_inMemoryStore != null) {
      return _inMemoryStore[keyUserRole];
    }
    return _secureStorage!.read(key: keyUserRole);
  }

  /// Retrieves authenticated user email
  Future<String?> getUserEmail() async {
    if (_inMemoryStore != null) {
      return _inMemoryStore[keyUserEmail];
    }
    return _secureStorage!.read(key: keyUserEmail);
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
    final storage = _secureStorage!;
    await Future.wait([
      storage.delete(key: keyAccessToken),
      storage.delete(key: keyUserId),
      storage.delete(key: keyUserRole),
      storage.delete(key: keyUserEmail),
    ]);
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
