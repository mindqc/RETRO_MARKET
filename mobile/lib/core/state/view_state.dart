import '../error/api_exception.dart';

enum ViewStatus {
  initial,
  loading,
  success,
  empty,
  error,
}

/// Generic ViewState encapsulates the 5 core states of asynchronous UI screens
class ViewState<T> {
  final ViewStatus status;
  final T? data;
  final String? errorMessage;
  final ApiException? error;

  const ViewState({
    required this.status,
    this.data,
    this.errorMessage,
    this.error,
  });

  const ViewState.initial([this.data])
      : status = ViewStatus.initial,
        errorMessage = null,
        error = null;

  const ViewState.loading([this.data])
      : status = ViewStatus.loading,
        errorMessage = null,
        error = null;

  const ViewState.success(this.data)
      : status = ViewStatus.success,
        errorMessage = null,
        error = null;

  const ViewState.empty([this.errorMessage])
      : status = ViewStatus.empty,
        data = null,
        error = null;

  const ViewState.error(this.errorMessage, [this.error, this.data])
      : status = ViewStatus.error;

  bool get isInitial => status == ViewStatus.initial;
  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isEmpty => status == ViewStatus.empty;
  bool get isError => status == ViewStatus.error;
  bool get hasData => data != null;

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String? message) empty,
    required R Function(String message, ApiException? error) error,
  }) {
    switch (status) {
      case ViewStatus.initial:
        return initial();
      case ViewStatus.loading:
        return loading();
      case ViewStatus.success:
        return success(data as T);
      case ViewStatus.empty:
        return empty(errorMessage);
      case ViewStatus.error:
        return error(errorMessage ?? 'Đã xảy ra lỗi', this.error);
    }
  }

  R maybeWhen<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(String? message)? empty,
    R Function(String message, ApiException? error)? error,
    required R Function() orElse,
  }) {
    switch (status) {
      case ViewStatus.initial:
        return initial != null ? initial() : orElse();
      case ViewStatus.loading:
        return loading != null ? loading() : orElse();
      case ViewStatus.success:
        return success != null && data != null ? success(data as T) : orElse();
      case ViewStatus.empty:
        return empty != null ? empty(errorMessage) : orElse();
      case ViewStatus.error:
        return error != null
            ? error(errorMessage ?? 'Đã xảy ra lỗi', this.error)
            : orElse();
    }
  }
}
