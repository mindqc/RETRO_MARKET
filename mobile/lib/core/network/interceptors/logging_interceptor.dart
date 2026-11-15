import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// LoggingInterceptor formats and prints network requests and responses in debug mode
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--> [REQ] ${options.method} ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('    Query: ${options.queryParameters}');
      }
      if (options.data != null) {
        debugPrint('    Body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- [RES] ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('    Data: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- [ERR] ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('    Message: ${err.message}');
      debugPrint('    Error Data: ${err.response?.data}');
    }
    handler.next(err);
  }
}
