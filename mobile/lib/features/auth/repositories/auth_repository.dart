import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/secure_token_storage.dart';
import '../models/bootstrap_model.dart';
import '../models/user_model.dart';

/// AuthRepository coordinates authentication, token storage, and bootstrap API calls
class AuthRepository {
  final DioClient dioClient;
  final SecureTokenStorage tokenStorage;

  AuthRepository({
    required this.dioClient,
    required this.tokenStorage,
  });

  /// Fetches system bootstrap configuration and authoritative clock time (M-AU-01)
  Future<BootstrapModel> fetchBootstrap() async {
    final envelope = await dioClient.getEnvelope<BootstrapModel>(
      ApiEndpoints.bootstrap,
      fromJsonT: (data) => BootstrapModel.fromJson(data as Map<String, dynamic>),
    );
    return envelope.data ?? const BootstrapModel();
  }

  /// Authenticates user and securely persists Sanctum Bearer token (M-AU-03)
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await dioClient.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>;
    final token = data['access_token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    await tokenStorage.saveTokens(
      accessToken: token,
      userId: user.id,
      role: user.role,
      email: user.email,
    );

    return user;
  }

  /// Registers a unified Buyer & Seller account (BR-AC-01, M-AU-04)
  Future<UserModel> register({
    required String displayName,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await dioClient.post(
      ApiEndpoints.register,
      data: {
        'display_name': displayName.trim(),
        'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>;
    final token = data['access_token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    await tokenStorage.saveTokens(
      accessToken: token,
      userId: user.id,
      role: user.role,
      email: user.email,
    );

    return user;
  }

  /// Revokes active Sanctum token and purges local secure storage
  Future<void> logout() async {
    try {
      await dioClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Tolerate offline logout or token already revoked
    } finally {
      await tokenStorage.clearTokens();
    }
  }

  /// Sends password reset instructions or returns demo token (M-AU-05)
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await dioClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email.trim()},
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  /// Resets password with token (M-AU-05)
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await dioClient.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email.trim(),
        'token': token.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data?['success'] == true;
  }
}

/// Riverpod provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  return AuthRepository(
    dioClient: dioClient,
    tokenStorage: tokenStorage,
  );
});
