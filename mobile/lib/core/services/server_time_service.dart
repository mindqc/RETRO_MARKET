import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ServerTimeService manages real-time clock synchronization between device and backend server
/// Enforces BR-AU-01: Auction bidding, countdowns, and expiration windows always evaluate against
/// authoritative server clock time rather than vulnerable client device clocks.
class ServerTimeService {
  static final ServerTimeService _instance = ServerTimeService._internal();
  factory ServerTimeService() => _instance;
  ServerTimeService._internal();

  static ServerTimeService get instance => _instance;

  Duration _offset = Duration.zero;
  DateTime? _lastSyncTime;

  /// Returns current duration offset between authoritative server and local device
  Duration get offset => _offset;

  /// Timestamp of when the last clock sync occurred
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Synchronizes device clock against authoritative server time
  void syncServerTime(DateTime serverTime, {DateTime? localReference}) {
    final localNow = localReference ?? DateTime.now();
    _offset = serverTime.difference(localNow);
    _lastSyncTime = localNow;
  }

  /// Convenience alias for clock sync
  void syncWithServer(DateTime? serverTime, {DateTime? localReference}) {
    if (serverTime != null) {
      syncServerTime(serverTime, localReference: localReference);
    }
  }

  /// Returns authoritative current server time
  DateTime now() {
    return DateTime.now().add(_offset);
  }

  /// Resets clock offset to zero (useful for test resets)
  void reset() {
    _offset = Duration.zero;
    _lastSyncTime = null;
  }
}

/// Riverpod Provider for ServerTimeService
final serverTimeServiceProvider = Provider<ServerTimeService>((ref) {
  return ServerTimeService.instance;
});
