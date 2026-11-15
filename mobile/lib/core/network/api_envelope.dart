import '../utils/safe_json_parser.dart';

/// Pagination metadata returned from backend Laravel LengthAwarePaginator
class PaginationMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMorePages;

  const PaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasMorePages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PaginationMeta(
        currentPage: 1,
        perPage: 15,
        total: 0,
        lastPage: 1,
        hasMorePages: false,
      );
    }
    return PaginationMeta(
      currentPage: SafeJsonParser.toInt(json['current_page'], defaultValue: 1),
      perPage: SafeJsonParser.toInt(json['per_page'], defaultValue: 15),
      total: SafeJsonParser.toInt(json['total'], defaultValue: 0),
      lastPage: SafeJsonParser.toInt(json['last_page'], defaultValue: 1),
      hasMorePages: SafeJsonParser.toBool(json['has_more_pages'], defaultValue: false),
    );
  }
}

/// PaginatedResponse packaging a list of items with pagination metadata
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.items,
    required this.meta,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic item) itemFromJson,
  ) {
    final rawData = json['data'];
    final List<T> parsedItems = [];
    if (rawData is List) {
      for (final item in rawData) {
        parsedItems.add(itemFromJson(item));
      }
    }

    final rawMeta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : (json['meta'] is Map ? Map<String, dynamic>.from(json['meta'] as Map) : null);

    return PaginatedResponse<T>(
      items: parsedItems,
      meta: PaginationMeta.fromJson(rawMeta),
    );
  }
}

/// Standardized API Response Envelope for all /api/v1/* endpoints
class ApiEnvelope<T> {
  final bool success;
  final T? data;
  final String message;
  final String? errorCode;
  final DateTime? serverTime;
  final PaginationMeta? meta;

  const ApiEnvelope({
    required this.success,
    this.data,
    this.message = '',
    this.errorCode,
    this.serverTime,
    this.meta,
  });

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic dataJson)? fromJsonT,
  ]) {
    final success = SafeJsonParser.toBool(json['success'], defaultValue: false);
    final message = json['message']?.toString() ?? '';
    final errorCode = json['error_code']?.toString();
    final serverTime = SafeJsonParser.toDateTime(json['server_time']);

    T? parsedData;
    final rawData = json['data'];
    if (rawData != null && fromJsonT != null) {
      parsedData = fromJsonT(rawData);
    } else if (rawData != null && rawData is T) {
      parsedData = rawData;
    }

    PaginationMeta? parsedMeta;
    if (json['meta'] is Map) {
      parsedMeta = PaginationMeta.fromJson(
        Map<String, dynamic>.from(json['meta'] as Map),
      );
    }

    return ApiEnvelope<T>(
      success: success,
      data: parsedData,
      message: message,
      errorCode: errorCode,
      serverTime: serverTime,
      meta: parsedMeta,
    );
  }
}
