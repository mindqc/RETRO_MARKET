import 'dart:async';
import 'package:flutter/widgets.dart';

/// LifecyclePollingController manages periodic HTTP polling routines (e.g. Live Auction room, 1-on-1 Chat)
/// strictly conforming to ADR-08 and NFR-PER-03.
///
/// Features Mandatory Adjustment #1:
/// - Concurrency lock (_isPollingInProgress) prevents overlapping network requests if previous cycle is slow.
/// - Automatically pauses when app transitions to background (paused/inactive/hidden).
/// - Automatically resumes when app transitions back to foreground (resumed).
/// - Cleanly cancels timer and unregisters lifecycle observer on dispose.
class LifecyclePollingController with WidgetsBindingObserver {
  final Duration interval;
  final Future<void> Function() pollAction;
  final bool registerObserver;

  Timer? _timer;
  bool _isActive = false;
  bool _isPaused = false;
  bool _isPollingInProgress = false;
  bool _isDisposed = false;

  LifecyclePollingController({
    required this.interval,
    required this.pollAction,
    bool autoStart = true,
    this.registerObserver = true,
  }) {
    if (registerObserver) {
      WidgetsBinding.instance.addObserver(this);
    }
    if (autoStart) {
      start();
    }
  }

  bool get isActive => _isActive;
  bool get isPaused => _isPaused;
  bool get isPollingInProgress => _isPollingInProgress;
  bool get isDisposed => _isDisposed;

  /// Starts or restarts the periodic polling timer
  void start() {
    if (_isDisposed) return;
    _timer?.cancel();
    _isActive = true;
    _isPaused = false;
    _scheduleNextTick();
  }

  /// Pauses polling timer without disposing
  void pause() {
    _timer?.cancel();
    _isPaused = true;
  }

  /// Resumes polling timer if active
  void resume() {
    if (_isDisposed || !_isActive) return;
    _isPaused = false;
    _scheduleNextTick();
  }

  /// Triggers an immediate execution cycle if no poll is currently in-flight
  Future<void> triggerImmediate() async {
    if (_isDisposed || _isPaused) return;
    await _executePoll();
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    if (_isDisposed || !_isActive || _isPaused) return;

    _timer = Timer(interval, () async {
      await _executePoll();
      if (!_isDisposed && _isActive && !_isPaused) {
        _scheduleNextTick();
      }
    });
  }

  Future<void> _executePoll() async {
    if (_isDisposed || _isPollingInProgress) {
      return;
    }

    _isPollingInProgress = true;
    try {
      await pollAction();
    } catch (_) {
      // Polling errors are swallowed or handled by callers inside pollAction
    } finally {
      _isPollingInProgress = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !_isActive) return;

    switch (state) {
      case AppLifecycleState.resumed:
        resume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        pause();
        break;
    }
  }

  /// Cleanly cancels all timers and removes WidgetsBinding lifecycle observer
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isActive = false;
    _timer?.cancel();
    _timer = null;
    if (registerObserver) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }
}
