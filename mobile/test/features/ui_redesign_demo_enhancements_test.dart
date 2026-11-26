import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izithrift/core/constants/api_endpoints.dart';
import 'package:izithrift/core/demo/retro_demo_marketplace_store.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/router/app_routes.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/core/theme/seasonal_decor_provider.dart';
import 'package:izithrift/core/utils/product_image_resolver.dart';
import 'package:izithrift/features/auth/models/user_model.dart';
import 'package:izithrift/features/auth/repositories/auth_repository.dart';
import 'package:izithrift/features/auth/viewmodels/auth_view_model.dart';
import 'package:izithrift/features/auth/widgets/auth_login_bottom_sheet.dart';
import 'package:izithrift/features/catalog/repositories/home_catalog_repository.dart';
import 'package:izithrift/features/engagement/models/conversation_model.dart';
import 'package:izithrift/features/engagement/models/message_model.dart';
import 'package:izithrift/features/engagement/repositories/communication_engagement_repository.dart';
import 'package:izithrift/features/engagement/screens/chat_room_screen.dart';
import 'package:izithrift/features/engagement/viewmodels/chat_view_model.dart';
import 'package:izithrift/features/home/models/home_feed_model.dart';
import 'package:izithrift/features/home/screens/home_screen.dart';
import 'package:izithrift/features/profile/repositories/profile_repository.dart';

class _OfflineAuthRepository extends AuthRepository {
  int loginCallCount = 0;

  _OfflineAuthRepository(SecureTokenStorage storage)
      : super(
          dioClient: DioClient(
            tokenStorage: storage,
            serverTimeService: ServerTimeService.instance,
          ),
          tokenStorage: storage,
        );

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    loginCallCount++;
    throw Exception('Backend offline in test');
  }
}

class _StubAuthDioClient extends DioClient {
  final List<String> postedPaths = [];
  final List<dynamic> postedPayloads = [];
  final Map<String, dynamic> Function(String path, dynamic data) responder;

  _StubAuthDioClient({
    required super.tokenStorage,
    required this.responder,
  }) : super(serverTimeService: ServerTimeService.instance);

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    postedPaths.add(path);
    postedPayloads.add(data);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responder(path, data) as T,
    );
  }
}

class _OfflineProfileRepository extends ProfileRepository {
  _OfflineProfileRepository(SecureTokenStorage storage)
      : super(
          dioClient: DioClient(
            tokenStorage: storage,
            serverTimeService: ServerTimeService.instance,
          ),
        );
}

class _StubHomeRepo extends HomeCatalogRepository {
  _StubHomeRepo()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  @override
  Future<HomeFeedModel> fetchHomeFeed() async {
    return const HomeFeedModel();
  }
}

class _StubChatRepo extends CommunicationEngagementRepository {
  _StubChatRepo()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  @override
  Future<PaginatedResponse<ConversationModel>> fetchConversations({
    int page = 1,
    int perPage = 15,
    int? currentUserId,
  }) async {
    return const PaginatedResponse<ConversationModel>(
      items: [
        ConversationModel(
          id: 101,
          partnerId: 201,
          partnerName: 'Tiệm Cổ Điển Sài Gòn',
        ),
      ],
      meta: PaginationMeta(
        currentPage: 1,
        perPage: 15,
        total: 1,
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
    return {
      'conversation': const ConversationModel(
        id: 101,
        partnerId: 201,
        partnerName: 'Tiệm Cổ Điển Sài Gòn',
      ),
      'messages': <MessageModel>[
        MessageModel(
          id: 1,
          conversationId: 101,
          senderId: 201,
          senderName: 'Tiệm Cổ Điển Sài Gòn',
          content: 'Chào bạn, bạn cần xem thêm thông tin món đồ nào ạ?',
          isMine: false,
          createdAt: DateTime.now(),
        ),
      ],
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI-2 Demo Catalog, Nearby Shops & Auction Store Verification', () {
    test('RetroDemoMarketplaceStore provides >= 44 unique demo products and 8 nearby shops', () {
      final store = RetroDemoMarketplaceStore();
      final products = store.demoCatalogProducts;

      expect(products.length, greaterThanOrEqualTo(44));
      final uniqueIds = products.map((p) => p.id).toSet();
      expect(uniqueIds.length, equals(products.length));

      // Verify newly added demo products resolve cleanly for ProductDetailScreen
      final sampleDetail = store.getDemoProductDetail(8144);
      expect(sampleDetail, isNotNull);
      expect(sampleDetail!.id, equals(8144));

      // Verify 8 nearby thrift shops resolve storefronts cleanly
      expect(RetroDemoMarketplaceStore.demoNearbyShops.length, equals(8));
      for (final shop in RetroDemoMarketplaceStore.demoNearbyShops) {
        final storefront = store.getDemoSellerStorefront(shop.sellerId);
        expect(storefront, isNotNull);
        expect(storefront!.displayName, equals(shop.shopName));
        expect(storefront.shopSlug, equals(shop.shopSlug));
      }
    });

    test('RetroDemoMarketplaceStore populates Ongoing, Ending Soon, Upcoming, and Completed auctions', () {
      final store = RetroDemoMarketplaceStore();

      final live = store.demoAuctionCardsForTab('live');
      final endingSoon = store.demoAuctionCardsForTab('ending_soon');
      final upcoming = store.demoAuctionCardsForTab('upcoming');
      final completed = store.demoAuctionCardsForTab('completed');
      final all = store.demoAuctionCardsForTab('all');

      expect(live.length, greaterThanOrEqualTo(4));
      expect(endingSoon.length, greaterThanOrEqualTo(3));
      expect(upcoming.length, greaterThanOrEqualTo(4));
      expect(completed.length, greaterThanOrEqualTo(1));
      expect(all.length, greaterThanOrEqualTo(12));
    });

    test('ProductImageResolver.conditionFreshnessLabel formats Vietnamese freshness cleanly', () {
      expect(
        ProductImageResolver.conditionFreshnessLabel('LIKE_NEW'),
        equals('Độ mới: 95%'),
      );
      expect(
        ProductImageResolver.conditionFreshnessLabel('NEW_WITH_TAGS'),
        equals('Độ mới: 100%'),
      );
      expect(
        ProductImageResolver.conditionFreshnessLabel('GOOD'),
        equals('Độ mới: 85%'),
      );
    });
  });

  group('UI-2 Real API Auth, Redirect State & Chat Order Attachment', () {
    test('AuthViewModel delegates login directly to AuthRepository without local demo bypass', () async {
      final storage = SecureTokenStorage.inMemory();
      final offlineRepo = _OfflineAuthRepository(storage);
      final authVm = AuthViewModel(
        authRepository: offlineRepo,
        profileRepository: _OfflineProfileRepository(storage),
        tokenStorage: storage,
        seasonalDecorNotifier: SeasonalDecorNotifier(null, true),
      );
      addTearDown(authVm.dispose);
      expect(authVm.isAuthenticated, isFalse);

      await authVm.login(email: 'buyer@retromarket.vn', password: 'password123');

      expect(offlineRepo.loginCallCount, equals(1));
      expect(authVm.isAuthenticated, isFalse);
      expect(authVm.currentUser, isNull);
      expect(authVm.state.isError, isTrue);
      expect(await storage.hasToken(), isFalse);
    });

    test('AuthRepository login and register call real API endpoints and persist Sanctum token', () async {
      final storage = SecureTokenStorage.inMemory();
      final dioClient = _StubAuthDioClient(
        tokenStorage: storage,
        responder: (path, data) {
          if (path == ApiEndpoints.login) {
            return {
              'success': true,
              'message': 'Đăng nhập thành công.',
              'data': {
                'token': '1|real_sanctum_login_token',
                'user': {
                  'id': 42,
                  'display_name': 'Minh Anh',
                  'email': 'minhanh@retromarket.vn',
                  'role': 'REGISTERED_USER',
                  'status': 'ACTIVE',
                },
              },
            };
          }
          return {
            'success': true,
            'message': 'Đăng ký tài khoản thành công.',
            'data': {
              'token': '2|real_sanctum_register_token',
              'user': {
                'id': 43,
                'display_name': 'Tiệm Đồ Cũ',
                'email': 'shopmoi@retromarket.vn',
                'role': 'REGISTERED_USER',
                'status': 'ACTIVE',
              },
            },
          };
        },
      );

      final repo = AuthRepository(dioClient: dioClient, tokenStorage: storage);

      final loggedInUser = await repo.login(
        email: 'minhanh@retromarket.vn',
        password: 'Password123!',
      );
      expect(dioClient.postedPaths.first, equals(ApiEndpoints.login));
      expect(loggedInUser.id, equals(42));
      expect(await storage.getAccessToken(), equals('1|real_sanctum_login_token'));
      expect(await storage.getUserEmail(), equals('minhanh@retromarket.vn'));

      final registeredUser = await repo.register(
        displayName: 'Tiệm Đồ Cũ',
        email: 'shopmoi@retromarket.vn',
        password: 'Password123!',
        passwordConfirmation: 'Password123!',
      );
      expect(dioClient.postedPaths.last, equals(ApiEndpoints.register));
      expect(registeredUser.id, equals(43));
      expect(await storage.getAccessToken(), equals('2|real_sanctum_register_token'));
      expect(await storage.getUserEmail(), equals('shopmoi@retromarket.vn'));
    });

    test('pendingAuthRedirectProvider preserves and clears intended navigation targets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(pendingAuthRedirectProvider), isNull);

      const target = PendingNavigationTarget(
        route: AppRoutes.cart,
        useGo: false,
      );
      container.read(pendingAuthRedirectProvider.notifier).state = target;
      expect(container.read(pendingAuthRedirectProvider)?.route, AppRoutes.cart);

      container.read(pendingAuthRedirectProvider.notifier).state = null;
      expect(container.read(pendingAuthRedirectProvider), isNull);
    });

    test('ChatViewModel.sendOrderAttachment appends structured interactive Order Card bubble', () async {
      final store = RetroDemoMarketplaceStore();
      final repo = _StubChatRepo();
      final vm = ChatViewModel(
        repository: repo,
        currentUserId: 999,
        enablePolling: false,
        enableDemoFallback: true,
      );
      addTearDown(vm.dispose);

      await vm.loadInbox();
      await vm.enterChatRoom(101);
      final beforeCount = vm.messages.length;

      final sampleOrder = store.demoBuyerOrders.first;
      final sent = await vm.sendOrderAttachment(order: sampleOrder);

      expect(sent, isTrue);
      expect(vm.messages.length, equals(beforeCount + 1));
      final lastMsg = vm.messages.last;
      expect(lastMsg.isOrder, isTrue);
      expect(lastMsg.attachedOrder, isNotNull);
      expect(lastMsg.attachedOrder!.orderCode, equals(sampleOrder.orderCode));
    });
  });

  group('UI-2 Widget Verification: Bottom Sheet, Home Redesign & Chat Sheet', () {
    testWidgets('AuthLoginBottomSheet renders back button, close button, and dismisses freely', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showAuthLoginBottomSheet(
                    ctx,
                    featureTitle: 'Đăng nhập để mở Giỏ hàng',
                    description: 'Tiếp tục xem các món đồ bạn đã chọn.',
                  ),
                  child: const Text('Mở sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Yêu cầu đăng nhập'), findsOneWidget);
      expect(find.text('Đăng nhập để mở Giỏ hàng'), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);
      expect(find.text('Để sau'), findsOneWidget);
      expect(find.byTooltip('Quay lại'), findsOneWidget);
      expect(find.textContaining('Demo:'), findsNothing);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập để mở Giỏ hàng'), findsNothing);
    });

    testWidgets('HomeScreen displays contained categories, nearby thrift shops, and paginated discovery feed', (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeCatalogRepositoryProvider.overrideWithValue(_StubHomeRepo()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Danh mục đồ si'), findsOneWidget);
      expect(find.text('American Tee'), findsOneWidget);
      expect(find.text('Khác'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Tiệm đồ si ở gần bạn'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tiệm đồ si ở gần bạn'), findsOneWidget);
      expect(find.text('Ghé tiệm →'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Bạn có thể đang tìm kiếm'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Bạn có thể đang tìm kiếm'), findsOneWidget);
      expect(find.textContaining('Độ mới:'), findsWidgets);

      await tester.scrollUntilVisible(
        find.textContaining('Xem thêm sản phẩm'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Xem thêm sản phẩm'), findsOneWidget);
    });

    testWidgets('ChatRoomScreen attachment sheet removes quick demo options and shows Gallery, Camera, and Orders', (tester) async {
      final repo = _StubChatRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationEngagementRepositoryProvider.overrideWithValue(repo),
            chatViewModelProvider.overrideWith(
              (ref) => ChatViewModel(
                repository: repo,
                currentUserId: 999,
                enablePolling: false,
                enableDemoFallback: true,
              ),
            ),
          ],
          child: const MaterialApp(
            home: ChatRoomScreen(conversationId: 101),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      await tester.tap(find.byTooltip('Đính kèm ảnh, video hoặc đơn hàng'));
      await tester.pumpAndSettle();

      expect(find.text('Tùy chọn nhanh (Chế độ Demo)'), findsNothing);
      expect(find.text('Ảnh cận chất vải'), findsNothing);
      expect(find.text('Thư viện'), findsOneWidget);
      expect(find.text('Máy ảnh'), findsOneWidget);
      expect(find.text('Đơn hàng'), findsOneWidget);
    });
  });
}
