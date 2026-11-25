import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/router/app_router.dart';
import 'package:izithrift/core/router/app_routes.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/core/widgets/state_feedback_views.dart';
import 'package:izithrift/features/seller/models/seller_product_item_model.dart';
import 'package:izithrift/features/seller/repositories/seller_channel_repository.dart';
import 'package:izithrift/features/seller/screens/edit_resubmit_listing_screen.dart';
import 'package:izithrift/features/seller/viewmodels/seller_product_form_view_model.dart';

/// Test Mock for SellerChannelRepository
class MockSellerChannelRepository extends SellerChannelRepository {
  MockSellerChannelRepository()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  SellerProductItemModel? stubProductDetail;
  bool shouldThrow = false;
  Object? exceptionToThrow;
  int fetchCallCount = 0;
  int? lastFetchedId;

  @override
  Future<SellerProductItemModel> fetchProductDetail(int productId) async {
    fetchCallCount++;
    lastFetchedId = productId;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (shouldThrow) {
      throw Exception('Không tìm thấy sản phẩm hoặc lỗi kết nối.');
    }
    return stubProductDetail ??
        SellerProductItemModel(
          id: productId,
          productCode: 'PRD-$productId',
          title: 'Áo khoác dạ vintage dáng dài 90s',
          slug: 'ao-khoac-da-vintage-$productId',
          price: 450000.0,
          listingType: 'FIXED_PRICE',
          condition: 'LIKE_NEW',
          defectInfo: 'Vết xước nhẹ ở khuy cài',
          status: 'REJECTED',
          rejectionReason: 'Ảnh bìa thiếu ánh sáng tự nhiên',
          brandName: 'Burberrys Vintage',
          categoryName: 'Áo khoác Vintage & Retro',
          availableQuantity: 1,
          totalQuantity: 1,
        );
  }
}

void main() {
  group('P9-01: Route Constants & Aliasing Configuration', () {
    test('AppRoutes declares all 4 notification route alias constants', () {
      expect(AppRoutes.buyerOrderAlias, equals('/buyer/orders/:id'));
      expect(AppRoutes.buyerDisputeAlias, equals('/buyer/disputes/:id'));
      expect(AppRoutes.sellerDisputeAlias, equals('/seller/disputes/:id'));
      expect(AppRoutes.sellerProductAlias, equals('/seller/products/:id'));
    });
  });

  group('P9-01: GoRouter Route Aliasing & Parameter Preservation (AC-P901-01..05)', () {
    testWidgets('Alias 1: /buyer/orders/:id redirects to /orders/:id preserving ID and query/hash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      AppRouter.router.go('/buyer/orders/101?source=push_notification&tab=ACTIVE#section-details');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final currentUri = AppRouter.router.routerDelegate.currentConfiguration.uri;
      expect(currentUri.path, equals('/orders/101'));
      expect(currentUri.queryParameters['source'], equals('push_notification'));
      expect(currentUri.queryParameters['tab'], equals('ACTIVE'));
      expect(currentUri.fragment, equals('section-details'));
    });

    testWidgets('Alias 2: /buyer/disputes/:id redirects to /disputes/:id preserving ID and query', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      AppRouter.router.go('/buyer/disputes/55?reason=counter_evidence');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final currentUri = AppRouter.router.routerDelegate.currentConfiguration.uri;
      expect(currentUri.path, equals('/disputes/55'));
      expect(currentUri.queryParameters['reason'], equals('counter_evidence'));
    });

    testWidgets('Alias 3: /seller/disputes/:id redirects to /disputes/:id preserving ID', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      AppRouter.router.go('/seller/disputes/55');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final currentUri = AppRouter.router.routerDelegate.currentConfiguration.uri;
      expect(currentUri.path, equals('/disputes/55'));
    });

    testWidgets('Alias 4: /seller/products/:id redirects to /seller/listings/:id/edit with URL-encoded query', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      AppRouter.router.go('/seller/products/88?note=resubmit%20request&urgency=high#edit-form');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final currentUri = AppRouter.router.routerDelegate.currentConfiguration.uri;
      expect(currentUri.path, equals('/seller/listings/88/edit'));
      expect(currentUri.queryParameters['note'], equals('resubmit request'));
      expect(currentUri.queryParameters['urgency'], equals('high'));
      expect(currentUri.fragment, equals('edit-form'));
    });

    testWidgets('AC-P901-04: Existing 7 destination routes regression check', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      // Verify each existing primary route resolves smoothly without exception
      final routesToTest = [
        '/orders/202',
        '/disputes/77',
        '/seller/listings/99/edit',
        '/auctions/15',
        '/seller/orders/44',
        '/seller/wallet',
        '/products/10',
      ];

      for (final r in routesToTest) {
        AppRouter.router.go(r);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final currentPath = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
        expect(currentPath, equals(r), reason: 'Route $r should resolve directly without unwanted redirects');
      }
    });

    testWidgets('AC-P901-11 Scenario A: /seller/products/abc redirects safely, renders invalid error state, and recovers via navigation action', (tester) async {
      final mockRepo = MockSellerChannelRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerChannelRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      AppRouter.router.go('/seller/products/abc');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final currentUri = AppRouter.router.routerDelegate.currentConfiguration.uri;
      // 1. Route redirects to /seller/listings/abc/edit
      expect(currentUri.path, equals('/seller/listings/abc/edit'));

      // 2. No API request issued for invalid ID (int.tryParse('abc') gives 0, productId > 0 is false)
      expect(mockRepo.fetchCallCount, equals(0));

      // 3. Application does not crash and renders RetroEmptyStateView instead of indefinite loading
      expect(find.byType(EditResubmitListingScreen), findsOneWidget);
      expect(find.byType(RetroEmptyStateView), findsOneWidget);
      expect(find.text('Sản phẩm không hợp lệ'), findsOneWidget);
      expect(find.text('Mã sản phẩm không hợp lệ hoặc không còn tồn tại.'), findsOneWidget);
      expect(find.text('Quay lại danh sách bài đăng'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EditResubmitListingScreen),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );

      // 4. Submit action is completely unavailable (bottomNavigationBar is null)
      expect(find.byKey(const Key('btn_resubmit_action')), findsNothing);
      expect(find.text('Gửi duyệt lại (Resubmit)'), findsNothing);
      expect(find.text('Lưu thay đổi'), findsNothing);

      // 5. Recovery action works: tap returns to seller listings
      await tester.tap(find.text('Quay lại danh sách bài đăng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path, equals('/seller/listings'));
    });
  });

  group('P9-01: Seller Product Response Parsing & Model Mapping', () {
    test('SellerProductItemModel parses Backend ProductDetailResource envelope correctly', () {
      final backendJson = {
        'id': 88,
        'product_code': 'PRD-88-VTG',
        'title': 'Đầm vintage chấm bi thập niên 70s',
        'slug': 'dam-vintage-cham-bi-70s',
        'price': '320000.00',
        'listing_type': 'FIXED_PRICE',
        'condition': 'GOOD',
        'defect_info': 'Mất một khuy áo phụ sau lưng',
        'status': 'REJECTED',
        'rejection_reason': 'Ảnh chụp chưa rõ chi tiết khuyết điểm',
        'total_quantity': 1,
        'available_quantity': 1,
        'category': {
          'id': 3,
          'name': 'Đầm & Váy Cổ Điển',
          'slug': 'dam-vay-co-dien',
        },
        'brand': {
          'id': 12,
          'name': 'Vintage Boutique',
          'slug': 'vintage-boutique',
        },
        'images': [
          {'image_url': 'https://izithrift.local/storage/products/dam1.jpg'},
        ],
      };

      final model = SellerProductItemModel.fromJson(backendJson);
      expect(model.id, equals(88));
      expect(model.productCode, equals('PRD-88-VTG'));
      expect(model.title, equals('Đầm vintage chấm bi thập niên 70s'));
      expect(model.price, equals(320000.0));
      expect(model.condition, equals('GOOD'));
      expect(model.defectInfo, equals('Mất một khuy áo phụ sau lưng'));
      expect(model.rejectionReason, equals('Ảnh chụp chưa rõ chi tiết khuyết điểm'));
      expect(model.categoryName, equals('Đầm & Váy Cổ Điển'));
      expect(model.brandName, equals('Vintage Boutique'));
      expect(model.primaryImageUrl, equals('https://izithrift.local/storage/products/dam1.jpg'));
    });
  });

  group('P9-01: SellerProductFormViewModel Self-Loading Unit Tests', () {
    late MockSellerChannelRepository mockRepo;
    late SellerProductFormViewModel vm;

    setUp(() {
      mockRepo = MockSellerChannelRepository();
      vm = SellerProductFormViewModel(repository: mockRepo);
    });

    test('loadProductForEdit successfully loads and populates form data', () async {
      expect(vm.isLoading, isFalse);
      expect(vm.editingProductId, isNull);

      final result = await vm.loadProductForEdit(88);

      expect(mockRepo.fetchCallCount, equals(1));
      expect(mockRepo.lastFetchedId, equals(88));
      expect(result, isNotNull);
      expect(vm.editingProductId, equals(88));
      expect(vm.title, equals('Áo khoác dạ vintage dáng dài 90s'));
      expect(vm.price, equals(450000.0));
      expect(vm.currentRejectionReason, equals('Ảnh bìa thiếu ánh sáng tự nhiên'));
      expect(vm.isLoading, isFalse);
      expect(vm.isError, isFalse);
    });

    test('loadProductForEdit handles network/API error gracefully', () async {
      mockRepo.shouldThrow = true;

      final result = await vm.loadProductForEdit(999);

      expect(mockRepo.fetchCallCount, equals(1));
      expect(result, isNull);
      expect(vm.editingProductId, isNull);
      expect(vm.isError, isTrue);
      expect(vm.errorMessage, contains('Lỗi khi tải thông tin bài đăng'));
      expect(vm.isLoading, isFalse);
    });
  });

  group('P9-01: AC-P901-11 Scenario B & C – HTTP & Network Error Handling', () {
    late MockSellerChannelRepository mockRepo;
    late SellerProductFormViewModel vm;

    setUp(() {
      mockRepo = MockSellerChannelRepository();
      vm = SellerProductFormViewModel(repository: mockRepo);
    });

    test('HTTP 404 Not Found (Non-existent or unapproved cross-seller product): propagates to ViewModel error state and prevents form initialization', () async {
      mockRepo.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/products/404'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/products/404'),
          statusCode: 404,
          data: {'success': false, 'message': 'Sản phẩm yêu cầu không tồn tại hoặc đã bị xóa.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final result = await vm.loadProductForEdit(404);

      expect(mockRepo.fetchCallCount, equals(1));
      expect(result, isNull);
      expect(vm.isError, isTrue);
      expect(vm.editingProductId, isNull);
      expect(vm.title, isEmpty);
      expect(vm.price, equals(0.0));
      expect(vm.errorMessage, contains('Lỗi khi tải thông tin bài đăng'));
    });

    test('HTTP 401 Unauthenticated: propagates failure cleanly to error state without corrupting form', () async {
      mockRepo.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/products/101'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/products/101'),
          statusCode: 401,
          data: {'success': false, 'message': 'Unauthenticated.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final result = await vm.loadProductForEdit(101);

      expect(mockRepo.fetchCallCount, equals(1));
      expect(result, isNull);
      expect(vm.isError, isTrue);
      expect(vm.editingProductId, isNull);
      expect(vm.errorMessage, contains('Lỗi khi tải thông tin bài đăng'));
    });

    test('HTTP 500 Internal Server Error: propagates server failure without crashing', () async {
      mockRepo.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/products/500'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/products/500'),
          statusCode: 500,
          data: {'success': false, 'message': 'Internal Server Error'},
        ),
        type: DioExceptionType.badResponse,
      );

      final result = await vm.loadProductForEdit(500);

      expect(mockRepo.fetchCallCount, equals(1));
      expect(result, isNull);
      expect(vm.isError, isTrue);
      expect(vm.editingProductId, isNull);
      expect(vm.errorMessage, contains('Lỗi khi tải thông tin bài đăng'));
    });

    test('Network Connection Failure: handles connection error gracefully', () async {
      mockRepo.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/products/10'),
        type: DioExceptionType.connectionError,
        error: 'Failed to connect to host',
      );

      final result = await vm.loadProductForEdit(10);

      expect(mockRepo.fetchCallCount, equals(1));
      expect(result, isNull);
      expect(vm.isError, isTrue);
      expect(vm.editingProductId, isNull);
      expect(vm.errorMessage, contains('Lỗi khi tải thông tin bài đăng'));
    });

    test('Network Timeout: handles connection timeout cleanly', () async {
      mockRepo.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/products/10'),
        type: DioExceptionType.connectionTimeout,
        error: 'Connection timed out',
      );

      final result = await vm.loadProductForEdit(10);

      expect(mockRepo.fetchCallCount, equals(1));
      expect(result, isNull);
      expect(vm.isError, isTrue);
      expect(vm.editingProductId, isNull);
      expect(vm.errorMessage, contains('Lỗi khi tải thông tin bài đăng'));
    });
  });

  group('P9-01: EditResubmitListingScreen Self-Loading & Fallback Widget Tests', () {
    late MockSellerChannelRepository mockRepo;

    setUp(() {
      mockRepo = MockSellerChannelRepository();
    });

    testWidgets('Case A: initialProduct != null preserves existing initialization without extra API call', (tester) async {
      const initialProduct = SellerProductItemModel(
        id: 42,
        productCode: 'PRD-42',
        title: 'Quần jeans Levi 501 vintage 1980',
        slug: 'quan-jeans-levi-501-1980',
        price: 850000.0,
        listingType: 'FIXED_PRICE',
        condition: 'VINTAGE_WORN',
        status: 'REJECTED',
        rejectionReason: 'Cần bổ sung ảnh chụp tag sản phẩm',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerChannelRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: EditResubmitListingScreen(
              productId: 42,
              initialProduct: initialProduct,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify no extra API call was made
      expect(mockRepo.fetchCallCount, equals(0));

      // Verify form is populated from initialProduct
      expect(find.text('Quần jeans Levi 501 vintage 1980'), findsOneWidget);
      expect(find.text('850000'), findsOneWidget);
      expect(find.text('Cần bổ sung ảnh chụp tag sản phẩm'), findsOneWidget);

      // Verify bottom submit action bar is present
      expect(find.byKey(const Key('btn_resubmit_action')), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
    });

    testWidgets('Case B: initialProduct == null triggers self-loading and renders populated form upon success', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerChannelRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: EditResubmitListingScreen(
              productId: 88,
              initialProduct: null,
            ),
          ),
        ),
      );

      // Initial pump: triggers load and post frame callback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify repository was called with productId = 88
      expect(mockRepo.fetchCallCount, equals(1));
      expect(mockRepo.lastFetchedId, equals(88));

      // Verify form fields were populated asynchronously
      expect(find.text('Áo khoác dạ vintage dáng dài 90s'), findsOneWidget);
      expect(find.text('450000'), findsOneWidget);
      expect(find.text('Ảnh bìa thiếu ánh sáng tự nhiên'), findsOneWidget);

      // Verify bottom action bar is active
      expect(find.byKey(const Key('btn_resubmit_action')), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
    });

    testWidgets('Case C: initialProduct == null with API error renders RetroErrorRetryView and hides submit bar', (tester) async {
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerChannelRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: EditResubmitListingScreen(
              productId: 999,
              initialProduct: null,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error view is displayed
      expect(find.byType(RetroErrorRetryView), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Verify bottom action bar is NOT shown to prevent invalid submission
      expect(find.byKey(const Key('btn_resubmit_action')), findsNothing);
      expect(find.text('Lưu thay đổi'), findsNothing);
    });

    testWidgets('AC-P901-11 Scenario D: User tap on "Thử lại" re-executes API, switches state, and populates form upon success without duplicate requests', (tester) async {
      // 1. Initial request fails
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerChannelRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: EditResubmitListingScreen(
              productId: 88,
              initialProduct: null,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial error state
      expect(find.byType(RetroErrorRetryView), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.byKey(const Key('btn_resubmit_action')), findsNothing);
      expect(find.text('Lưu thay đổi'), findsNothing);
      expect(mockRepo.fetchCallCount, equals(1));

      // 2. Configure repository for second request to SUCCEED
      mockRepo.shouldThrow = false;
      mockRepo.stubProductDetail = const SellerProductItemModel(
        id: 88,
        productCode: 'PRD-88-RETRY',
        title: 'Áo khoác dạ phục hồi sau retry',
        slug: 'ao-khoac-da-phuc-hoi',
        price: 490000.0,
        listingType: 'FIXED_PRICE',
        condition: 'LIKE_NEW',
        status: 'REJECTED',
        rejectionReason: 'Lý do từ chối mẫu',
      );

      // 3. User taps "Thử lại" button
      await tester.tap(find.text('Thử lại'));

      // 4. Pump single frame to observe request increment and loading state
      await tester.pump();
      expect(mockRepo.fetchCallCount, equals(2));
      expect(mockRepo.lastFetchedId, equals(88));

      // 5. Pump asynchronous completion
      await tester.pump(const Duration(milliseconds: 100));

      // 6. Verify full recovery
      expect(find.byType(RetroErrorRetryView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Áo khoác dạ phục hồi sau retry'), findsOneWidget);
      expect(find.text('490000'), findsOneWidget);
      expect(find.byKey(const Key('btn_resubmit_action')), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);

      // 7. Verify no duplicate requests triggered
      expect(mockRepo.fetchCallCount, equals(2));
    });
  });
}
