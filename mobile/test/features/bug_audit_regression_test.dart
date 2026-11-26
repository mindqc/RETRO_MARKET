import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izithrift/core/demo/retro_demo_marketplace_store.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/features/cart/models/cart_item_model.dart';
import 'package:izithrift/features/cart/models/cart_model.dart';
import 'package:izithrift/features/cart/models/cart_seller_group_model.dart';
import 'package:izithrift/features/cart/models/checkout_preview_model.dart';
import 'package:izithrift/features/cart/models/payment_session_model.dart';
import 'package:izithrift/features/cart/repositories/cart_checkout_repository.dart';
import 'package:izithrift/features/cart/viewmodels/cart_view_model.dart';
import 'package:izithrift/features/cart/viewmodels/checkout_view_model.dart';
import 'package:izithrift/features/catalog/models/product_filter_query.dart';
import 'package:izithrift/features/catalog/models/product_summary_model.dart';
import 'package:izithrift/features/catalog/repositories/home_catalog_repository.dart';
import 'package:izithrift/features/catalog/viewmodels/catalog_search_view_model.dart';
import 'package:izithrift/features/engagement/models/conversation_model.dart';
import 'package:izithrift/features/engagement/models/notification_item_model.dart';
import 'package:izithrift/features/engagement/models/violation_report_payload.dart';
import 'package:izithrift/features/engagement/repositories/communication_engagement_repository.dart';
import 'package:izithrift/features/engagement/viewmodels/chat_view_model.dart';
import 'package:izithrift/features/engagement/viewmodels/notification_view_model.dart';
import 'package:izithrift/features/profile/models/user_address_model.dart';

class _RegressionHomeCatalogRepository extends HomeCatalogRepository {
  _RegressionHomeCatalogRepository()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  ProductFilterQuery? lastQuery;

  @override
  Future<PaginatedResponse<ProductSummaryModel>> searchProducts(
    ProductFilterQuery query,
  ) async {
    lastQuery = query;
    return const PaginatedResponse<ProductSummaryModel>(
      items: [],
      meta: PaginationMeta(
        currentPage: 1,
        perPage: 12,
        total: 0,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }
}

class _RegressionCartCheckoutRepository extends CartCheckoutRepository {
  _RegressionCartCheckoutRepository()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  CartModel stubCart = const CartModel(
    cartId: 1,
    sellerGroups: [],
    totalItemsCount: 0,
  );
  CheckoutPreviewModel? stubPreview;
  bool failPlaceOrder = false;

  @override
  Future<CartModel> fetchCart() async => stubCart;

  @override
  Future<CheckoutPreviewModel> previewCheckout({
    required String source,
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    int? addressId,
  }) async {
    return stubPreview ??
        const CheckoutPreviewModel(
          source: 'CART',
          sellersCount: 1,
          itemsCount: 1,
          totalItemSubtotal: 300000,
          totalBuyerProtectionFee: 25000,
          totalShippingFee: 0,
          grandTotalAmount: 325000,
          orderGroups: [
            CheckoutOrderGroupPreviewModel(
              sellerId: 502,
              shopName: 'Retro Closet Quận 1',
              items: [
                CartItemModel(
                  id: 1,
                  productId: 8101,
                  productCode: 'PRD-8101',
                  title: 'Áo Khoác Varsity 90s',
                  condition: 'LIKE_NEW',
                  unitPrice: 300000,
                  itemSubtotal: 300000,
                ),
              ],
              itemSubtotal: 300000,
              buyerProtectionFee: 25000,
              totalAmount: 325000,
              sellerNetAmount: 300000,
            ),
          ],
        );
  }

  @override
  Future<PaymentSessionModel> placeOrder({
    required String source,
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    required int shippingAddressId,
    String? note,
  }) async {
    if (failPlaceOrder) {
      throw Exception('Simulated network error');
    }
    return PaymentSessionModel(
      paymentId: 1,
      paymentCode: 'PAY-001',
      orderId: 10,
      orderCode: 'ORD-001',
      amount: 325000,
      paymentStatus: 'PENDING',
      escrowStatus: 'HELD',
      paymentExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
      qrCodeUrl: 'https://example.com/qr.png',
      transferContent: 'IZI 1',
    );
  }
}

class _RegressionEngagementRepository extends CommunicationEngagementRepository {
  _RegressionEngagementRepository()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  bool failCalls = false;
  List<NotificationItemModel> stubNotifications = [];

  @override
  Future<PaginatedResponse<ConversationModel>> fetchConversations({
    int page = 1,
    int perPage = 15,
    int? currentUserId,
  }) async {
    if (failCalls) throw Exception('Offline');
    return const PaginatedResponse<ConversationModel>(
      items: [],
      meta: PaginationMeta(
        currentPage: 1,
        perPage: 15,
        total: 0,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> fetchMessages(
    int conversationId, {
    int? afterId,
    int limit = 50,
    int? currentUserId,
  }) async {
    if (failCalls) throw Exception('Offline');
    return {
      'conversation': ConversationModel(
        id: conversationId,
        partnerId: 501,
        partnerName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
      ),
      'messages': const [],
    };
  }

  @override
  Future<bool> submitReport(ViolationReportPayload payload) async {
    if (failCalls) throw Exception('Offline');
    return true;
  }

  @override
  Future<Map<String, dynamic>> fetchNotifications({
    String? category,
    int page = 1,
    int perPage = 15,
  }) async {
    final filtered = category == null
        ? stubNotifications
        : stubNotifications
            .where((n) => n.category.toUpperCase() == category.toUpperCase())
            .toList();
    return {
      'items': filtered,
      'unread_count': filtered.where((n) => !n.isRead).length,
    };
  }
}

void main() {
  group('Bug Audit Regression Tests', () {
    test('CatalogSearchViewModel clears keyword, category, and brand when set to null', () async {
      final repo = _RegressionHomeCatalogRepository();
      final container = ProviderContainer(
        overrides: [
          homeCatalogRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final vm = container.read(catalogSearchViewModelProvider);

      await vm.setKeyword('vintage');
      await vm.setCategory(3);
      await vm.setBrand(7);
      expect(vm.currentQuery.q, equals('vintage'));
      expect(vm.currentQuery.categoryId, equals(3));
      expect(vm.currentQuery.brandId, equals(7));

      await vm.setKeyword(null);
      await vm.setCategory(null);
      await vm.setBrand(null);

      expect(vm.currentQuery.q, isNull);
      expect(vm.currentQuery.categoryId, isNull);
      expect(vm.currentQuery.brandId, isNull);
      expect(repo.lastQuery?.q, isNull);
      expect(repo.lastQuery?.categoryId, isNull);
      expect(repo.lastQuery?.brandId, isNull);
    });

    test('CartViewModel.toggleSellerGroupSelection safely ignores empty cart or unknown sellerId', () async {
      final repo = _RegressionCartCheckoutRepository();
      final vm = CartViewModel(repository: repo);

      // Empty sellerGroups should not throw StateError
      await vm.loadCart();
      expect(() => vm.toggleSellerGroupSelection(999), returnsNormally);

      // Unknown sellerId in non-empty cart should not mutate other seller groups
      repo.stubCart = const CartModel(
        cartId: 1,
        totalItemsCount: 1,
        sellerGroups: [
          CartSellerGroupModel(
            sellerId: 502,
            shopName: 'Retro Closet Quận 1',
            items: [
              CartItemModel(
                id: 10,
                productId: 8101,
                productCode: 'PRD-8101',
                title: 'Áo Khoác Varsity',
                condition: 'LIKE_NEW',
                unitPrice: 389000,
                itemSubtotal: 389000,
                isSelected: true,
              ),
            ],
          ),
        ],
      );
      await vm.loadCart();
      vm.toggleSellerGroupSelection(9999);
      expect(vm.state.data!.sellerGroups.first.items.first.isSelected, isTrue);
    });

    test('CheckoutViewModel preserves preview state on validation or submission failure', () async {
      final repo = _RegressionCartCheckoutRepository();
      final vm = CheckoutViewModel(repository: repo);
      await vm.loadCheckoutPreview(source: 'CART');
      expect(vm.state.isSuccess, isTrue);

      // Missing shipping address should keep ViewState.success while exposing errorMessage
      final missingAddrResult = await vm.placeOrder();
      expect(missingAddrResult, isNull);
      expect(vm.state.isSuccess, isTrue);
      expect(vm.state.data, isNotNull);
      expect(
        vm.errorMessage,
        equals('Vui lòng chọn hoặc thêm địa chỉ nhận hàng.'),
      );

      // API failure during placeOrder should also keep ViewState.success
      vm.selectedAddress = const UserAddressModel(
        id: 1,
        recipientName: 'Nguyễn Văn A',
        recipientPhone: '0901234567',
        provinceCity: 'TP.HCM',
        districtWard: 'Quận 1',
        streetAddress: '123 Lê Lợi',
        isDefault: true,
      );
      repo.failPlaceOrder = true;
      final failedApiResult = await vm.placeOrder();
      expect(failedApiResult, isNull);
      expect(vm.state.isSuccess, isTrue);
      expect(vm.errorMessage, contains('Lỗi khi đặt hàng:'));
    });

    test('NotificationViewModel preserves all categories after pull-to-refresh on a filtered tab', () async {
      final repo = _RegressionEngagementRepository();
      repo.stubNotifications = [
        NotificationItemModel(
          id: 1,
          userId: 1,
          category: 'ORDER',
          title: 'Đơn hàng mới',
          body: 'Đơn đã được tạo',
          createdAt: DateTime.now(),
        ),
        NotificationItemModel(
          id: 2,
          userId: 1,
          category: 'AUCTION',
          title: 'Phiên đấu giá sắp kết thúc',
          body: 'Còn 5 phút',
          createdAt: DateTime.now(),
        ),
      ];

      final vm = NotificationViewModel(repository: repo);
      await vm.fetchNotifications();

      vm.selectTab(NotificationTabFilter.order);
      expect(vm.filteredNotifications.length, equals(1));

      // Pull-to-refresh while on Order tab
      await vm.fetchNotifications(refresh: true);
      expect(vm.filteredNotifications.length, equals(1));

      // Switching to Auction tab should still show the Auction notification
      vm.selectTab(NotificationTabFilter.auction);
      expect(vm.filteredNotifications.length, equals(1));
      expect(vm.filteredNotifications.first.id, equals(2));
    });

    test('ChatViewModel demo report succeeds without block and syncs inbox when blocked', () async {
      final repo = _RegressionEngagementRepository()..failCalls = true;
      final vm = ChatViewModel(
        repository: repo,
        currentUserId: 1,
        enablePolling: false,
        enableDemoFallback: true,
      );
      addTearDown(vm.dispose);

      await vm.loadInbox();
      expect(vm.conversations, isNotEmpty);
      final targetConvId = vm.conversations.first.id;

      await vm.enterChatRoom(targetConvId);

      // Report without blocking must succeed in demo mode
      final reportOnly = await vm.reportViolation(
        conversationId: targetConvId,
        reasonCategory: 'SPAM',
        description: 'Kiểm thử báo cáo không chặn',
        blockConversation: false,
      );
      expect(reportOnly, isTrue);
      expect(vm.isBlocked, isFalse);

      // Report with blocking must lock room AND sync inbox conversation entry
      final reportAndBlock = await vm.reportViolation(
        conversationId: targetConvId,
        reasonCategory: 'SCAM',
        description: 'Kiểm thử báo cáo kèm chặn',
        blockConversation: true,
      );
      expect(reportAndBlock, isTrue);
      expect(vm.isBlocked, isTrue);
      final inboxEntry =
          vm.conversations.firstWhere((c) => c.id == targetConvId);
      expect(inboxEntry.isBlocked, isTrue);
    });

    test('RetroDemoMarketplaceStore resolves demo auction/sold products and demo seller storefronts', () {
      final store = RetroDemoMarketplaceStore();

      // Pinned demo auction product IDs
      final auctionProduct = store.getDemoProductDetail(9101);
      expect(auctionProduct, isNotNull);
      expect(auctionProduct!.id, equals(9101));

      // Demo sold profile product IDs
      final soldProduct1 = store.getDemoProductDetail(9401);
      final soldProduct2 = store.getDemoProductDetail(9402);
      expect(soldProduct1, isNotNull);
      expect(soldProduct2, isNotNull);
      expect(soldProduct1!.availableQuantity, equals(0));

      // Demo seller storefronts + local follow state
      final storefront = store.getDemoSellerStorefront(502);
      expect(storefront, isNotNull);
      expect(storefront!.userId, equals(502));
      expect(storefront.isFollowing, isFalse);

      final nowFollowing = store.toggleLocalFollowSeller(502);
      expect(nowFollowing, isTrue);
      final updatedStorefront = store.getDemoSellerStorefront(502);
      expect(updatedStorefront!.isFollowing, isTrue);
      expect(
        updatedStorefront.followersCount,
        equals(storefront.followersCount + 1),
      );
    });
  });
}
