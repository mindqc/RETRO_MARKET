import 'package:dio/dio.dart';
import '../../services/server_time_service.dart';
import '../../utils/safe_json_parser.dart';

/// ServerClockSyncInterceptor extracts authoritative server timestamps (BR-AU-01).
///
/// Features Mandatory Adjustment #3:
/// Listens to "server_time" in BOTH onResponse (HTTP 2xx) AND onError (HTTP 4xx/5xx).
/// This guarantees that when a 409 AUCTION_OUTBID_CONFLICT occurs and an Anti-Sniping extension
/// moves the auction deadline, the device clock sync updates immediately from the error payload.
class ServerClockSyncInterceptor extends Interceptor {
  final ServerTimeService serverTimeService;

  ServerClockSyncInterceptor({ServerTimeService? serverTimeService})
      : serverTimeService = serverTimeService ?? ServerTimeService.instance;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _trySyncServerTime(response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _trySyncServerTime(err.response?.data);
    handler.next(err);
  }

  void _trySyncServerTime(dynamic data) {
    if (data is Map) {
      final rawServerTime = data['server_time'];
      if (rawServerTime != null) {
        final parsed = SafeJsonParser.toDateTime(rawServerTime);
        if (parsed != null) {
          serverTimeService.syncServerTime(parsed);
        }
      }
    }
  }
}
