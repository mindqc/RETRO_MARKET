import 'package:dio/dio.dart';
import '../../services/secure_token_storage.dart';

/// AuthBearerInterceptor attaches Sanctum Bearer tokens to outgoing HTTP requests.
///
/// Features Mandatory Adjustment #2 (DEC-01 & optional.sanctum compatibility):
/// Attaches Bearer token even on endpoints configured with optional.sanctum (/bootstrap, /home, /products, /auctions)
/// so that the backend can recognize authenticated users for is_favorited, is_owner, is_watching attributes.
/// Strictly omits token ONLY on the 4 pure guest authentication endpoints:
/// - /auth/login
/// - /auth/register
/// - /auth/forgot-password
/// - /auth/reset-password
class AuthBearerInterceptor extends Interceptor {
  final SecureTokenStorage tokenStorage;

  static const List<String> guestAuthEndpoints = [
    '/auth/login',
    '/auth/register',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  AuthBearerInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path.toLowerCase();

    // Skip attaching Bearer token only for the 4 pure guest auth endpoints
    final isGuestAuthEndpoint = guestAuthEndpoints.any(
      (endpoint) => path.endsWith(endpoint) || path.contains('$endpoint?'),
    );

    if (!isGuestAuthEndpoint) {
      try {
        final token = await tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // Proceed without Authorization header if token storage read fails
      }
    }

    handler.next(options);
  }
}
