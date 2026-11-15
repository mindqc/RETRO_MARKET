import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:izithrift/core/error/error_code_enum.dart';
import 'package:izithrift/core/error/api_exception.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/core/services/lifecycle_polling_controller.dart';
import 'package:izithrift/core/network/interceptors/auth_bearer_interceptor.dart';
import 'package:izithrift/core/network/interceptors/server_clock_sync_interceptor.dart';
import 'package:izithrift/core/network/interceptors/api_envelope_error_interceptor.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/state/view_state.dart';
import 'package:izithrift/core/state/base_view_model.dart';

class TestErrorInterceptorHandler extends ErrorInterceptorHandler {
  DioException? capturedError;

  @override
  void next(DioException err) {
    capturedError = err;
  }
}

class TestViewModel extends BaseViewModel<String> {
  Future<void> fetchSuccess() async {
    await runCatching(() async => 'Hello Retro Market');
  }

  Future<void> fetchEmpty() async {
    await runCatching(
      () async => '',
      isEmpty: (data) => data.isEmpty,
      emptyMessage: 'Không có dữ liệu',
    );
  }

  Future<void> fetchFailure() async {
    await runCatching(() async {
      throw const ApiException(
        statusCode: 422,
        errorCode: 'VALIDATION_ERROR',
        errorCodeEnum: ErrorCodeEnum.validationError,
        message: 'Dữ liệu đầu vào không hợp lệ',
      );
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P7-03: AuthBearerInterceptor Tests (Mandatory Adjustment #2)', () {
    late SecureTokenStorage tokenStorage;
    late AuthBearerInterceptor interceptor;

    setUp(() {
      tokenStorage = SecureTokenStorage.inMemory();
      interceptor = AuthBearerInterceptor(tokenStorage: tokenStorage);
    });

    test('Attaches Bearer token to optional.sanctum endpoints when token is present', () async {
      await tokenStorage.saveTokens(
        accessToken: 'sanctum_token_12345',
        userId: 1,
        role: 'buyer_seller',
        email: 'user@example.com',
      );

      final endpoints = [
        '/api/v1/bootstrap',
        '/api/v1/home',
        '/api/v1/products',
        '/api/v1/auctions/123',
        '/api/v1/catalog/taxonomy',
      ];

      for (final endpoint in endpoints) {
        final options = RequestOptions(path: endpoint);
        final handler = RequestInterceptorHandler();
        await interceptor.onRequest(options, handler);
        expect(
          options.headers['Authorization'],
          'Bearer sanctum_token_12345',
          reason: 'Endpoint $endpoint must carry Bearer token',
        );
      }
    });

    test('Strictly omits Bearer token on the 4 pure guest auth endpoints', () async {
      await tokenStorage.saveTokens(
        accessToken: 'sanctum_token_12345',
        userId: 1,
        role: 'buyer_seller',
        email: 'user@example.com',
      );

      final guestEndpoints = [
        '/api/v1/auth/login',
        '/api/v1/auth/register',
        '/api/v1/auth/forgot-password',
        '/api/v1/auth/reset-password',
      ];

      for (final endpoint in guestEndpoints) {
        final options = RequestOptions(path: endpoint);
        final handler = RequestInterceptorHandler();
        await interceptor.onRequest(options, handler);
        expect(
          options.headers.containsKey('Authorization'),
          isFalse,
          reason: 'Guest auth endpoint $endpoint must NOT carry Bearer token',
        );
      }
    });
  });

  group('P7-03: ServerClockSyncInterceptor Tests (Mandatory Adjustment #3)', () {
    late ServerTimeService serverTimeService;
    late ServerClockSyncInterceptor interceptor;

    setUp(() {
      serverTimeService = ServerTimeService();
      serverTimeService.reset();
      interceptor = ServerClockSyncInterceptor(serverTimeService: serverTimeService);
    });

    test('Synchronizes server_time on HTTP 2xx Response', () {
      final serverTimeTarget = DateTime.parse('2026-12-25T12:00:00.000Z');
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/home'),
        statusCode: 200,
        data: {
          'success': true,
          'server_time': '2026-12-25T12:00:00.000Z',
        },
      );

      final handler = ResponseInterceptorHandler();
      interceptor.onResponse(response, handler);

      expect(serverTimeService.lastSyncTime, isNotNull);
      final syncedNow = serverTimeService.now();
      expect(syncedNow.year, equals(serverTimeTarget.year));
      expect(syncedNow.month, equals(serverTimeTarget.month));
      expect(syncedNow.day, equals(serverTimeTarget.day));
    });

    test('Synchronizes server_time on HTTP 409 AUCTION_OUTBID_CONFLICT Error', () {
      final errorServerTime = DateTime.parse('2026-12-25T12:15:30.000Z');
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/auctions/5/bids'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/auctions/5/bids'),
          statusCode: 409,
          data: {
            'success': false,
            'error_code': 'AUCTION_OUTBID_CONFLICT',
            'message': 'Đã có người đặt giá cao hơn.',
            'server_time': '2026-12-25T12:15:30.000Z',
          },
        ),
      );

      final handler = TestErrorInterceptorHandler();
      interceptor.onError(error, handler);

      expect(handler.capturedError, isNotNull);
      expect(serverTimeService.lastSyncTime, isNotNull);
      final syncedNow = serverTimeService.now();
      expect(syncedNow.year, equals(errorServerTime.year));
      expect(syncedNow.month, equals(errorServerTime.month));
      expect(syncedNow.day, equals(errorServerTime.day));
    });
  });

  group('P7-03: ApiEnvelopeErrorInterceptor & ApiException Tests', () {
    late SecureTokenStorage tokenStorage;
    late ApiEnvelopeErrorInterceptor errorInterceptor;

    setUp(() {
      tokenStorage = SecureTokenStorage.inMemory();
      errorInterceptor = ApiEnvelopeErrorInterceptor(tokenStorage: tokenStorage);
    });

    test('Parses 401 UNAUTHENTICATED, clears token, and emits session alert', () async {
      await tokenStorage.saveTokens(
        accessToken: 'expired_token',
        userId: 10,
        role: 'buyer_seller',
        email: 'test@example.com',
      );

      AuthSessionAlert? emittedAlert;
      final sub = tokenStorage.sessionAlerts.listen((alert) => emittedAlert = alert);

      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/api/v1/cart'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/cart'),
          statusCode: 401,
          data: {
            'success': false,
            'error_code': 'UNAUTHENTICATED',
            'message': 'Phiên đăng nhập đã hết hạn.',
          },
        ),
      );

      final handler = TestErrorInterceptorHandler();
      await errorInterceptor.onError(dioErr, handler);

      expect(handler.capturedError, isNotNull);
      final apiException = handler.capturedError?.error as ApiException?;
      expect(apiException?.errorCodeEnum, ErrorCodeEnum.unauthenticated);
      expect(await tokenStorage.hasToken(), isFalse);
      expect(emittedAlert, isNotNull);
      expect(emittedAlert?.type, equals(AuthSessionAlertType.unauthenticated));

      await sub.cancel();
    });

    test('Parses 403 ACCOUNT_SUSPENDED, clears token, and emits suspended alert', () async {
      await tokenStorage.saveTokens(
        accessToken: 'active_token',
        userId: 11,
        role: 'buyer_seller',
        email: 'suspended@example.com',
      );

      AuthSessionAlert? emittedAlert;
      final sub = tokenStorage.sessionAlerts.listen((alert) => emittedAlert = alert);

      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/api/v1/products'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/products'),
          statusCode: 403,
          data: {
            'success': false,
            'error_code': 'ACCOUNT_SUSPENDED',
            'message': 'Tài khoản của bạn đã bị khóa do vi phạm chính sách.',
          },
        ),
      );

      final handler = TestErrorInterceptorHandler();
      await errorInterceptor.onError(dioErr, handler);

      expect(handler.capturedError, isNotNull);
      final apiException = handler.capturedError?.error as ApiException?;
      expect(apiException?.errorCodeEnum, ErrorCodeEnum.accountSuspended);
      expect(await tokenStorage.hasToken(), isFalse);
      expect(emittedAlert, isNotNull);
      expect(emittedAlert?.type, equals(AuthSessionAlertType.accountSuspended));

      await sub.cancel();
    });

    test('Parses 403 SELF_TRANSACTION_FORBIDDEN without clearing tokens', () async {
      await tokenStorage.saveTokens(
        accessToken: 'valid_token',
        userId: 12,
        role: 'buyer_seller',
        email: 'seller@example.com',
      );

      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/api/v1/cart/items'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/cart/items'),
          statusCode: 403,
          data: {
            'success': false,
            'error_code': 'SELF_TRANSACTION_FORBIDDEN',
            'message': 'Bạn không thể mua sản phẩm do chính mình đăng bán.',
          },
        ),
      );

      final handler = TestErrorInterceptorHandler();
      await errorInterceptor.onError(dioErr, handler);

      expect(handler.capturedError, isNotNull);
      final apiException = handler.capturedError?.error as ApiException?;
      expect(apiException?.errorCodeEnum, ErrorCodeEnum.selfTransactionForbidden);
      expect(await tokenStorage.hasToken(), isTrue);
    });

    test('Parses 409 AUCTION_OUTBID_CONFLICT with latest_state', () {
      final exception = ApiException.fromResponse(
        statusCode: 409,
        data: {
          'success': false,
          'error_code': 'AUCTION_OUTBID_CONFLICT',
          'message': 'Đã có người đặt giá cao hơn.',
          'latest_state': {
            'current_highest_bid': 550000,
            'bid_count': 12,
            'extended_count': 2,
          },
        },
      );

      expect(exception.statusCode, 409);
      expect(exception.errorCodeEnum, ErrorCodeEnum.auctionOutbidConflict);
      expect(exception.latestState, isNotNull);
      expect(exception.latestState?['current_highest_bid'], 550000);
      expect(exception.latestState?['extended_count'], 2);
    });

    test('Parses 422 VALIDATION_ERROR with fieldErrors and firstErrorFor', () {
      final exception = ApiException.fromResponse(
        statusCode: 422,
        data: {
          'success': false,
          'error_code': 'VALIDATION_ERROR',
          'message': 'Dữ liệu không hợp lệ.',
          'errors': {
            'price': ['Giá sản phẩm phải lớn hơn 1.000đ.', 'Giá không được là số âm.'],
            'title': ['Tiêu đề là bắt buộc.'],
          },
        },
      );

      expect(exception.statusCode, 422);
      expect(exception.errorCodeEnum, ErrorCodeEnum.validationError);
      expect(exception.fieldErrors.length, 2);
      expect(exception.firstErrorFor('price'), 'Giá sản phẩm phải lớn hơn 1.000đ.');
      expect(exception.firstErrorFor('title'), 'Tiêu đề là bắt buộc.');
      expect(exception.firstErrorFor('non_existent'), isNull);
    });
  });

  group('P7-03: ApiEnvelope & PaginatedResponse Parsing Tests', () {
    test('ApiEnvelope parses success, data, and metadata', () {
      final json = {
        'success': true,
        'message': 'Thành công',
        'server_time': '2026-11-14T21:00:00.000Z',
        'data': {'id': 99, 'name': 'Áo khoác Vintage Denim'},
        'meta': {
          'current_page': 1,
          'per_page': 12,
          'total': 48,
          'last_page': 4,
          'has_more_pages': true,
        },
      };

      final envelope = ApiEnvelope.fromJson(
        json,
        (data) => (data as Map)['name'].toString(),
      );

      expect(envelope.success, isTrue);
      expect(envelope.data, 'Áo khoác Vintage Denim');
      expect(envelope.meta?.currentPage, 1);
      expect(envelope.meta?.total, 48);
      expect(envelope.meta?.hasMorePages, isTrue);
    });

    test('PaginatedResponse parses item list and metadata', () {
      final json = {
        'data': [
          {'id': 1, 'title': 'Món A'},
          {'id': 2, 'title': 'Món B'},
        ],
        'meta': {
          'current_page': 2,
          'per_page': 2,
          'total': 10,
          'last_page': 5,
          'has_more_pages': true,
        },
      };

      final paginated = PaginatedResponse.fromJson(
        json,
        (item) => (item as Map)['title'].toString(),
      );

      expect(paginated.items.length, 2);
      expect(paginated.items[0], 'Món A');
      expect(paginated.items[1], 'Món B');
      expect(paginated.meta.currentPage, 2);
      expect(paginated.meta.lastPage, 5);
      expect(paginated.meta.hasMorePages, isTrue);
    });
  });

  group('P7-03: LifecyclePollingController Tests (Mandatory Adjustment #1)', () {
    test('Prevents overlapping execution when previous poll action is in progress', () async {
      int pollCount = 0;
      final completer = Completer<void>();

      final controller = LifecyclePollingController(
        interval: const Duration(milliseconds: 50),
        registerObserver: false,
        autoStart: false,
        pollAction: () async {
          pollCount++;
          await completer.future; // keeps running until completed
        },
      );

      controller.start();
      final inFlightPoll = controller.triggerImmediate();

      expect(controller.isPollingInProgress, isTrue);
      expect(pollCount, 1);

      // Attempt second immediate poll while first is still pending
      await controller.triggerImmediate();
      expect(pollCount, 1, reason: 'Must not trigger second poll while first is in-flight');

      completer.complete();
      await inFlightPoll;
      expect(controller.isPollingInProgress, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    test('Pauses polling on background and resumes on foreground', () {
      final controller = LifecyclePollingController(
        interval: const Duration(seconds: 1),
        registerObserver: false,
        autoStart: true,
        pollAction: () async {},
      );

      expect(controller.isActive, isTrue);
      expect(controller.isPaused, isFalse);

      // Simulate app backgrounded
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(controller.isPaused, isTrue);

      // Simulate app foregrounded
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.isPaused, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });
  });

  group('P7-03: ViewState & BaseViewModel Tests', () {
    test('BaseViewModel runs catching lifecycle cleanly', () async {
      final vm = TestViewModel();

      expect(vm.state.isInitial, isTrue);
      expect(vm.state.status, equals(ViewStatus.initial));

      // 1. Success transition
      await vm.fetchSuccess();
      expect(vm.state.isSuccess, isTrue);
      expect(vm.state.status, equals(ViewStatus.success));
      expect(vm.state.data, 'Hello Retro Market');

      // 2. Empty transition
      await vm.fetchEmpty();
      expect(vm.state.isEmpty, isTrue);
      expect(vm.state.status, equals(ViewStatus.empty));
      expect(vm.state.errorMessage, 'Không có dữ liệu');

      // 3. Error transition
      await vm.fetchFailure();
      expect(vm.state.isError, isTrue);
      expect(vm.state.status, equals(ViewStatus.error));
      expect(vm.state.error?.errorCodeEnum, ErrorCodeEnum.validationError);
      expect(vm.state.errorMessage, 'Dữ liệu đầu vào không hợp lệ');

      vm.dispose();
      expect(vm.isDisposed, isTrue);
    });
  });
}
