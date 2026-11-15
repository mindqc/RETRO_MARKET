import 'package:dio/dio.dart';
import '../../error/api_exception.dart';
import '../../error/error_code_enum.dart';
import '../../services/secure_token_storage.dart';

/// ApiEnvelopeErrorInterceptor unpacks backend error envelopes into structured ApiExceptions
/// and triggers automatic session invalidation on 401 or 403 ACCOUNT_SUSPENDED (BR-AC-04).
class ApiEnvelopeErrorInterceptor extends Interceptor {
  final SecureTokenStorage tokenStorage;

  ApiEnvelopeErrorInterceptor({required this.tokenStorage});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    ApiException apiException;

    if (response != null) {
      final statusCode = response.statusCode;
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data is Map ? Map<String, dynamic>.from(response.data as Map) : null);

      apiException = ApiException.fromResponse(
        statusCode: statusCode,
        data: responseData,
      );

      // Handle 401 UNAUTHENTICATED or 403 ACCOUNT_SUSPENDED
      if (apiException.errorCodeEnum == ErrorCodeEnum.unauthenticated ||
          apiException.statusCode == 401) {
        await tokenStorage.clearTokens();
        tokenStorage.notifySessionAlert(
          AuthSessionAlert(
            type: AuthSessionAlertType.unauthenticated,
            message: apiException.message.isNotEmpty
                ? apiException.message
                : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          ),
        );
      } else if (apiException.errorCodeEnum == ErrorCodeEnum.accountSuspended ||
          (apiException.statusCode == 403 &&
              apiException.errorCode == 'ACCOUNT_SUSPENDED')) {
        await tokenStorage.clearTokens();
        tokenStorage.notifySessionAlert(
          AuthSessionAlert(
            type: AuthSessionAlertType.accountSuspended,
            message: apiException.message.isNotEmpty
                ? apiException.message
                : 'Tài khoản của bạn đã bị tạm khóa. Vui lòng liên hệ quản trị viên.',
          ),
        );
      }
    } else {
      // Network connectivity, timeout, or DNS failure
      apiException = ApiException.network(
        message: err.message ?? 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.',
      );
    }

    final transformedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiException,
      message: apiException.message,
    );

    handler.next(transformedError);
  }
}
