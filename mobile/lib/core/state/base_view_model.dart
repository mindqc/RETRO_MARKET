import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../error/api_exception.dart';
import 'view_state.dart';

/// BaseViewModel encapsulates standardized state mutations, error catching, and lifecycle disposal.
abstract class BaseViewModel<T> extends ChangeNotifier {
  ViewState<T> _state = const ViewState.initial();
  bool _disposed = false;

  ViewState<T> get state => _state;
  bool get isDisposed => _disposed;
  bool get isLoading => _state.isLoading;
  bool get isError => _state.isError;
  String? get errorMessage => _state.errorMessage;

  @protected
  void setState(ViewState<T> newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  void setLoading([T? currentData]) {
    setState(ViewState.loading(currentData ?? _state.data));
  }

  void setSuccess(T data) {
    setState(ViewState.success(data));
  }

  void setEmpty([String? message]) {
    setState(ViewState.empty(message));
  }

  void setError(String message, [ApiException? apiException, T? previousData]) {
    setState(ViewState.error(message, apiException, previousData ?? _state.data));
  }

  /// Executes asynchronous action with automatic state transitions and structured error handling
  Future<void> runCatching(
    Future<T> Function() action, {
    bool Function(T data)? isEmpty,
    String? emptyMessage,
  }) async {
    setLoading();
    try {
      final result = await action();
      if (isEmpty != null && isEmpty(result)) {
        setEmpty(emptyMessage);
      } else {
        setSuccess(result);
      }
    } on DioException catch (dioErr) {
      if (dioErr.error is ApiException) {
        final apiErr = dioErr.error as ApiException;
        setError(apiErr.message, apiErr);
      } else {
        setError(dioErr.message ?? 'Đã xảy ra lỗi mạng.', ApiException.network(message: dioErr.message));
      }
    } on ApiException catch (apiErr) {
      setError(apiErr.message, apiErr);
    } catch (e) {
      setError(e.toString(), ApiException.unknown(message: e.toString()));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
