import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:izithrift/app.dart';
import 'package:izithrift/core/error/api_exception.dart';
import 'package:izithrift/core/error/error_code_enum.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/core/theme/seasonal_decor_provider.dart';
import 'package:izithrift/core/widgets/price_breakdown_card.dart';
import 'package:izithrift/core/widgets/seasonal_decor_overlay.dart';
import 'package:izithrift/features/auth/models/user_model.dart';
import 'package:izithrift/features/auth/repositories/auth_repository.dart';
import 'package:izithrift/features/auth/viewmodels/auth_view_model.dart';
import 'package:izithrift/features/profile/models/profile_summary_model.dart';
import 'package:izithrift/features/profile/repositories/profile_repository.dart';
import 'package:izithrift/features/catalog/models/product_filter_query.dart';
import 'package:izithrift/features/catalog/models/product_summary_model.dart';
import 'package:izithrift/features/catalog/models/review_item_model.dart';
import 'package:izithrift/features/catalog/repositories/home_catalog_repository.dart';
import 'package:izithrift/features/catalog/screens/product_search_screen.dart';
import 'package:izithrift/features/catalog/viewmodels/catalog_search_view_model.dart';
import 'package:izithrift/features/seller/models/seller_product_item_model.dart';
import 'package:izithrift/features/seller/models/seller_wallet_overview_model.dart';
import 'package:izithrift/features/seller/models/wallet_transaction_model.dart';
import 'package:izithrift/features/seller/repositories/seller_channel_repository.dart';
import 'package:izithrift/features/seller/screens/edit_resubmit_listing_screen.dart';
import 'package:izithrift/features/seller/screens/seller_wallet_ledger_screen.dart';
import 'package:izithrift/features/orders/models/order_model.dart';
import 'package:izithrift/features/orders/models/order_item_snapshot_model.dart';
import 'package:izithrift/features/orders/repositories/order_fulfillment_repository.dart';
import 'package:izithrift/features/orders/screens/purchase_order_detail_screen.dart';
import 'package:izithrift/features/auctions/models/auction_detail_model.dart';
import 'package:izithrift/features/auctions/models/auction_bid_item_model.dart';
import 'package:izithrift/features/auctions/repositories/auction_repository.dart';
import 'package:izithrift/features/auctions/screens/live_bidding_room_screen.dart';
import 'package:izithrift/features/auctions/screens/bid_placement_bottom_sheet.dart';
import 'package:izithrift/features/engagement/models/chat_context_card_model.dart';
import 'package:izithrift/features/engagement/models/conversation_model.dart';
import 'package:izithrift/features/engagement/models/message_model.dart';
import 'package:izithrift/features/engagement/models/notification_item_model.dart';
import 'package:izithrift/features/engagement/models/seller_reviews_summary_model.dart';
import 'package:izithrift/features/engagement/repositories/communication_engagement_repository.dart';
import 'package:izithrift/features/engagement/screens/chat_room_screen.dart';
import 'package:izithrift/features/engagement/screens/notification_center_screen.dart';
import 'package:izithrift/features/engagement/screens/submit_verified_review_screen.dart';
import 'package:izithrift/features/engagement/screens/seller_reviews_list_screen.dart';

/// Mock Repositories for E2E Flow Testing
class MockHomeCatalogRepositoryForE2E extends HomeCatalogRepository {
  MockHomeCatalogRepositoryForE2E()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  @override
  Future<PaginatedResponse<ProductSummaryModel>> searchProducts(ProductFilterQuery query) async {
    return const PaginatedResponse<ProductSummaryModel>(
      items: <ProductSummaryModel>[],
      meta: PaginationMeta(
        currentPage: 1,
        perPage: 20,
        total: 0,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }
}

class MockOrderFulfillmentRepositoryForE2E extends OrderFulfillmentRepository {
  MockOrderFulfillmentRepositoryForE2E()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  OrderModel? stubOrder;

  @override
  Future<OrderModel> fetchOrderDetail(int orderId) async {
    return stubOrder ??
        OrderModel(
          id: orderId,
          orderCode: 'IZI-777',
          buyerId: 1,
          buyerName: 'Người mua Đỗ Đức',
          sellerId: 5,
          shopName: 'Tiệm Đồ Si Chú Ba',
          recipientName: 'Đỗ Minh Đức',
          recipientPhone: '0988776655',
          fullAddress: '123 Đường Xô Viết Nghệ Tĩnh, P.25, Q.Bình Thạnh, TP.HCM',
          orderStatus: 'DELIVERED',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
          itemSubtotal: 500000.0,
          shippingFee: 25000.0,
          buyerProtectionFee: 37000.0,
          totalAmount: 562000.0,
          sellerNetPayout: 500000.0,
          deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
          items: const [
            OrderItemSnapshotModel(
              id: 1,
              productId: 10,
              productCode: 'PRD-10',
              productTitle: 'Áo khoác da cừu vintage',
              condition: 'EXCELLENT',
              unitPrice: 500000.0,
              quantity: 1,
              subtotal: 500000.0,
            ),
          ],
        );
  }
}

class MockAuctionRepositoryForE2E extends AuctionRepository {
  MockAuctionRepositoryForE2E()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  AuctionDetailModel? stubDetail;
  bool placeBidShouldThrowConflict = false;

  @override
  Future<AuctionDetailModel> fetchAuctionDetail(int auctionId, {int? currentUserId}) async {
    return stubDetail ??
        AuctionDetailModel(
          id: auctionId,
          auctionCode: 'AUC-99',
          productId: 10,
          sellerId: 2,
          startingPrice: 100000.0,
          minBidIncrement: 20000.0,
          minimumNextBid: 120000.0,
          currentHighestBid: 100000.0,
          bidCount: 2,
          watchCount: 5,
          status: 'LIVE',
          auctionEndsAt: DateTime.now().add(const Duration(hours: 1)),
          productTitle: 'Máy ảnh Film Canon AE-1 Vintage',
          extendedCount: 2,
          recentBids: [
            AuctionBidItemModel(
              id: 1,
              auctionId: auctionId,
              bidderId: 88,
              bidAmount: 100000.0,
              triggeredAntiSniping: true,
              createdAt: DateTime.now(),
              bidderName: 'u***88',
              isLeading: true,
            ),
          ],
        );
  }

  @override
  Future<Map<String, dynamic>> placeBid(int auctionId, double bidAmount, {int? currentUserId}) async {
    if (placeBidShouldThrowConflict) {
      throw ApiException(
        statusCode: 409,
        errorCode: 'AUCTION_OUTBID_CONFLICT',
        errorCodeEnum: ErrorCodeEnum.auctionOutbidConflict,
        message: 'Mức giá vừa bị người khác vượt qua!',
        latestState: {
          'auction_id': auctionId,
          'current_highest_bid': 360000.0,
          'minimum_next_bid': 380000.0,
          'leading_bidder_id': 99,
          'bid_count': 13,
          'auction_ends_at': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
          'extended_count': 3,
        },
      );
    }
    return {'success': true};
  }
}

class MockSellerChannelRepositoryForE2E extends SellerChannelRepository {
  MockSellerChannelRepositoryForE2E()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  @override
  Future<SellerWalletOverviewModel> fetchWalletLedger({
    int page = 1,
    int perPage = 15,
  }) async {
    return const SellerWalletOverviewModel(
      walletBalance: 850000.0,
      escrowHeldBalance: 350000.0,
      totalEarned: 2400000.0,
      transactions: [
        WalletTransactionModel(
          id: 1,
          transactionCode: 'WTX-20261115-001',
          type: 'CREDIT',
          amount: 350000.0,
          balanceAfter: 850000.0,
          description: 'Giải ngân 100% tiền hàng đơn #IZI-777',
        ),
      ],
    );
  }
}

class MockEngagementRepositoryForE2E extends CommunicationEngagementRepository {
  MockEngagementRepositoryForE2E()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  @override
  Future<Map<String, dynamic>> fetchMessages(
    int conversationId, {
    int? afterId,
    int limit = 50,
    int? currentUserId,
  }) async {
    return {
      'conversation': const ConversationModel(
        id: 50,
        partnerId: 8,
        partnerName: 'Tiệm Đồ Gốm Vintage Bát Tràng',
        pinnedContext: ChatContextCardModel(
          contextType: 'PRODUCT',
          referenceId: 101,
          title: 'Bình hoa gốm hoa văn cổ điển',
          priceOrTotal: 380000.0,
        ),
      ),
      'messages': [
        MessageModel(
          id: 1,
          conversationId: 50,
          senderId: 8,
          senderName: 'Tiệm Đồ Gốm Vintage Bát Tràng',
          content: 'Dạ bình hoa gốm này nguyên bản không nứt vỡ bạn nhé!',
          isMine: false,
          createdAt: DateTime.now(),
        ),
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> fetchNotifications({
    String? category,
    int page = 1,
    int perPage = 15,
  }) async {
    return {
      'items': [
        NotificationItemModel(
          id: 1,
          userId: 1,
          category: 'ORDER',
          title: 'Đơn hàng #IZI-777 đã giao',
          body: 'Hãy kiểm tra món đồ và bấm xác nhận hài lòng để giải ngân cho tiệm.',
          deepLinkRoute: '/orders/777',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ],
      'unread_count': 1,
      'meta': const PaginationMeta(
        currentPage: 1,
        perPage: 15,
        total: 1,
        lastPage: 1,
        hasMorePages: false,
      ),
    };
  }

  @override
  Future<ReviewItemModel> submitVerifiedReview(
    int orderId, {
    required int rating,
    required String comment,
  }) async {
    return ReviewItemModel(
      id: 999,
      orderId: orderId,
      rating: rating,
      comment: comment,
      reviewerName: 'Người mua Đỗ Đức',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<SellerReviewsSummaryModel> fetchSellerReviews(
    int sellerId, {
    int? ratingFilter,
    int page = 1,
    int perPage = 10,
  }) async {
    return const SellerReviewsSummaryModel(
      sellerId: 8,
      shopName: 'Tiệm Đồ Gốm Vintage Bát Tràng',
      averageRating: 4.9,
      totalReviews: 35,
      starDistribution: {5: 32, 4: 3, 3: 0, 2: 0, 1: 0},
      reviews: [
        ReviewItemModel(
          id: 1,
          rating: 5,
          comment: 'Bình hoa gốm cổ đóng gói nhiều lớp xốp rất kỹ!',
          reviewerName: 'Người mua Đỗ Đức',
        ),
      ],
    );
  }
}

class MockProfileRepositoryForE2E extends ProfileRepository {
  MockProfileRepositoryForE2E(SecureTokenStorage storage, this.user)
      : super(
          dioClient: DioClient(
            tokenStorage: storage,
            serverTimeService: ServerTimeService.instance,
          ),
        );

  final UserModel user;

  @override
  Future<ProfileSummaryModel> fetchMyProfile() async {
    return ProfileSummaryModel(user: user);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuctionRepositoryForE2E mockAuctionRepo;
  late MockSellerChannelRepositoryForE2E mockSellerRepo;
  late MockEngagementRepositoryForE2E mockEngagementRepo;
  late MockHomeCatalogRepositoryForE2E mockHomeCatalogRepo;
  late MockOrderFulfillmentRepositoryForE2E mockOrderRepo;

  setUp(() {
    mockAuctionRepo = MockAuctionRepositoryForE2E();
    mockSellerRepo = MockSellerChannelRepositoryForE2E();
    mockEngagementRepo = MockEngagementRepositoryForE2E();
    mockHomeCatalogRepo = MockHomeCatalogRepositoryForE2E();
    mockOrderRepo = MockOrderFulfillmentRepositoryForE2E();
  });

  group('P7-12: Phase 07 Final Sign-Off & E2E Integration Suite', () {
    // -------------------------------------------------------------
    // SCENARIO 1: 5-Tab Navigation Shell Integration & Seasonal Decor
    // -------------------------------------------------------------
    testWidgets('Scenario 1: 5-Tab Navigation Shell switches all branches seamlessly with SeasonalDecorOverlay', (tester) async {
      final tokenStorage = SecureTokenStorage.inMemory();
      await tokenStorage.saveTokens(
        accessToken: 'e2e_test_token',
        userId: 1,
        role: 'buyer_seller',
        email: 'e2e@izithrift.vn',
      );
      const testUser = UserModel(
        id: 1,
        displayName: 'Tiệm Đồ Cũ Test',
        email: 'e2e@izithrift.vn',
        role: 'buyer_seller',
        status: 'ACTIVE',
        profile: UserProfileModel(seasonalDecorEnabled: true),
        sellerProfile: SellerProfileModel(
          shopSlug: 'tiem-do-cu-test',
          trustScore: 98.0,
          walletBalance: 1250000.0,
          escrowHeldBalance: 500000.0,
        ),
      );
      final mockProfileRepo = MockProfileRepositoryForE2E(tokenStorage, testUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureTokenStorageProvider.overrideWithValue(tokenStorage),
            seasonalDecorProvider.overrideWith(
              (ref) => SeasonalDecorNotifier(null, true),
            ),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            authViewModelProvider.overrideWith((ref) {
              final vm = AuthViewModel(
                authRepository: ref.watch(authRepositoryProvider),
                profileRepository: mockProfileRepo,
                tokenStorage: tokenStorage,
                seasonalDecorNotifier: ref.watch(seasonalDecorProvider.notifier),
              );
              vm.updateCurrentUser(testUser);
              return vm;
            }),
          ],
          child: const IzithriftApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify SeasonalDecorOverlay wraps the app
      expect(find.byType(SeasonalDecorOverlay), findsOneWidget);

      // Verify Tab 1: Trang chủ with unified izithrift Global AppBar
      expect(find.text('Trang chủ'), findsWidgets);
      expect(find.text('izithrift'), findsWidgets);

      // Verify all 5 destination labels exist in bottom navigation bar
      expect(find.text('Tin nhắn'), findsOneWidget);
      expect(find.text('Đăng bán'), findsOneWidget);
      expect(find.text('Đấu giá'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);

      // Switch to Tab 2: Tin nhắn
      await tester.tap(find.text('Tin nhắn').last);
      await tester.pumpAndSettle();
      expect(find.text('izithrift'), findsWidgets);
      expect(find.text('Tin nhắn'), findsWidgets);

      // Tap central Đăng bán CTA to verify Sell Bottom Sheet
      await tester.tap(find.text('Đăng bán').last);
      await tester.pumpAndSettle();
      expect(find.text('Đăng bán sản phẩm'), findsOneWidget);
      expect(find.text('Tạo phiên đấu giá'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Switch to Tab 4: Đấu giá
      await tester.tap(find.text('Đấu giá').last);
      await tester.pumpAndSettle();
      expect(find.text('izithrift'), findsWidgets);
      expect(find.text('Săn món đồ độc đáo với mức giá của bạn.'), findsOneWidget);

      // Switch to Tab 5: Cá nhân
      await tester.tap(find.text('Cá nhân').last);
      await tester.pumpAndSettle();
      expect(find.text('izithrift'), findsWidgets);
      expect(find.text('Tiệm Đồ Cũ Test'), findsOneWidget);
      expect(find.text('Kênh Người bán izithrift'), findsOneWidget);

      // Switch back to Tab 1: Trang chủ
      await tester.tap(find.text('Trang chủ').last);
      await tester.pumpAndSettle();
      expect(find.text('izithrift'), findsWidgets);
    });

    // -------------------------------------------------------------
    // SCENARIO 2: Search History Persistence (SharedPreferences Polish M-DS-02)
    // -------------------------------------------------------------
    testWidgets('Scenario 2: SharedPreferences Search History loads, adds, and clears keywords on M-DS-02', (tester) async {
      SharedPreferences.setMockInitialValues({
        CatalogSearchViewModel.recentKeywordsKey: ['áo dạ vintage 90s', 'túi da retro', 'đồng hồ cúc cu'],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeCatalogRepositoryProvider.overrideWithValue(mockHomeCatalogRepo),
          ],
          child: const MaterialApp(
            home: ProductSearchScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check Recent Searches Section Header
      expect(find.text('Tìm kiếm gần đây'), findsOneWidget);
      expect(find.text('Xóa tất cả'), findsOneWidget);

      // Check pre-populated Chips
      expect(find.text('áo dạ vintage 90s'), findsOneWidget);
      expect(find.text('túi da retro'), findsOneWidget);
      expect(find.text('đồng hồ cúc cu'), findsOneWidget);

      // Tap on a keyword chip to search
      await tester.tap(find.text('áo dạ vintage 90s'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Clear all keywords
      await tester.tap(find.text('Xóa tất cả'));
      await tester.pump();

      // Keywords section disappears
      expect(find.text('túi da retro'), findsNothing);
      expect(find.text('đồng hồ cúc cu'), findsNothing);
    });

    // -------------------------------------------------------------
    // SCENARIO 3: End-to-End Shopping & Escrow Flow (DEC-04)
    // -------------------------------------------------------------
    testWidgets('Scenario 3: E2E Checkout Preview (DEC-04) -> QR Escrow Hold -> Confirm Delivery 100% Release', (tester) async {
      // 1. Verify PriceBreakdownCard calculates and renders DEC-04 equation
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriceBreakdownCard(
              itemSubtotal: 500000.0,
              shippingFee: 25000.0,
              customBuyerProtectionFee: 37000.0,
              showSellerNetAmount: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết thanh toán'), findsOneWidget);
      expect(find.text('Tiền hàng'), findsOneWidget);
      expect(find.text('Phí bảo vệ người mua'), findsOneWidget);
      expect(find.text('Thực nhận của người bán'), findsOneWidget);
      expect(find.text('Tổng thanh toán'), findsOneWidget);

      // 2. Verify Order Detail in DELIVERED state displays Confirm Delivery CTA
      final orderDelivered = OrderModel(
        id: 777,
        orderCode: 'IZI-777',
        buyerId: 1,
        buyerName: 'Người mua Đỗ Đức',
        sellerId: 5,
        shopName: 'Tiệm Đồ Si Chú Ba',
        recipientName: 'Đỗ Minh Đức',
        recipientPhone: '0988776655',
        fullAddress: '123 Đường Xô Viết Nghệ Tĩnh, P.25, Q.Bình Thạnh, TP.HCM',
        shippingAddressSnapshot: const {
          'recipient_name': 'Đỗ Minh Đức',
          'recipient_phone': '0988776655',
          'full_address': '123 Đường Xô Viết Nghệ Tĩnh, P.25, Q.Bình Thạnh, TP.HCM',
        },
        orderStatus: 'DELIVERED',
        paymentStatus: 'PAID',
        escrowStatus: 'HELD',
        disputeStatus: 'NONE',
        itemSubtotal: 500000.0,
        shippingFee: 25000.0,
        buyerProtectionFee: 37000.0,
        totalAmount: 562000.0,
        sellerNetPayout: 500000.0, // 100% item subtotal
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
        items: const [
          OrderItemSnapshotModel(
            id: 1,
            productId: 10,
            productCode: 'PRD-10',
            productTitle: 'Áo khoác da cừu vintage',
            condition: 'EXCELLENT',
            unitPrice: 500000.0,
            quantity: 1,
            subtotal: 500000.0,
          ),
        ],
      );
      mockOrderRepo.stubOrder = orderDelivered;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderFulfillmentRepositoryProvider.overrideWithValue(mockOrderRepo),
          ],
          child: MaterialApp(
            home: PurchaseOrderDetailScreen(
              orderId: 777,
              initialOrder: orderDelivered,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Đơn hàng IZI-777'), findsOneWidget);
      expect(find.text('Mã đơn: IZI-777'), findsOneWidget);
      expect(find.text('Đã giao hàng'), findsOneWidget);
      expect(find.text('Đã thanh toán'), findsOneWidget);
      expect(find.text('Đã nhận được hàng & Hài lòng'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // SCENARIO 4: End-to-End Seller & Moderation Resubmit Flow (DEC-05)
    // -------------------------------------------------------------
    testWidgets('Scenario 4: Seller views rejection banner (DEC-05) and inspects immutable Wallet Ledger', (tester) async {
      final rejectedProduct = SellerProductItemModel(
        id: 88,
        productCode: 'PRD-88',
        title: 'Áo khoác bomber da lộn',
        slug: 'ao-khoac-bomber-da-lon',
        price: 250000.0,
        listingType: 'FIXED_PRICE',
        condition: 'FAIR',
        status: 'REJECTED',
        rejectionReason: 'Ảnh chụp chưa rõ chi tiết vết sờn cổ áo theo quy định BR-PR-03.',
        defectInfo: 'Sờn nhẹ ở cổ',
      );

      // Verify EditResubmitListingScreen renders DEC-05 rejection banner
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerChannelRepositoryProvider.overrideWithValue(mockSellerRepo),
          ],
          child: MaterialApp(
            home: EditResubmitListingScreen(
              productId: 88,
              initialProduct: rejectedProduct,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lý do từ chối kiểm duyệt (DEC-05)'), findsOneWidget);
      expect(find.text('Ảnh chụp chưa rõ chi tiết vết sờn cổ áo theo quy định BR-PR-03.'), findsOneWidget);
      expect(find.text('Gửi duyệt lại (Resubmit)'), findsOneWidget);

      // Verify Seller Wallet Ledger Screen
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerChannelRepositoryProvider.overrideWithValue(mockSellerRepo),
          ],
          child: const MaterialApp(
            home: SellerWalletLedgerScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sổ Cái Ví & Giao Dịch'), findsOneWidget);
      expect(find.textContaining('Sổ cái tài chính bất biến'), findsOneWidget);
      expect(find.text('Số dư ví khả dụng'), findsOneWidget);
      expect(find.textContaining('Ký quỹ đang giữ'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // SCENARIO 5: End-to-End Live Auction, Anti-Sniping (BR-AU-04) & 409 Conflict
    // -------------------------------------------------------------
    testWidgets('Scenario 5: Live Bidding Room displays Anti-Sniping warning and handles 409 Outbid Conflict retention', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Live Bidding Room with Anti-Sniping Triggered
      final liveDetail = AuctionDetailModel(
        id: 99,
        auctionCode: 'AUC-99',
        productId: 44,
        sellerId: 2,
        startingPrice: 100000.0,
        minBidIncrement: 20000.0,
        minimumNextBid: 340000.0,
        currentHighestBid: 320000.0,
        status: 'LIVE',
        bidCount: 12,
        watchCount: 8,
        auctionEndsAt: DateTime.now().add(const Duration(minutes: 3)),
        extendedCount: 2,
        productTitle: 'Máy ảnh Film Canon AE-1 Vintage',
        sellerDisplayName: 'Tiệm Đồ Xưa',
        leadingBidderId: 88,
        isOwner: true, // Owner rule BR-AC-02
        recentBids: [
          AuctionBidItemModel(
            id: 1,
            auctionId: 99,
            bidderId: 88,
            bidAmount: 320000.0,
            triggeredAntiSniping: true,
            createdAt: DateTime.now(),
            bidderName: 'u***88',
            isLeading: true,
          ),
        ],
      );

      mockAuctionRepo.stubDetail = liveDetail;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auctionRepositoryProvider.overrideWithValue(mockAuctionRepo),
          ],
          child: const MaterialApp(
            home: LiveBiddingRoomScreen(
              auctionId: 99,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Máy ảnh Film Canon AE-1 Vintage'), findsWidgets);
      expect(find.text('⚡ Đã kích hoạt Anti-Sniping (+2 phút) • Gia hạn lần #2'), findsOneWidget);
      expect(find.text('Chốt phiên sớm (M-AC-05)'), findsOneWidget);

      // 2. 409 Conflict Bid Sheet Retention (M-AC-04)
      mockAuctionRepo.placeBidShouldThrowConflict = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auctionRepositoryProvider.overrideWithValue(mockAuctionRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BidPlacementBottomSheet(
                auctionId: 99,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🔨 Đặt Giá Thầu'), findsOneWidget);
      expect(find.text('Tối thiểu'), findsOneWidget);
      expect(find.text('+1 bước'), findsOneWidget);

      // Tap confirm bid -> triggers 409 conflict
      await tester.tap(find.textContaining('Xác nhận đặt giá'));
      await tester.pumpAndSettle();

      // Sheet is NOT closed! It retains state and displays 409 conflict banner
      expect(find.text('Mức giá vừa bị người khác vượt qua!'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // SCENARIO 6: End-to-End Chat Polling, Notification Deep-Link & Verified Review
    // -------------------------------------------------------------
    testWidgets('Scenario 6: 1-on-1 Chat Room with pinned context, Notifications Center & Verified Review submission (BR-RV-01)', (tester) async {
      // 1. Chat Room (M-CM-02) with pinned product card
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockEngagementRepo),
          ],
          child: const MaterialApp(
            home: ChatRoomScreen(
              conversationId: 50,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tiệm Đồ Gốm Vintage Bát Tràng'), findsOneWidget);
      expect(find.text('Bình hoa gốm hoa văn cổ điển'), findsOneWidget);
      expect(find.text('Xem đồ'), findsOneWidget);
      expect(find.text('Dạ bình hoa gốm này nguyên bản không nứt vỡ bạn nhé!'), findsOneWidget);

      // 2. Notification Center (M-NT-01) with deep-link alert
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockEngagementRepo),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Thông Báo'), findsOneWidget);
      expect(find.text('Đơn hàng #IZI-777 đã giao'), findsOneWidget);

      // 3. Submit Verified Review (M-RV-01) for Completed Order
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockEngagementRepo),
          ],
          child: const MaterialApp(
            home: SubmitVerifiedReviewScreen(
              orderId: 777,
              orderCode: 'IZI-777',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đánh Giá Đơn Hàng'), findsOneWidget);
      expect(find.text('Đơn Hàng: #IZI-777'), findsOneWidget);
      expect(find.text('Tuyệt vời, đúng chất vintage!'), findsOneWidget);
      expect(find.text('Đánh giá của bạn sẽ được gắn huy hiệu Đã mua hàng xác thực để tăng độ tin cậy cho cộng đồng izithrift.'), findsOneWidget);
      expect(find.text('Gửi Đánh Giá Xác Thực'), findsOneWidget);

      // 4. Seller Reviews List (M-RV-02)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockEngagementRepo),
          ],
          child: const MaterialApp(
            home: SellerReviewsListScreen(
              sellerId: 8,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Đánh Giá Tiệm'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('35 đánh giá'), findsOneWidget);
      expect(find.text('Bình hoa gốm cổ đóng gói nhiều lớp xốp rất kỹ!'), findsOneWidget);
      expect(find.text('Đã mua hàng'), findsOneWidget);
    });
  });
}
