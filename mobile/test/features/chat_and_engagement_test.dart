import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/features/catalog/models/product_summary_model.dart';
import 'package:izithrift/features/catalog/models/review_item_model.dart';
import 'package:izithrift/features/home/models/featured_seller_model.dart';
import 'package:izithrift/features/engagement/models/chat_context_card_model.dart';
import 'package:izithrift/features/engagement/models/conversation_model.dart';
import 'package:izithrift/features/engagement/models/message_model.dart';
import 'package:izithrift/features/engagement/models/notification_item_model.dart';
import 'package:izithrift/features/engagement/models/seller_reviews_summary_model.dart';
import 'package:izithrift/features/engagement/models/violation_report_payload.dart';
import 'package:izithrift/features/engagement/repositories/communication_engagement_repository.dart';
import 'package:izithrift/features/engagement/screens/conversation_inbox_screen.dart';
import 'package:izithrift/features/engagement/screens/chat_room_screen.dart';
import 'package:izithrift/features/engagement/screens/report_and_block_modal.dart';
import 'package:izithrift/features/engagement/screens/notification_center_screen.dart';
import 'package:izithrift/features/engagement/screens/saved_favorites_and_shops_screen.dart';
import 'package:izithrift/features/engagement/screens/submit_verified_review_screen.dart';
import 'package:izithrift/features/engagement/screens/seller_reviews_list_screen.dart';
import 'package:izithrift/features/engagement/viewmodels/chat_view_model.dart';
import 'package:izithrift/features/engagement/viewmodels/notification_view_model.dart';
import 'package:izithrift/features/engagement/viewmodels/engagement_and_review_view_model.dart';

/// Mock Implementation of CommunicationEngagementRepository
class MockCommunicationEngagementRepository extends CommunicationEngagementRepository {
  MockCommunicationEngagementRepository()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  List<ConversationModel> stubConversations = [];
  Map<int, List<MessageModel>> stubMessages = {};
  List<NotificationItemModel> stubNotifications = [];
  int stubUnreadCount = 0;
  List<ProductSummaryModel> stubFavorites = [];
  SellerReviewsSummaryModel? stubSellerReviews;

  bool submitReportCalled = false;
  ViolationReportPayload? lastReportPayload;
  bool submitReviewCalled = false;
  bool toggleFavoriteCalled = false;
  bool toggleFollowCalled = false;

  @override
  Future<PaginatedResponse<ConversationModel>> fetchConversations({
    int page = 1,
    int perPage = 15,
    int? currentUserId,
  }) async {
    return PaginatedResponse<ConversationModel>(
      items: stubConversations,
      meta: PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: stubConversations.length,
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
    final conv = stubConversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => ConversationModel(
        id: conversationId,
        partnerId: 99,
        partnerName: 'Người bán vintage',
      ),
    );

    final allMsgs = stubMessages[conversationId] ?? [];
    List<MessageModel> filtered = allMsgs;
    if (afterId != null) {
      filtered = allMsgs.where((m) => m.id > afterId).toList();
    }

    return {
      'conversation': conv,
      'messages': filtered,
    };
  }

  @override
  Future<MessageModel> sendMessage(
    int conversationId, {
    required String content,
    int? attachedProductId,
    int? currentUserId,
  }) async {
    final newMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      senderId: currentUserId ?? 1,
      senderName: 'Tôi',
      content: content,
      isMine: true,
      createdAt: DateTime.now(),
    );
    stubMessages.putIfAbsent(conversationId, () => []).add(newMsg);
    return newMsg;
  }

  @override
  Future<bool> submitReport(ViolationReportPayload payload) async {
    submitReportCalled = true;
    lastReportPayload = payload;
    return true;
  }

  @override
  Future<Map<String, dynamic>> fetchNotifications({
    String? category,
    int page = 1,
    int perPage = 15,
  }) async {
    List<NotificationItemModel> items = stubNotifications;
    if (category != null && category.isNotEmpty) {
      items = stubNotifications.where((n) => n.category == category).toList();
    }
    return {
      'items': items,
      'unread_count': stubUnreadCount,
      'meta': PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: items.length,
        lastPage: 1,
        hasMorePages: false,
      ),
    };
  }

  @override
  Future<bool> markNotificationAsRead(int notificationId) async {
    if (stubUnreadCount > 0) stubUnreadCount--;
    return true;
  }

  @override
  Future<int> markAllNotificationsAsRead() async {
    final count = stubUnreadCount;
    stubUnreadCount = 0;
    return count;
  }

  @override
  Future<PaginatedResponse<ProductSummaryModel>> fetchFavorites({
    int page = 1,
    int perPage = 12,
  }) async {
    return PaginatedResponse<ProductSummaryModel>(
      items: stubFavorites,
      meta: PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: stubFavorites.length,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<bool> toggleFavorite(int productId) async {
    toggleFavoriteCalled = true;
    return false; // Toggled off
  }

  @override
  Future<bool> toggleFollowSeller(int sellerId) async {
    toggleFollowCalled = true;
    return false; // Toggled off
  }

  @override
  Future<ReviewItemModel> submitVerifiedReview(
    int orderId, {
    required int rating,
    required String comment,
  }) async {
    submitReviewCalled = true;
    return ReviewItemModel(
      id: 999,
      orderId: orderId,
      rating: rating,
      comment: comment,
      reviewerName: 'Tôi',
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
    return stubSellerReviews ??
        SellerReviewsSummaryModel(
          sellerId: sellerId,
          shopName: 'Tiệm đồ si vintage Sài Gòn',
          averageRating: 4.8,
          totalReviews: 25,
          starDistribution: const {5: 20, 4: 3, 3: 1, 2: 1, 1: 0},
          reviews: const [],
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCommunicationEngagementRepository mockRepo;

  setUp(() {
    mockRepo = MockCommunicationEngagementRepository();
  });

  group('P7-11: Data Models Parsing & Mapping Tests', () {
    test('ConversationModel parses backend JSON with context product & other_user correctly', () {
      final json = {
        'id': 101,
        'other_user': {
          'id': 42,
          'display_name': 'Tiệm Vintage Đà Lạt',
          'avatar_url': 'https://example.com/dalat.jpg',
          'shop_slug': 'tiem-vintage-da-lat',
          'trust_score': 98.5,
        },
        'unread_count': 3,
        'last_message_preview': 'Chào bạn, áo khoác này còn không?',
        'last_message_at': '2026-11-15T08:30:00Z',
        'is_blocked': false,
        'context_product': {
          'id': 505,
          'title': 'Áo khoác dạ vintage 90s',
          'price': 450000,
          'image_url': 'https://example.com/coat.jpg',
          'status': 'APPROVED',
        },
      };

      final conv = ConversationModel.fromJson(json, currentUserId: 1);

      expect(conv.id, equals(101));
      expect(conv.partnerId, equals(42));
      expect(conv.otherUser.displayName, equals('Tiệm Vintage Đà Lạt'));
      expect(conv.unreadCount, equals(3));
      expect(conv.lastMessagePreview, contains('áo khoác'));
      expect(conv.isBlocked, isFalse);
      expect(conv.contextProduct, isNotNull);
      expect(conv.contextProduct!.title, equals('Áo khoác dạ vintage 90s'));
      expect(conv.contextProduct!.price, equals(450000.0));
      expect(conv.formattedTime, equals('15:30')); // Parsed local or UTC time string
    });

    test('MessageModel detects mine vs partner messages via currentUserId', () {
      final json = {
        'id': 201,
        'conversation_id': 101,
        'sender_id': 1,
        'sender': {'display_name': 'Nguyễn Văn A'},
        'message_text': 'Món này còn mới bao nhiêu % ạ?',
        'is_read': true,
        'created_at': '2026-11-15T09:00:00Z',
      };

      final msgMe = MessageModel.fromJson(json, currentUserId: 1);
      final msgOther = MessageModel.fromJson(json, currentUserId: 42);

      expect(msgMe.isMine, isTrue);
      expect(msgOther.isMine, isFalse);
      expect(msgMe.content, equals('Món này còn mới bao nhiêu % ạ?'));
      expect(msgMe.isRead, isTrue);
    });

    test('NotificationItemModel normalizes category and deep link route correctly', () {
      final jsonOrder = {
        'id': 1,
        'user_id': 10,
        'type': 'ORDER_SHIPPED',
        'title': 'Đơn hàng đang giao',
        'body': 'Đơn hàng #IZI-99 đã được bàn giao cho đơn vị vận chuyển',
        'target_type': 'ORDER',
        'target_id': 99,
        'deep_link_route': '/orders/99',
        'is_read': false,
        'created_at': '2026-11-15T10:00:00Z',
      };

      final jsonAuction = {
        'id': 2,
        'user_id': 10,
        'type': 'AUCTION_OUTBID',
        'title': 'Bạn đã bị vượt giá!',
        'body': 'Có người vừa trả giá cao hơn cho món đồ vintage',
        'target_type': 'AUCTION',
        'target_id': 88,
        'deep_link_route': '/auctions/88',
        'is_read': true,
        'created_at': '2026-11-15T10:05:00Z',
      };

      final notifOrder = NotificationItemModel.fromJson(jsonOrder);
      final notifAuction = NotificationItemModel.fromJson(jsonAuction);

      expect(notifOrder.category, equals('ORDER'));
      expect(notifOrder.isOrderType, isTrue);
      expect(notifOrder.deepLinkRoute, equals('/orders/99'));
      expect(notifOrder.isRead, isFalse);

      expect(notifAuction.category, equals('AUCTION'));
      expect(notifAuction.isAuctionType, isTrue);
      expect(notifAuction.deepLinkRoute, equals('/auctions/88'));
      expect(notifAuction.isRead, isTrue);
    });

    test('SellerReviewsSummaryModel aggregates star distribution and score accurately', () {
      final json = {
        'seller_id': 42,
        'shop_name': 'Tiệm Vintage Đà Lạt',
        'average_rating': 4.7,
        'total_reviews': 10,
        'star_distribution': {
          '5': 7,
          '4': 2,
          '3': 0,
          '2': 1,
          '1': 0,
        },
        'data': [
          {
            'id': 1,
            'rating': 5,
            'comment': 'Đồ đẹp đúng mô tả, đóng gói rất cẩn thận!',
            'reviewer_name': 'Thảo Nguyễn',
            'created_at': '2026-11-14T12:00:00Z',
          }
        ],
      };

      final summary = SellerReviewsSummaryModel.fromJson(json);

      expect(summary.averageRating, equals(4.7));
      expect(summary.totalReviews, equals(10));
      expect(summary.starDistribution[5], equals(7));
      expect(summary.starDistribution[4], equals(2));
      expect(summary.reviews.length, equals(1));
      expect(summary.reviews.first.userName, equals('Thảo Nguyễn'));
    });
  });

  group('P7-11: ViewModels Unit Tests', () {
    test('ChatViewModel loads inbox and aggregates total unread counter', () async {
      mockRepo.stubConversations = [
        const ConversationModel(
          id: 1,
          partnerId: 10,
          partnerName: 'Shop A',
          unreadCount: 2,
        ),
        const ConversationModel(
          id: 2,
          partnerId: 20,
          partnerName: 'Shop B',
          unreadCount: 3,
        ),
      ];

      final vm = ChatViewModel(repository: mockRepo, currentUserId: 1, enablePolling: false);
      await vm.loadInbox();

      expect(vm.conversations.length, equals(2));
      expect(vm.totalUnreadCount, equals(5));
      expect(vm.state.isSuccess, isTrue);
    });

    test('ChatViewModel enterChatRoom fetches history and sendMessage appends message', () async {
      mockRepo.stubConversations = [
        const ConversationModel(
          id: 10,
          partnerId: 5,
          partnerName: 'Shop Vintage',
        ),
      ];
      mockRepo.stubMessages[10] = [
        MessageModel(
          id: 100,
          conversationId: 10,
          senderId: 5,
          senderName: 'Shop Vintage',
          content: 'Xin chào bạn!',
          createdAt: DateTime.now(),
        ),
      ];

      final vm = ChatViewModel(repository: mockRepo, currentUserId: 1, enablePolling: false);
      await vm.enterChatRoom(10);

      expect(vm.messages.length, equals(1));
      expect(vm.messages.first.content, equals('Xin chào bạn!'));

      final sendOk = await vm.sendMessage('Sản phẩm còn bảo hành không shop?');
      expect(sendOk, isTrue);
      expect(vm.messages.length, equals(2));
      expect(vm.messages.last.content, equals('Sản phẩm còn bảo hành không shop?'));
      expect(vm.messages.last.isMine, isTrue);
    });

    test('ChatViewModel reportViolation locks room and pauses polling', () async {
      mockRepo.stubConversations = [
        const ConversationModel(
          id: 10,
          partnerId: 5,
          partnerName: 'Shop Lừa Đảo',
        ),
      ];

      final vm = ChatViewModel(repository: mockRepo, currentUserId: 1, enablePolling: false);
      await vm.enterChatRoom(10);

      final reportOk = await vm.reportViolation(
        conversationId: 10,
        reasonCategory: 'SCAM',
        description: 'Người bán yêu cầu chuyển khoản ngoài ứng dụng',
        blockConversation: true,
      );

      expect(reportOk, isTrue);
      expect(vm.isBlocked, isTrue);
      expect(mockRepo.submitReportCalled, isTrue);
      expect(mockRepo.lastReportPayload?.reasonCategory, equals('SCAM'));
      expect(mockRepo.lastReportPayload?.blockConversation, isTrue);
    });

    test('NotificationViewModel tab filter and optimistic read-all', () async {
      mockRepo.stubNotifications = [
        NotificationItemModel(
          id: 1,
          userId: 1,
          category: 'ORDER',
          title: 'Đơn hàng mới',
          body: 'Đơn đã xác nhận',
          createdAt: DateTime.now(),
          isRead: false,
        ),
        NotificationItemModel(
          id: 2,
          userId: 1,
          category: 'AUCTION',
          title: 'Đấu giá sắp kết thúc',
          body: 'Còn 15 phút',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];
      mockRepo.stubUnreadCount = 2;

      final vm = NotificationViewModel(repository: mockRepo);
      await vm.fetchNotifications();

      expect(vm.notifications.length, equals(2));
      expect(vm.unreadCount, equals(2));

      // Filter Tab
      vm.selectTab(NotificationTabFilter.order);
      expect(vm.filteredNotifications.length, equals(1));
      expect(vm.filteredNotifications.first.category, equals('ORDER'));

      // Mark All Read
      await vm.markAllAsRead();
      expect(vm.unreadCount, equals(0));
      expect(vm.notifications.every((n) => n.isRead), isTrue);
    });

    test('EngagementViewModel loads favorites and toggles optimistically', () async {
      mockRepo.stubFavorites = [
        const ProductSummaryModel(
          id: 10,
          productCode: 'PRD-10',
          title: 'Áo khoác dù vintage 90s',
          slug: 'ao-khoac-du-vintage-90s',
          listingType: 'FIXED_PRICE',
          condition: 'LIKE_NEW',
          price: 320000,
          status: 'APPROVED',
          isFavorited: true,
        ),
      ];

      final vm = EngagementViewModel(repository: mockRepo);
      await vm.loadEngagementData();

      expect(vm.favoriteProducts.length, equals(1));
      expect(vm.favoriteProducts.first.title, contains('Áo khoác'));

      // Toggle favorite off
      final isFav = await vm.toggleFavoriteProduct(10);
      expect(isFav, isFalse);
      expect(vm.favoriteProducts.isEmpty, isTrue);
      expect(mockRepo.toggleFavoriteCalled, isTrue);

      // Toggle follow shop
      const shop = FeaturedSellerModel(
        id: 7,
        userId: 14,
        shopName: 'Tiệm Đồ Si Chú Ba',
        shopSlug: 'tiem-do-si-chu-ba',
      );
      final isFollow = await vm.toggleFollowSeller(shop);
      expect(isFollow, isFalse);
      expect(mockRepo.toggleFollowCalled, isTrue);
    });

    test('ReviewViewModel validates rating 1..5 and comment length >= 5 (BR-RV-01)', () async {
      final vm = ReviewViewModel(repository: mockRepo);

      // Invalid Rating (0 stars)
      final okRating0 = await vm.submitVerifiedReview(orderId: 50, rating: 0, comment: 'Đồ đẹp quá shop ơi');
      expect(okRating0, isFalse);
      expect(vm.errorMessage, contains('từ 1 đến 5'));

      // Invalid Comment (< 5 chars)
      final okShortComment = await vm.submitVerifiedReview(orderId: 50, rating: 5, comment: 'Đẹp');
      expect(okShortComment, isFalse);
      expect(vm.errorMessage, contains('tối thiểu 5 ký tự'));

      // Valid review
      final okValid = await vm.submitVerifiedReview(
        orderId: 50,
        rating: 5,
        comment: 'Đồ vintage cực kỳ chất lượng, đóng gói rất kỹ lưỡng!',
      );
      expect(okValid, isTrue);
      expect(mockRepo.submitReviewCalled, isTrue);
    });
  });

  group('P7-11: Screen Widget Smoke & Interaction Tests', () {
    testWidgets('M-CM-01: ConversationInboxScreen renders conversation list and unread badge', (tester) async {
      mockRepo.stubConversations = [
        const ConversationModel(
          id: 1,
          partnerId: 42,
          partnerName: 'Tiệm Đồ Cũ Sài Gòn',
          unreadCount: 4,
          lastMessagePreview: 'Dạ shop đã gửi hàng sáng nay rồi nhé!',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ConversationInboxScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('izithrift • Tin nhắn'), findsOneWidget);
      expect(find.text('Tiệm Đồ Cũ Sài Gòn'), findsOneWidget);
      expect(find.text('Dạ shop đã gửi hàng sáng nay rồi nhé!'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('M-CM-02: ChatRoomScreen renders pinned product context & message bubbles', (tester) async {
      mockRepo.stubConversations = [
        const ConversationModel(
          id: 10,
          partnerId: 42,
          partnerName: 'Tiệm Đồ Cũ Sài Gòn',
          pinnedContext: ChatContextCardModel(
            contextType: 'PRODUCT',
            referenceId: 88,
            title: 'Áo khoác bomber da thật',
            priceOrTotal: 750000,
          ),
        ),
      ];
      mockRepo.stubMessages[10] = [
        MessageModel(
          id: 1,
          conversationId: 10,
          senderId: 42,
          senderName: 'Tiệm Đồ Cũ Sài Gòn',
          content: 'Chào bạn, áo bomber này size L chuẩn âu nhé.',
          isMine: false,
          createdAt: DateTime.now(),
        ),
        MessageModel(
          id: 2,
          conversationId: 10,
          senderId: 1,
          senderName: 'Tôi',
          content: 'Dạ em cảm ơn shop, để em đặt luôn!',
          isMine: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ChatRoomScreen(conversationId: 10),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tiệm Đồ Cũ Sài Gòn'), findsOneWidget);
      expect(find.text('Áo khoác bomber da thật'), findsOneWidget);
      expect(find.text('Xem đồ'), findsOneWidget);
      expect(find.text('Chào bạn, áo bomber này size L chuẩn âu nhé.'), findsOneWidget);
      expect(find.text('Dạ em cảm ơn shop, để em đặt luôn!'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('M-CM-03: ReportAndBlockModal renders violation options & submit button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ReportAndBlockModal(
                conversationId: 10,
                targetUserId: 42,
                targetUserName: 'Người bán vi phạm',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Báo Cáo & Chặn Người Dùng'), findsOneWidget);
      expect(find.text('Lừa đảo / Gian lận thanh toán'), findsOneWidget);
      expect(find.text('Chặn người này'), findsOneWidget);
      expect(find.text('Gửi Báo Cáo Vi Phạm'), findsOneWidget);
    });

    testWidgets('M-NT-01: NotificationCenterScreen renders tabs and notification items', (tester) async {
      mockRepo.stubNotifications = [
        NotificationItemModel(
          id: 1,
          userId: 1,
          category: 'ORDER',
          title: 'Đơn hàng giao thành công',
          body: 'Đơn hàng #IZI-1234 đã được giao đến bạn. Hãy kiểm tra đồ nhé!',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];
      mockRepo.stubUnreadCount = 1;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Thông Báo'), findsOneWidget);
      expect(find.text('TẤT CẢ'), findsOneWidget);
      expect(find.text('ĐƠN HÀNG'), findsOneWidget);
      expect(find.text('ĐẤU GIÁ'), findsOneWidget);
      expect(find.text('Đơn hàng giao thành công'), findsOneWidget);
      expect(find.text('Đọc tất cả'), findsOneWidget);
    });

    testWidgets('M-RV-01: SubmitVerifiedReviewScreen renders 5 stars and verified pledge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: SubmitVerifiedReviewScreen(orderId: 77, orderCode: 'IZI-77'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Đánh Giá Đơn Hàng'), findsOneWidget);
      expect(find.text('Đơn Hàng: #IZI-77'), findsOneWidget);
      expect(find.text('Tuyệt vời, đúng chất vintage!'), findsOneWidget); // Default 5 stars
      expect(find.text('Đánh giá của bạn sẽ được gắn huy hiệu Đã mua hàng xác thực để tăng độ tin cậy cho cộng đồng izithrift.'), findsOneWidget);
      expect(find.text('Gửi Đánh Giá Xác Thực'), findsOneWidget);
    });

    testWidgets('M-RV-02: SellerReviewsListScreen renders aggregated ratings and breakdown', (tester) async {
      mockRepo.stubSellerReviews = SellerReviewsSummaryModel(
        sellerId: 99,
        shopName: 'Tiệm Vintage Đà Lạt',
        averageRating: 4.9,
        totalReviews: 40,
        starDistribution: const {5: 36, 4: 4, 3: 0, 2: 0, 1: 0},
        reviews: [
          ReviewItemModel(
            id: 1,
            rating: 5,
            comment: 'Món đồ tuyệt đẹp, thơm phức mùi vintage!',
            reviewerName: 'Minh Trí',
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: SellerReviewsListScreen(sellerId: 99),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Đánh Giá Tiệm'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('40 đánh giá'), findsOneWidget);
      expect(find.text('Món đồ tuyệt đẹp, thơm phức mùi vintage!'), findsOneWidget);
      expect(find.text('Minh Trí'), findsOneWidget);
      expect(find.text('Đã mua hàng'), findsOneWidget);
    });

    testWidgets('M-PF-05: SavedFavoritesAndShopsScreen renders favorites & shop tabs', (tester) async {
      mockRepo.stubFavorites = [
        const ProductSummaryModel(
          id: 10,
          productCode: 'PRD-10',
          title: 'Áo khoác dù vintage 90s',
          slug: 'ao-khoac-du-vintage-90s',
          listingType: 'FIXED_PRICE',
          condition: 'LIKE_NEW',
          price: 320000,
          status: 'APPROVED',
          isFavorited: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: SavedFavoritesAndShopsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Đồ Lưu & Tiệm Quen'), findsOneWidget);
      expect(find.text('Đồ Yêu Thích (1)'), findsOneWidget);
      expect(find.text('Tiệm Theo Dõi (0)'), findsOneWidget);
      expect(find.text('Áo khoác dù vintage 90s'), findsOneWidget);
    });
  });
}
