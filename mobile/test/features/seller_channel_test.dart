import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/features/seller/models/seller_dashboard_model.dart';
import 'package:izithrift/features/seller/models/seller_product_form_payload.dart';
import 'package:izithrift/features/seller/models/seller_product_item_model.dart';
import 'package:izithrift/features/seller/models/seller_wallet_overview_model.dart';
import 'package:izithrift/features/seller/models/wallet_transaction_model.dart';
import 'package:izithrift/features/seller/repositories/seller_channel_repository.dart';
import 'package:izithrift/features/seller/screens/create_listing_screen.dart';
import 'package:izithrift/features/seller/screens/edit_resubmit_listing_screen.dart';
import 'package:izithrift/features/seller/screens/seller_hub_screen.dart';
import 'package:izithrift/features/seller/screens/seller_listings_screen.dart';
import 'package:izithrift/features/seller/screens/seller_wallet_ledger_screen.dart';
import 'package:izithrift/features/seller/viewmodels/seller_listings_view_model.dart';
import 'package:izithrift/features/seller/viewmodels/seller_product_form_view_model.dart';

/// Mock implementation of SellerChannelRepository for isolated unit and widget tests.
class MockSellerChannelRepository extends SellerChannelRepository {
  MockSellerChannelRepository()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  SellerDashboardModel? stubDashboard;
  List<SellerProductItemModel> stubProducts = [];
  SellerWalletOverviewModel? stubWallet;

  bool updateStatusCalled = false;
  int? lastUpdatedId;
  String? lastUpdatedStatus;

  bool relistCalled = false;
  bool createCalled = false;
  bool updateAndResubmitCalled = false;

  @override
  Future<SellerDashboardModel> fetchDashboard() async {
    return stubDashboard ??
        const SellerDashboardModel(
          shopName: 'Tiệm Đồ Si Vintage Hàng Tuyển',
          walletBalance: 1250000.0,
          escrowHeldBalance: 450000.0,
          trustScore: 98.0,
          averageRating: 4.9,
          reviewCount: 38,
          paidOrdersCount: 3,
          preparingOrdersCount: 1,
          disputedOrdersCount: 0,
          rejectedProductsCount: 2,
          pendingReviewCount: 4,
          activeProductsCount: 12,
          soldProductsCount: 45,
        );
  }

  @override
  Future<PaginatedResponse<SellerProductItemModel>> fetchSellerProducts({
    String? status,
    int page = 1,
    int perPage = 12,
  }) async {
    List<SellerProductItemModel> filtered = stubProducts;
    if (status != null && status != 'ALL') {
      filtered = stubProducts.where((p) => p.status == status).toList();
    }
    return PaginatedResponse<SellerProductItemModel>(
      items: filtered,
      meta: const PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 5,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> updateProductStatus(int productId, String newStatus) async {
    updateStatusCalled = true;
    lastUpdatedId = productId;
    lastUpdatedStatus = newStatus;
    return {'status': newStatus};
  }

  @override
  Future<Map<String, dynamic>> relistAuctionProduct(int productId, Map<String, dynamic> scheduleData) async {
    relistCalled = true;
    return {'success': true};
  }

  @override
  Future<SellerProductItemModel> createProduct(SellerProductFormPayload payload) async {
    createCalled = true;
    return SellerProductItemModel(
      id: 99,
      productCode: 'PRD-TEST-99',
      title: payload.title,
      slug: 'prd-test-99',
      price: payload.price,
      listingType: payload.listingType,
      condition: payload.condition,
      defectInfo: payload.defectInfo,
      status: payload.submitForReview ? 'PENDING_REVIEW' : 'DRAFT',
      availableQuantity: payload.availableQuantity,
    );
  }

  @override
  Future<SellerProductItemModel> updateAndResubmitProduct(
    int productId,
    SellerProductFormPayload payload,
  ) async {
    updateAndResubmitCalled = true;
    return SellerProductItemModel(
      id: productId,
      productCode: 'PRD-TEST-$productId',
      title: payload.title,
      slug: 'prd-test-$productId',
      price: payload.price,
      listingType: payload.listingType,
      condition: payload.condition,
      defectInfo: payload.defectInfo,
      status: payload.submitForReview ? 'PENDING_REVIEW' : 'DRAFT',
      availableQuantity: payload.availableQuantity,
      rejectionReason: null, // DEC-05: Cleared upon resubmission
    );
  }

  @override
  Future<SellerWalletOverviewModel> fetchWalletLedger({int page = 1, int perPage = 15}) async {
    return stubWallet ??
        SellerWalletOverviewModel(
          walletBalance: 1250000.0,
          escrowHeldBalance: 450000.0,
          totalEarned: 1700000.0,
          transactions: [
            WalletTransactionModel(
              id: 101,
              transactionCode: 'WTX-20261115-001',
              type: 'CREDIT',
              amount: 350000.0,
              balanceBefore: 900000.0,
              balanceAfter: 1250000.0,
              description: 'Giải ngân ký quỹ đơn hàng #ORD-8821',
              referenceType: 'ORDER',
              referenceCode: 'ORD-8821',
              createdAt: DateTime(2026, 11, 15, 14, 30),
            ),
            WalletTransactionModel(
              id: 102,
              transactionCode: 'WTX-20261114-002',
              type: 'DEBIT',
              amount: 50000.0,
              balanceBefore: 950000.0,
              balanceAfter: 900000.0,
              description: 'Phí kiểm duyệt bảo chứng sản phẩm vintage',
              referenceType: 'FEE',
              createdAt: DateTime(2026, 11, 14, 10, 15),
            ),
          ],
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P7-07: Seller Models & Business Rules Verification (BR-PR-01, BR-PR-03, DEC-05)', () {
    test('SellerDashboardModel.fromJson correctly parses balances, trust score and action counters', () {
      final json = {
        'shop_name': 'Tiệm Đồ Si Chú Bảy',
        'wallet_balance': '2500000.50',
        'escrow_held_balance': '800000.00',
        'trust_score': '96.5',
        'average_rating': '4.85',
        'review_count': '42',
        'action_counters': {
          'orders_pending_shipment': 5,
          'cancellation_requests': 2,
          'open_disputes': 1,
          'products_rejected': 3,
          'products_pending_review': 7,
          'products_approved': 20,
          'products_sold': 50,
        },
      };

      final model = SellerDashboardModel.fromJson(json);
      expect(model.shopName, 'Tiệm Đồ Si Chú Bảy');
      expect(model.walletBalance, 2500000.50);
      expect(model.escrowHeldBalance, 800000.00);
      expect(model.trustScore, 96.5);
      expect(model.paidOrdersCount, 5);
      expect(model.preparingOrdersCount, 2);
      expect(model.disputedOrdersCount, 1);
      expect(model.rejectedProductsCount, 3);
      expect(model.pendingReviewCount, 7);
      expect(model.activeProductsCount, 20);
      expect(model.soldProductsCount, 50);
    });

    test('SellerProductItemModel.fromJson correctly maps 7 statuses, condition ratings, and rejection reasons', () {
      final jsonRejected = {
        'id': 12,
        'product_code': 'PRD-REJ-012',
        'title': 'Áo khoác dạ vintage 90s',
        'slug': 'ao-khoac-da-vintage-90s',
        'price': 420000,
        'listing_type': 'FIXED_PRICE',
        'condition': 'GOOD',
        'defect_info': 'Sờn nhẹ ở góc tay áo',
        'status': 'REJECTED',
        'available_quantity': 1,
        'rejection_reason': 'Ảnh chụp chưa rõ nhãn mác thương hiệu và lỗi sờn ve áo.',
        'can_relist': false,
      };

      final rejectedItem = SellerProductItemModel.fromJson(jsonRejected);
      expect(rejectedItem.id, 12);
      expect(rejectedItem.status, 'REJECTED');
      expect(rejectedItem.condition, 'GOOD');
      expect(rejectedItem.rejectionReason, contains('Ảnh chụp chưa rõ nhãn mác'));
      expect(rejectedItem.canRelist, isFalse);

      final jsonAuctionEnded = {
        'id': 15,
        'product_code': 'PRD-AUC-015',
        'title': 'Đồng hồ cơ Poljot Liên Xô cổ',
        'slug': 'dong-ho-co-poljot',
        'price': 1500000,
        'listing_type': 'AUCTION',
        'condition': 'VINTAGE_WORN',
        'defect_info': 'Mặt kính có xước nhẹ',
        'status': 'AUCTION_ENDED',
        'available_quantity': 1,
        'can_relist': true,
      };

      final auctionItem = SellerProductItemModel.fromJson(jsonAuctionEnded);
      expect(auctionItem.listingType, 'AUCTION');
      expect(auctionItem.canRelist, isTrue);
    });

    test('SellerProductFormPayload.validate enforces BR-PR-01 (Auction quantity locked to 1) and BR-PR-03 (Mandatory defect info >= 5 chars)', () {
      // 1. Missing defect info violates BR-PR-03
      final invalidDefectPayload = const SellerProductFormPayload(
        title: 'Áo khoác da Bomber Vintage',
        description: 'Mô tả chi tiết',
        categoryId: 1,
        listingType: 'FIXED_PRICE',
        price: 500000,
        availableQuantity: 1,
        condition: 'GOOD',
        defectInfo: '   ', // Empty or whitespace
        submitForReview: true,
      );
      final error1 = invalidDefectPayload.validate();
      expect(error1, contains('BR-PR-03'));

      // 2. Short defect info violates BR-PR-03 (< 5 chars)
      final shortDefectPayload = const SellerProductFormPayload(
        title: 'Áo khoác da Bomber Vintage',
        description: 'Mô tả chi tiết',
        categoryId: 1,
        listingType: 'FIXED_PRICE',
        price: 500000,
        availableQuantity: 1,
        condition: 'GOOD',
        defectInfo: 'Rách', // Only 4 chars
        submitForReview: true,
      );
      final error2 = shortDefectPayload.validate();
      expect(error2, contains('BR-PR-03'));

      // 3. Auction with quantity > 1 violates BR-PR-01
      final invalidAuctionQuantityPayload = const SellerProductFormPayload(
        title: 'Áo khoác da Bomber Vintage',
        description: 'Mô tả chi tiết',
        categoryId: 1,
        listingType: 'AUCTION',
        price: 200000,
        availableQuantity: 3, // Must strictly be 1
        condition: 'GOOD',
        defectInfo: 'Có một vết xước nhỏ ở cổ áo 1cm',
        startingPrice: 200000,
        minBidIncrement: 10000,
        submitForReview: true,
      );
      final error3 = invalidAuctionQuantityPayload.validate();
      expect(error3, contains('BR-PR-01'));

      // 4. Valid Payload passes with 0 errors
      final validPayload = const SellerProductFormPayload(
        title: 'Áo khoác da Bomber Vintage',
        description: 'Mô tả chi tiết',
        categoryId: 1,
        listingType: 'AUCTION',
        price: 200000,
        availableQuantity: 1,
        condition: 'VINTAGE_WORN',
        defectInfo: 'Có một vết xước nhỏ ở ve áo 1cm',
        startingPrice: 200000,
        minBidIncrement: 10000,
        submitForReview: true,
      );
      final error4 = validPayload.validate();
      expect(error4, isNull);
    });

    test('WalletTransactionModel and SellerWalletOverviewModel parse immutable financial ledger records', () {
      final jsonWallet = {
        'wallet_balance': '1250000',
        'escrow_held_balance': '450000',
        'transactions': [
          {
            'id': 101,
            'transaction_code': 'WTX-20261115-001',
            'type': 'CREDIT',
            'amount': 350000,
            'balance_before': 900000,
            'balance_after': 1250000,
            'description': 'Giải ngân ký quỹ',
          },
          {
            'id': 102,
            'transaction_code': 'WTX-20261114-002',
            'type': 'DEBIT',
            'amount': 50000,
            'balance_before': 950000,
            'balance_after': 900000,
            'description': 'Phí bảo chứng',
          },
        ],
      };

      final wallet = SellerWalletOverviewModel.fromJson(jsonWallet);
      expect(wallet.walletBalance, 1250000.0);
      expect(wallet.escrowHeldBalance, 450000.0);
      expect(wallet.transactions.length, 2);

      final creditTx = wallet.transactions[0];
      expect(creditTx.isCredit, isTrue);
      expect(creditTx.walletTxCode, 'WTX-20261115-001');
      expect(creditTx.balanceAfter, 1250000.0);

      final debitTx = wallet.transactions[1];
      expect(debitTx.isCredit, isFalse);
      expect(debitTx.amount, 50000.0);
    });
  });

  group('P7-07: ViewModel Business Logic (Optimistic UI & DEC-05)', () {
    late MockSellerChannelRepository mockRepo;

    setUp(() {
      mockRepo = MockSellerChannelRepository();
      mockRepo.stubProducts = [
        const SellerProductItemModel(
          id: 1,
          productCode: 'PRD-001',
          title: 'Quần Jeans Levi\'s 501 Big E Vintage',
          slug: 'quan-jeans-levis-501',
          price: 650000,
          listingType: 'FIXED_PRICE',
          condition: 'GOOD',
          defectInfo: 'Sờn nhẹ gấu quần',
          status: 'APPROVED',
          availableQuantity: 1,
        ),
        const SellerProductItemModel(
          id: 2,
          productCode: 'PRD-002',
          title: 'Áo thun Harley Davidson 3D Emblem',
          slug: 'ao-thun-harley-davidson',
          price: 950000,
          listingType: 'FIXED_PRICE',
          condition: 'LIKE_NEW',
          defectInfo: 'Không lỗi lầm, vải mượt',
          status: 'DRAFT',
          availableQuantity: 1,
        ),
      ];
    });

    test('SellerListingsViewModel optimistic visibility toggle updates state before API response', () async {
      final vm = SellerListingsViewModel(repository: mockRepo);
      await vm.loadProducts();

      expect(vm.state.data!.first.status, 'APPROVED');

      final ok = await vm.toggleVisibility(1, 'APPROVED');
      expect(ok, isTrue);
      expect(mockRepo.updateStatusCalled, isTrue);
      expect(mockRepo.lastUpdatedStatus, 'HIDDEN');
      expect(vm.state.data!.first.status, 'HIDDEN');
    });

    test('SellerListingsViewModel deleteDraft removes draft product from list', () async {
      final vm = SellerListingsViewModel(repository: mockRepo);
      await vm.loadProducts();

      expect(vm.state.data!.length, 2);

      final ok = await vm.deleteDraft(2);
      expect(ok, isTrue);
      expect(vm.state.data!.length, 1);
      expect(vm.state.data!.any((p) => p.id == 2), isFalse);
    });

    test('SellerProductFormViewModel clears rejection reason upon resubmitting (DEC-05)', () async {
      final rejectedProduct = const SellerProductItemModel(
        id: 77,
        productCode: 'PRD-REJ-77',
        title: 'Áo blazer nhung tăm vintage',
        slug: 'ao-blazer-nhung-tam',
        price: 380000,
        listingType: 'FIXED_PRICE',
        categoryId: 1,
        condition: 'GOOD',
        defectInfo: 'Mất một cúc tay áo',
        status: 'REJECTED',
        rejectionReason: 'Vui lòng bổ sung ảnh chụp cận cảnh cúc áo bị mất.',
      );

      final vm = SellerProductFormViewModel(repository: mockRepo);
      vm.initForEdit(rejectedProduct);

      expect(vm.currentRejectionReason, isNotNull);
      expect(vm.editingProductId, 77);

      // User fixes defect and resubmits
      vm.defectInfo = 'Đã đính lại cúc sừng vintage mới tương thích hoàn hảo.';
      final res = await vm.submit(submitForReview: true);

      expect(res, isNotNull);
      expect(mockRepo.updateAndResubmitCalled, isTrue);
      // DEC-05: Rejection reason cleared
      expect(vm.currentRejectionReason, isNull);
    });
  });

  group('P7-07: Widget Tests for Seller Channel Screens (M-SL-01, M-SL-02, M-SL-03, M-SL-04, M-SL-08)', () {
    late MockSellerChannelRepository mockRepo;

    setUp(() {
      mockRepo = MockSellerChannelRepository();
    });

    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          sellerChannelRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('M-SL-01: SellerHubScreen displays wallet card, escrow held balance, action counters & CTA', (tester) async {
      await tester.pumpWidget(createTestApp(const SellerHubScreen()));
      await tester.pumpAndSettle();

      // Check Shop Title
      expect(find.text('Kênh Người Bán'), findsOneWidget);
      expect(find.text('Tiệm Đồ Si Vintage Hàng Tuyển'), findsOneWidget);

      // Check Wallet Card & Escrow Held Balance
      expect(find.text('Số dư ví Tiệm'), findsOneWidget);
      expect(find.textContaining('1.250.000'), findsOneWidget);
      expect(find.textContaining('450.000'), findsOneWidget);
      expect(find.byKey(const Key('btn_open_wallet_ledger')), findsOneWidget);

      // Check CTA button
      expect(find.byKey(const Key('btn_create_new_listing')), findsOneWidget);

      // Check Action Counters
      expect(find.text('Chờ giao hàng'), findsOneWidget);
      expect(find.text('Yêu cầu hủy'), findsOneWidget);
      expect(find.text('Khiếu nại đang mở'), findsOneWidget);
      expect(find.text('Bị từ chối kiểm duyệt'), findsOneWidget);
    });

    testWidgets('M-SL-02: SellerListingsScreen renders 7 tabs, condition badges, rejection actions, and relist buttons', (tester) async {
      mockRepo.stubProducts = [
        const SellerProductItemModel(
          id: 10,
          productCode: 'PRD-10',
          title: 'Áo khoác da Moto Cafe Racer',
          slug: 'ao-khoac-da-moto',
          price: 1800000,
          listingType: 'FIXED_PRICE',
          condition: 'LIKE_NEW',
          defectInfo: 'Khóa kéo Talon cổ điển nguyên bản',
          status: 'APPROVED',
          availableQuantity: 1,
        ),
        const SellerProductItemModel(
          id: 11,
          productCode: 'PRD-11',
          title: 'Mũ Beret dạ vintage Scotland',
          slug: 'mu-beret-da-vintage',
          price: 250000,
          listingType: 'FIXED_PRICE',
          condition: 'FAIR',
          defectInfo: 'Vết ố nhẹ bên trong lót mũ',
          status: 'REJECTED',
          rejectionReason: 'Ảnh chụp mặt trong mũ bị mờ, vui lòng chụp lại rõ nét.',
          availableQuantity: 1,
        ),
        const SellerProductItemModel(
          id: 12,
          productCode: 'PRD-12',
          title: 'Bật lửa Zippo La Mã 1994',
          slug: 'bat-lua-zippo-1994',
          price: 500000,
          listingType: 'AUCTION',
          condition: 'VINTAGE_WORN',
          defectInfo: 'Xước dăm theo thời gian',
          status: 'AUCTION_ENDED',
          canRelist: true,
          availableQuantity: 1,
        ),
      ];

      await tester.pumpWidget(createTestApp(const SellerListingsScreen()));
      await tester.pumpAndSettle();

      // Check 7 Tab Headers
      expect(find.widgetWithText(Tab, 'Tất cả'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Chờ duyệt'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Đang bán'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Bị từ chối'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Đã bán'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Bản nháp'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Đã ẩn'), findsOneWidget);

      // Check Context Buttons
      // Product 10 (APPROVED): Has [Ẩn bài]
      expect(find.byKey(const Key('btn_toggle_visibility_10')), findsOneWidget);

      // Product 11 (REJECTED): Has [Xem lý do & Gửi duyệt lại]
      expect(find.byKey(const Key('btn_resubmit_11')), findsOneWidget);
      expect(find.textContaining('Ảnh chụp mặt trong mũ bị mờ'), findsOneWidget);

      // Product 12 (canRelist): Has [Tái đăng đấu giá]
      expect(find.byKey(const Key('btn_relist_12')), findsOneWidget);
    });

    testWidgets('M-SL-03: CreateListingScreen enforces BR-PR-01 (Auction notice) and BR-PR-03 (Mandatory defect info >= 5 chars)', (tester) async {
      await tester.pumpWidget(createTestApp(const CreateListingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Đăng bán sản phẩm mới'), findsOneWidget);
      expect(find.text('🏷️ Bán giá cố định'), findsOneWidget);
      expect(find.text('🔨 Đấu giá trực tiếp'), findsOneWidget);

      // Switch to Auction Mode
      await tester.tap(find.text('🔨 Đấu giá trực tiếp'));
      await tester.pumpAndSettle();

      // Enforces BR-PR-01 alert
      expect(find.textContaining('BR-PR-01'), findsOneWidget);

      // Try to submit with empty defect info
      await tester.tap(find.byKey(const Key('btn_submit_for_review')));
      await tester.pumpAndSettle();

      // Form validation error appears
      expect(find.textContaining('BR-PR-03'), findsOneWidget);
    });

    testWidgets('M-SL-04: EditResubmitListingScreen displays DEC-05 rejection reason banner in Burgundy/Red', (tester) async {
      final rejectedProduct = const SellerProductItemModel(
        id: 44,
        productCode: 'PRD-REJ-44',
        title: 'Áo sơ mi lụa họa tiết Baroque 80s',
        slug: 'ao-so-mi-lua-baroque',
        price: 320000,
        listingType: 'FIXED_PRICE',
        condition: 'GOOD',
        defectInfo: 'Sứt chỉ gấu áo một đoạn 2cm',
        status: 'REJECTED',
        rejectionReason: 'Thiếu ảnh cận cảnh nhãn chất liệu lụa tơ tằm theo quy định hàng hiệu si.',
      );

      await tester.pumpWidget(createTestApp(
        EditResubmitListingScreen(productId: 44, initialProduct: rejectedProduct),
      ));
      await tester.pumpAndSettle();

      // Check DEC-05 Rejection Reason Banner
      expect(find.byKey(const Key('banner_rejection_reason')), findsOneWidget);
      expect(find.textContaining('Thiếu ảnh cận cảnh nhãn chất liệu lụa'), findsOneWidget);

      // Check [Gửi duyệt lại (Resubmit)] button
      expect(find.byKey(const Key('btn_resubmit_action')), findsOneWidget);
      expect(find.text('Gửi duyệt lại (Resubmit)'), findsOneWidget);
    });

    testWidgets('M-SL-08: SellerWalletLedgerScreen displays immutable append-only ledger notice and transaction history', (tester) async {
      await tester.pumpWidget(createTestApp(const SellerWalletLedgerScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sổ Cái Ví & Giao Dịch'), findsOneWidget);
      expect(find.textContaining('Sổ cái tài chính bất biến (Append-Only Ledger)'), findsOneWidget);

      // Balances
      expect(find.textContaining('1.250.000'), findsAtLeast(1));
      expect(find.textContaining('450.000'), findsOneWidget);

      // Transactions
      expect(find.textContaining('WTX-20261115-001'), findsOneWidget);
      expect(find.text('Giải ngân ký quỹ đơn hàng #ORD-8821'), findsOneWidget);
      expect(find.textContaining('WTX-20261114-002'), findsOneWidget);
      expect(find.text('Phí kiểm duyệt bảo chứng sản phẩm vintage'), findsOneWidget);
    });
  });
}
