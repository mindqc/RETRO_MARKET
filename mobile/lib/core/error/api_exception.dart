import 'error_code_enum.dart';
import '../utils/safe_json_parser.dart';

/// ApiException represents structured HTTP API errors from RETRO MARKET Backend
class ApiException implements Exception {
  final int? statusCode;
  final String? errorCode;
  final ErrorCodeEnum errorCodeEnum;
  final String message;
  final Map<String, List<String>> fieldErrors;
  final Map<String, dynamic>? latestState;
  final DateTime? serverTime;

  const ApiException({
    this.statusCode,
    this.errorCode,
    required this.errorCodeEnum,
    required this.message,
    this.fieldErrors = const {},
    this.latestState,
    this.serverTime,
  });

  /// Factory constructing ApiException from Backend ApiEnvelope error payload:
  /// {"success": false, "error_code": "...", "message": "...", "errors": {...}, "latest_state": {...}, "server_time": "..."}
  factory ApiException.fromResponse({
    int? statusCode,
    Map<String, dynamic>? data,
  }) {
    if (data == null) {
      return ApiException(
        statusCode: statusCode,
        errorCode: 'UNKNOWN_ERROR',
        errorCodeEnum: ErrorCodeEnum.unknownError,
        message: 'Đã xảy ra lỗi không xác định từ máy chủ (HTTP $statusCode).',
      );
    }

    final rawErrorCode = data['error_code']?.toString();
    final errorCodeEnum = ErrorCodeEnum.fromCode(rawErrorCode);
    final rawMessage = data['message']?.toString() ?? 'Đã xảy ra lỗi khi xử lý yêu cầu.';

    // Extract validation errors: {"email": ["Email đã tồn tại"], "price": ["Giá không hợp lệ"]}
    final Map<String, List<String>> parsedFieldErrors = {};
    if (data['errors'] is Map) {
      final errorsMap = data['errors'] as Map;
      errorsMap.forEach((key, value) {
        if (value is List) {
          parsedFieldErrors[key.toString()] = value.map((e) => e.toString()).toList();
        } else if (value != null) {
          parsedFieldErrors[key.toString()] = [value.toString()];
        }
      });
    }

    // Extract latest state (e.g. for AUCTION_OUTBID_CONFLICT)
    Map<String, dynamic>? parsedLatestState;
    if (data['latest_state'] is Map<String, dynamic>) {
      parsedLatestState = data['latest_state'] as Map<String, dynamic>;
    } else if (data['latest_state'] is Map) {
      parsedLatestState = Map<String, dynamic>.from(data['latest_state'] as Map);
    }

    final parsedServerTime = SafeJsonParser.toDateTime(data['server_time']);

    return ApiException(
      statusCode: statusCode,
      errorCode: rawErrorCode,
      errorCodeEnum: errorCodeEnum,
      message: rawMessage,
      fieldErrors: parsedFieldErrors,
      latestState: parsedLatestState,
      serverTime: parsedServerTime,
    );
  }

  /// Network error factory for timeouts, connection failure, DNS resolution failure
  factory ApiException.network({String? message}) {
    return ApiException(
      statusCode: null,
      errorCode: 'NETWORK_ERROR',
      errorCodeEnum: ErrorCodeEnum.networkError,
      message: message ?? 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.',
    );
  }

  /// Unknown or client-side parsing error factory
  factory ApiException.unknown({String? message, int? statusCode}) {
    return ApiException(
      statusCode: statusCode,
      errorCode: 'UNKNOWN_ERROR',
      errorCodeEnum: ErrorCodeEnum.unknownError,
      message: message ?? 'Đã xảy ra lỗi không mong muốn.',
    );
  }

  /// Returns the first error message for a given field key (e.g. "email")
  String? firstErrorFor(String field) {
    final list = fieldErrors[field];
    if (list != null && list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  @override
  String toString() {
    return 'ApiException(status: $statusCode, code: $errorCode, message: $message, fieldErrors: ${fieldErrors.keys.toList()})';
  }
}
