import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';
import '../services/secure_token_storage.dart';
import '../services/server_time_service.dart';
import 'api_envelope.dart';
import 'interceptors/auth_bearer_interceptor.dart';
import 'interceptors/server_clock_sync_interceptor.dart';
import 'interceptors/api_envelope_error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// DioClient encapsulates the configured Dio HTTP networking instance
/// with default timeouts, standard headers, and the chain of 4 dedicated interceptors.
class DioClient {
  final Dio dio;
  final SecureTokenStorage tokenStorage;
  final ServerTimeService serverTimeService;

  DioClient({
    Dio? dioInstance,
    required this.tokenStorage,
    ServerTimeService? serverTimeService,
  })  : serverTimeService = serverTimeService ?? ServerTimeService.instance,
        dio = dioInstance ??
            Dio(
              BaseOptions(
                baseUrl: EnvConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  'X-App-Platform': 'flutter_mobile',
                  'X-App-Version': '1.0.0',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.clear();
    dio.interceptors.addAll([
      AuthBearerInterceptor(tokenStorage: tokenStorage),
      ServerClockSyncInterceptor(serverTimeService: serverTimeService),
      ApiEnvelopeErrorInterceptor(tokenStorage: tokenStorage),
      LoggingInterceptor(),
    ]);
  }

  // Core HTTP Verbs
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Multipart POST request for file uploads (Product images, dispute evidence)
  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return dio.post<T>(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: (options ?? Options()).copyWith(contentType: 'multipart/form-data'),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  /// Multipart PUT request using Laravel method spoofing (_method: PUT)
  Future<Response<T>> putMultipart<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    formData.fields.add(const MapEntry('_method', 'PUT'));
    return dio.post<T>(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: (options ?? Options()).copyWith(contentType: 'multipart/form-data'),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  // Typed Envelope Helpers
  Future<ApiEnvelope<T>> getEnvelope<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    final response = await get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return ApiEnvelope<T>.fromJson(response.data ?? {}, fromJsonT);
  }

  Future<ApiEnvelope<T>> postEnvelope<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    final response = await post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return ApiEnvelope<T>.fromJson(response.data ?? {}, fromJsonT);
  }

  Future<PaginatedResponse<T>> getPaginated<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJsonItem,
  }) async {
    final response = await get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return PaginatedResponse<T>.fromJson(response.data ?? {}, fromJsonItem);
  }
}

/// Riverpod provider for DioClient
final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  final serverTimeService = ref.watch(serverTimeServiceProvider);
  return DioClient(
    tokenStorage: tokenStorage,
    serverTimeService: serverTimeService,
  );
});
