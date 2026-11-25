import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/error/api_exception.dart';
import 'package:izithrift/core/error/error_code_enum.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/features/auctions/models/auction_bid_item_model.dart';
import 'package:izithrift/features/auctions/models/auction_card_model.dart';
import 'package:izithrift/features/auctions/models/auction_detail_model.dart';
import 'package:izithrift/features/auctions/models/outbid_conflict_state_model.dart';
import 'package:izithrift/features/auctions/repositories/auction_repository.dart';
import 'package:izithrift/features/auctions/screens/bid_placement_bottom_sheet.dart';
import 'package:izithrift/features/auctions/screens/live_bidding_room_screen.dart';
import 'package:izithrift/features/auctions/screens/my_auctions_screen.dart';
import 'package:izithrift/features/auctions/screens/scheduled_auction_hub_screen.dart';
import 'package:izithrift/features/auctions/screens/seller_close_early_modal.dart';
import 'package:izithrift/features/auctions/screens/seller_relist_auction_modal.dart';
import 'package:izithrift/features/auctions/viewmodels/auction_hub_view_model.dart';
import 'package:izithrift/features/auctions/viewmodels/live_auction_view_model.dart';
import 'package:izithrift/features/auctions/viewmodels/my_auctions_view_model.dart';
import 'package:izithrift/features/seller/models/seller_product_form_payload.dart';

/// Mock Implementation of AuctionRepository for Unit and Widget testing
class MockAuctionRepository extends AuctionRepository {
  MockAuctionRepository()
    : super(
        dioClient: DioClient(
          tokenStorage: SecureTokenStorage(),
          serverTimeService: ServerTimeService.instance,
        ),
      );

  List<AuctionCardModel> stubHubAuctions = [];
  List<AuctionCardModel> stubMyAuctions = [];
  AuctionDetailModel? stubAuctionDetail;
  List<AuctionBidItemModel> stubBids = [];

  bool placeBidShouldThrowConflict409 = false;
  Map<String, dynamic>? conflictLatestState;
  bool toggleWatchCalled = false;
  bool closeEarlyCalled = false;
  bool relistCalled = false;

  @override
  Future<PaginatedResponse<AuctionCardModel>> fetchHubAuctions({
    String tab = 'live',
    int page = 1,
    int perPage = 12,
    int? currentUserId,
  }) async {
    return PaginatedResponse<AuctionCardModel>(
      items: stubHubAuctions,
      meta: PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: stubHubAuctions.length,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<PaginatedResponse<AuctionCardModel>> fetchMyAuctions({
    String tab = 'participating',
    int page = 1,
    int perPage = 12,
    int? currentUserId,
  }) async {
    return PaginatedResponse<AuctionCardModel>(
      items: stubMyAuctions,
      meta: PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: stubMyAuctions.length,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<AuctionDetailModel> fetchAuctionDetail(
    int auctionId, {
    int? currentUserId,
  }) async {
    return stubAuctionDetail ??
        AuctionDetailModel(
          id: auctionId,
          auctionCode: 'AUC-20261115-$auctionId',
          productId: 10,
          sellerId: 2,
          startingPrice: 100000.0,
          minBidIncrement: 20000.0,
          minimumNextBid: 120000.0,
          currentHighestBid: 100000.0,
          bidCount: 3,
          watchCount: 5,
          status: 'LIVE',
          auctionEndsAt: DateTime.now().add(const Duration(hours: 2)),
          extendedCount: 0,
          productTitle: 'Đồng hồ cơ Poljot Liên Xô 1980s',
          productDescription:
              'Máy lên dây cót tay nguyên bản, hoạt động mượt mà.',
          primaryImageUrl: 'https://example.com/poljot.jpg',
          sellerDisplayName: 'Tiệm Đồ Xưa Hà Nội',
          sellerTrustScore: 98.0,
          leadingBidderId: 1,
          leadingBidderName: 'u***1',
          isOwner: false,
          isWatching: false,
          isLeading: true,
          recentBids: stubBids,
        );
  }

  @override
  Future<PaginatedResponse<AuctionBidItemModel>> fetchAuctionBids(
    int auctionId, {
    int page = 1,
    int perPage = 20,
    int? currentUserId,
  }) async {
    return PaginatedResponse<AuctionBidItemModel>(
      items: stubBids,
      meta: PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: stubBids.length,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> placeBid(
    int auctionId,
    double bidAmount, {
    int? currentUserId,
  }) async {
    if (placeBidShouldThrowConflict409) {
      throw ApiException(
        statusCode: 409,
        errorCode: 'AUCTION_OUTBID_CONFLICT',
        errorCodeEnum: ErrorCodeEnum.auctionOutbidConflict,
        message: 'Mức giá đặt đã bị người mua khác vượt qua. Vui lòng cập nhật giá mới.',
        latestState:
            conflictLatestState ??
            {
              'auction_id': auctionId,
              'current_highest_bid': (bidAmount + 10000.0).toStringAsFixed(2),
              'minimum_next_bid': (bidAmount + 30000.0).toStringAsFixed(2),
              'leading_bidder_id': 99,
              'bid_count': 5,
              'auction_ends_at': DateTime.now()
                  .add(const Duration(minutes: 10))
                  .toIso8601String(),
              'extended_count': 1,
            },
      );
    }

    final newBid = AuctionBidItemModel(
      id: 999,
      auctionId: auctionId,
      bidderId: currentUserId ?? 1,
      bidAmount: bidAmount,
      previousHighestBid: 100000.0,
      triggeredAntiSniping: true,
      createdAt: DateTime.now(),
      bidderName: 'Tôi',
      isMine: true,
      isLeading: true,
    );

    final updatedAuction =
        (stubAuctionDetail ??
                await fetchAuctionDetail(
                  auctionId,
                  currentUserId: currentUserId,
                ))
            .copyWith(
              currentHighestBid: bidAmount,
              minimumNextBid: bidAmount + 20000.0,
              bidCount: 4,
              extendedCount: 1,
              isLeading: true,
              isOutbid: false,
              recentBids: [newBid, ...stubBids],
            );

    stubAuctionDetail = updatedAuction;

    return {
      'auction': updatedAuction,
      'bid': newBid,
      'triggered_anti_sniping': true,
    };
  }

  @override
  Future<bool> toggleWatch(int auctionId) async {
    toggleWatchCalled = true;
    return true;
  }

  @override
  Future<AuctionDetailModel> closeEarly(
    int auctionId, {
    int? currentUserId,
  }) async {
    closeEarlyCalled = true;
    final updated =
        (stubAuctionDetail ??
                await fetchAuctionDetail(
                  auctionId,
                  currentUserId: currentUserId,
                ))
            .copyWith(status: 'ENDED_SOLD');
    stubAuctionDetail = updated;
    return updated;
  }

  @override
  Future<AuctionDetailModel> relistAuction(
    int productId, {
    required double startingPrice,
    required double minBidIncrement,
    required DateTime auctionStartsAt,
    required DateTime auctionEndsAt,
    double? reservePrice,
    int? currentUserId,
  }) async {
    relistCalled = true;
    return AuctionDetailModel(
      id: 888,
      auctionCode: 'AUC-RELIST-888',
      productId: productId,
      sellerId: currentUserId ?? 2,
      startingPrice: startingPrice,
      minBidIncrement: minBidIncrement,
      minimumNextBid: startingPrice + minBidIncrement,
      currentHighestBid: startingPrice,
      bidCount: 0,
      watchCount: 0,
      status: 'LIVE',
      auctionStartsAt: auctionStartsAt,
      auctionEndsAt: auctionEndsAt,
      productTitle: 'Sản phẩm tái đăng',
      sellerDisplayName: 'Chủ tiệm',
      isOwner: true,
    );
  }
}

AuctionCardModel _createDummyCard({
  required int id,
  required String status,
  required double currentBid,
  String title = 'Sản phẩm đấu giá retro test',
  bool isWatching = false,
  String? myBidStatus,
  double? myHighestBid,
}) {
  return AuctionCardModel(
    id: id,
    auctionCode: 'AUC-TEST-$id',
    productId: id * 10,
    sellerId: 2,
    startingPrice: 50000.0,
    minBidIncrement: 10000.0,
    currentHighestBid: currentBid,
    bidCount: 5,
    watchCount: 12,
    status: status,
    auctionEndsAt: DateTime.now().add(const Duration(hours: 1)),
    extendedCount: 0,
    productTitle: title,
    primaryImageUrl: 'https://example.com/item$id.jpg',
    sellerDisplayName: 'Tiệm Vintage Test',
    sellerTrustScore: 99.0,
    myHighestBid: myHighestBid,
    myBidStatus: myBidStatus,
    isWatching: isWatching,
    isOwner: false,
  );
}

void main() {
  late MockAuctionRepository mockRepo;

  setUp(() {
    mockRepo = MockAuctionRepository();
  });

  Widget createTestWidget(
    Widget child, {
    Key? scopeKey,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      key: scopeKey,
      overrides: [
        auctionRepositoryProvider.overrideWithValue(mockRepo),
        ...overrides,
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('P7-10 Task Verification: Scheduled Auctions & Live Room', () {
    // -------------------------------------------------------------
    // TEST 1: Model Serialization & OutbidConflictStateModel
    // -------------------------------------------------------------
    test('1. Auction models parse JSON correctly and calculate getters', () {
      final cardJson = {
        'id': 101,
        'auction_code': 'AUC-101',
        'product_id': 50,
        'seller_id': 2,
        'starting_price': 150000.0,
        'min_bid_increment': 15000.0,
        'current_highest_bid': 180000.0,
        'bid_count': 2,
        'watch_count': 10,
        'status': 'LIVE',
        'auction_ends_at': '2026-11-15T15:00:00Z',
        'extended_count': 1,
        'product': {
          'id': 50,
          'title': 'Máy hát đĩa than Victor 1970',
          'primary_image_url': 'https://example.com/record.jpg',
          'condition': 'EXCELLENT',
        },
        'seller': {
          'id': 2,
          'display_name': 'Tiệm Retro Sài Gòn',
          'trust_score': 95.0,
        },
        'my_bid_status': 'OUTBID',
        'my_highest_bid': 165000.0,
        'is_watching': true,
      };

      final card = AuctionCardModel.fromJson(cardJson, currentUserId: 1);
      expect(card.id, 101);
      expect(card.productTitle, 'Máy hát đĩa than Victor 1970');
      expect(card.currentHighestBid, 180000.0);
      expect(card.isOutbid, isTrue);
      expect(card.isLive, isTrue);
      expect(card.isWatching, isTrue);

      // OutbidConflictStateModel
      final conflictJson = {
        'auction_id': 101,
        'current_highest_bid': '200000.00',
        'minimum_next_bid': '215000.00',
        'leading_bidder_id': 88,
        'bid_count': 3,
        'auction_ends_at': '2026-11-15T15:02:00Z',
        'extended_count': 2,
      };
      final conflict = OutbidConflictStateModel.fromJson(conflictJson);
      expect(conflict.auctionId, 101);
      expect(conflict.currentHighestBid, 200000.0);
      expect(conflict.minimumNextBid, 215000.0);
      expect(conflict.extendedCount, 2);
    });

    // -------------------------------------------------------------
    // TEST 2: AuctionHubViewModel tab switching & optimistic watch
    // -------------------------------------------------------------
    test(
      '2. AuctionHubViewModel manages 4 tabs and optimistic watch toggle',
      () async {
        mockRepo.stubHubAuctions = [
          _createDummyCard(id: 1, status: 'LIVE', currentBid: 100000.0),
          _createDummyCard(id: 2, status: 'LIVE', currentBid: 200000.0),
        ];

        final vm = AuctionHubViewModel(repository: mockRepo);
        expect(vm.currentTab, 'live');

        await vm.fetchInitial();
        expect(vm.items.length, 2);

        // Toggle watch optimistically
        await vm.toggleWatch(1);
        expect(vm.items.first.isWatching, isTrue);
        expect(mockRepo.toggleWatchCalled, isTrue);

        // Switch to ending_soon tab
        await vm.switchTab('ending_soon');
        expect(vm.currentTab, 'ending_soon');
      },
    );

    // -------------------------------------------------------------
    // TEST 3: MyAuctionsViewModel leading/outbid categorization
    // -------------------------------------------------------------
    test(
      '3. MyAuctionsViewModel calculates leadingCount and outbidCount',
      () async {
        mockRepo.stubMyAuctions = [
          _createDummyCard(
            id: 1,
            status: 'LIVE',
            currentBid: 120000.0,
            myBidStatus: 'LEADING',
          ),
          _createDummyCard(
            id: 2,
            status: 'LIVE',
            currentBid: 250000.0,
            myBidStatus: 'OUTBID',
          ),
          _createDummyCard(
            id: 3,
            status: 'LIVE',
            currentBid: 300000.0,
            myBidStatus: 'OUTBID',
          ),
        ];

        final vm = MyAuctionsViewModel(repository: mockRepo);
        await vm.fetchInitial();

        expect(vm.items.length, 3);
        expect(vm.leadingCount, 1);
        expect(vm.outbidCount, 2);
      },
    );

    // -------------------------------------------------------------
    // TEST 4: LiveAuctionViewModel Anti-Sniping & 409 Conflict Handling
    // -------------------------------------------------------------
    test('4. LiveAuctionViewModel detects Anti-Sniping and handles 409 Outbid Conflict retention', () async {
      final initialDetail = AuctionDetailModel(
        id: 500,
        auctionCode: 'AUC-500',
        productId: 10,
        sellerId: 9,
        startingPrice: 100000.0,
        minBidIncrement: 20000.0,
        minimumNextBid: 120000.0,
        currentHighestBid: 100000.0,
        bidCount: 2,
        watchCount: 4,
        status: 'LIVE',
        auctionEndsAt: DateTime.now().add(const Duration(minutes: 5)),
        extendedCount: 0,
        productTitle: 'Đèn dầu Pháp cổ điển',
      );
      mockRepo.stubAuctionDetail = initialDetail;

      final vm = LiveAuctionViewModel(
        auctionId: 500,
        repository: mockRepo,
        enablePolling: false,
      );

      await vm.loadAuction();
      expect(vm.auction?.currentHighestBid, 100000.0);
      expect(vm.justTriggeredAntiSniping, isFalse);

      // Successful bid placement triggering Anti-Sniping
      final bidOk = await vm.placeBid(120000.0);
      expect(bidOk, isTrue);
      expect(vm.auction?.currentHighestBid, 120000.0);
      expect(vm.justTriggeredAntiSniping, isTrue);

      // Now simulate 409 Conflict when someone outbids simultaneously
      mockRepo.placeBidShouldThrowConflict409 = true;
      final conflictOk = await vm.placeBid(140000.0);

      expect(conflictOk, isFalse);
      expect(vm.outbidConflict, isNotNull);
      expect(vm.outbidConflict?.currentHighestBid, 150000.0);
      expect(vm.outbidConflict?.minimumNextBid, 170000.0);
      expect(vm.auction?.minimumNextBid, 170000.0); // Retained & updated
    });

    // -------------------------------------------------------------
    // TEST 5: Widget Test M-AC-01 Scheduled Auction Hub Screen
    // -------------------------------------------------------------
    testWidgets(
      '5. ScheduledAuctionHubScreen renders 4 tabs, cards and triggers watch',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        mockRepo.stubHubAuctions = [
          _createDummyCard(
            id: 11,
            status: 'LIVE',
            currentBid: 300000.0,
            title: 'Bàn ủi con gà cổ',
          ),
          _createDummyCard(
            id: 12,
            status: 'LIVE',
            currentBid: 450000.0,
            title: 'Quạt tai voi Liên Xô',
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(const ScheduledAuctionHubScreen()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('izithrift'), findsOneWidget);
        expect(find.text('Đấu giá'), findsOneWidget);
        expect(
          find.text('Săn món đồ độc đáo với mức giá của bạn.'),
          findsOneWidget,
        );
        expect(find.text('🔴 Đang diễn ra'), findsOneWidget);
        expect(find.text('⚡ Sắp kết thúc'), findsOneWidget);
        expect(find.text('⏰ Sắp mở'), findsOneWidget);
        expect(find.text('📦 Đã kết thúc'), findsOneWidget);
        expect(find.text('Bàn ủi con gà cổ'), findsOneWidget);
        expect(find.text('Quạt tai voi Liên Xô'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------
    // TEST 6: Widget Test M-AC-02 My Auctions Screen (Leading & Won 30-min Deadline)
    // -------------------------------------------------------------
    testWidgets(
      '6. MyAuctionsScreen shows leading badge, outbid CTA, and Won payment 30-min countdown',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        mockRepo.stubMyAuctions = [
          _createDummyCard(
            id: 21,
            status: 'LIVE',
            currentBid: 500000.0,
            title: 'Đài Cassette Sony Walkman WM-2',
            myBidStatus: 'OUTBID',
          ),
        ];

        await tester.pumpWidget(createTestWidget(const MyAuctionsScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Đấu Giá Của Tôi'), findsOneWidget);
        expect(find.text('⚠️ ĐÃ BỊ VƯỢT GIÁ'), findsOneWidget);
        expect(find.text('Trả giá lại ngay'), findsOneWidget);

        // Now switch to Won tab
        mockRepo.stubMyAuctions = [
          _createDummyCard(
            id: 22,
            status: 'ENDED_SOLD',
            currentBid: 850000.0,
            title: 'Bật lửa Dupont mạ vàng cổ điển',
          ),
        ];

        await tester.tap(find.text('🏆 Đã thắng đấu giá'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('🏆 BẠN ĐÃ CHIẾN THẮNG PHIÊN ĐẤU GIÁ!'),
          findsOneWidget,
        );
        expect(
          find.text('Thời hạn thanh toán (30 phút - BR-AU-07):'),
          findsOneWidget,
        );
        expect(find.text('Thanh toán đơn hàng ngay 💳'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------
    // TEST 7: Widget Test M-AC-03 Live Bidding Room & Anti-Sniping Alert
    // -------------------------------------------------------------
    testWidgets(
      '7. LiveBiddingRoomScreen displays server countdown, anti-sniping alert, and owner restrictions',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final detail = AuctionDetailModel(
          id: 700,
          auctionCode: 'AUC-700',
          productId: 10,
          sellerId: 1, // viewing as owner
          startingPrice: 200000.0,
          minBidIncrement: 20000.0,
          minimumNextBid: 240000.0,
          currentHighestBid: 220000.0,
          bidCount: 4,
          watchCount: 8,
          status: 'LIVE',
          auctionEndsAt: DateTime.now().add(const Duration(minutes: 3)),
          extendedCount: 1, // Anti-sniping active
          productTitle: 'Đồng hồ Odo 36/8 cổ Pháp',
          sellerDisplayName: 'Tiệm Đồ Xưa',
          isOwner: true, // Owner rule BR-AC-02
          recentBids: [
            AuctionBidItemModel(
              id: 1,
              auctionId: 700,
              bidderId: 88,
              bidAmount: 220000.0,
              triggeredAntiSniping: true,
              createdAt: DateTime.now(),
              bidderName: 'u***88',
              isLeading: true,
            ),
          ],
        );
        mockRepo.stubAuctionDetail = detail;

        await tester.pumpWidget(
          createTestWidget(const LiveBiddingRoomScreen(auctionId: 700)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Đồng hồ Odo 36/8 cổ Pháp'), findsWidgets);
        // Anti-sniping badge
        expect(
          find.text('⚡ Đã kích hoạt Anti-Sniping (+2 phút) • Gia hạn lần #1'),
          findsOneWidget,
        );
        // Owner CTA: cannot bid (BR-AC-02), can close early (M-AC-05)
        expect(find.text('Chốt phiên sớm (M-AC-05)'), findsOneWidget);
        expect(find.text('👑 Dẫn đầu'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------
    // TEST 8: Widget Test M-AC-04 Bid Placement Bottom Sheet with 409 Conflict Retention
    // -------------------------------------------------------------
    testWidgets(
      '8. BidPlacementBottomSheet renders quick chips and adapts seamlessly on 409 Conflict',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final detail = AuctionDetailModel(
          id: 900,
          auctionCode: 'AUC-900',
          productId: 10,
          sellerId: 9,
          startingPrice: 100000.0,
          minBidIncrement: 20000.0,
          minimumNextBid: 120000.0,
          currentHighestBid: 100000.0,
          bidCount: 1,
          watchCount: 5,
          status: 'LIVE',
          auctionEndsAt: DateTime.now().add(const Duration(hours: 1)),
          productTitle: 'Radio cassette Sharp GF-777',
        );
        mockRepo.stubAuctionDetail = detail;
        mockRepo.placeBidShouldThrowConflict409 = true;

        await tester.pumpWidget(
          createTestWidget(const BidPlacementBottomSheet(auctionId: 900)),
        );
        await tester.pumpAndSettle();

        expect(find.text('🔨 Đặt Giá Thầu'), findsOneWidget);
        expect(find.text('Tối thiểu'), findsOneWidget);
        expect(find.text('+1 bước'), findsOneWidget);

        // Tap confirm bid -> triggers 409 conflict
        await tester.tap(find.textContaining('Xác nhận đặt giá'));
        await tester.pumpAndSettle();

        // Sheet is NOT closed! It retains state and displays 409 conflict banner
        expect(
          find.text('Mức giá vừa bị người khác vượt qua!'),
          findsOneWidget,
        );
      },
    );

    // -------------------------------------------------------------
    // TEST 9: Widget Test M-AC-05 Seller Close Early Modal
    // -------------------------------------------------------------
    testWidgets('9. SellerCloseEarlyModal confirms early closure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final detail = AuctionDetailModel(
        id: 950,
        auctionCode: 'AUC-950',
        productId: 10,
        sellerId: 2,
        startingPrice: 100000.0,
        minBidIncrement: 20000.0,
        minimumNextBid: 160000.0,
        currentHighestBid: 140000.0,
        bidCount: 3,
        watchCount: 2,
        status: 'LIVE',
        auctionEndsAt: DateTime.now().add(const Duration(hours: 1)),
        productTitle: 'Bình hoa gốm Biên Hòa',
        leadingBidderName: 'u***99',
        isOwner: true,
      );
      mockRepo.stubAuctionDetail = detail;

      await tester.pumpWidget(
        createTestWidget(const SellerCloseEarlyModal(auctionId: 950)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chốt Phiên Đấu Giá Sớm'), findsOneWidget);
      expect(find.text('Xác nhận chốt ngay'), findsOneWidget);
      await tester.tap(find.text('Xác nhận chốt ngay'));
      await tester.pumpAndSettle();
      expect(mockRepo.closeEarlyCalled, isTrue);
    });

    // -------------------------------------------------------------
    // TEST 10: Widget Test M-AC-06 Seller Relist Auction Modal
    // -------------------------------------------------------------
    testWidgets(
      '10. SellerRelistAuctionModal validates and submits relisting',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final detail = AuctionDetailModel(
          id: 951,
          auctionCode: 'AUC-951',
          productId: 10,
          sellerId: 2,
          startingPrice: 100000.0,
          minBidIncrement: 20000.0,
          minimumNextBid: 160000.0,
          currentHighestBid: 140000.0,
          bidCount: 3,
          watchCount: 2,
          status: 'ENDED_UNSOLD',
          auctionEndsAt: DateTime.now().subtract(const Duration(hours: 1)),
          productTitle: 'Bình hoa gốm Biên Hòa',
          isOwner: true,
        );
        mockRepo.stubAuctionDetail = detail;

        await tester.pumpWidget(
          createTestWidget(const SellerRelistAuctionModal(auctionId: 951)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tái Đăng Phiên Đấu Giá'), findsOneWidget);
        final submitBtn = find.text('Xác nhận đăng lại phiên đấu giá');
        expect(submitBtn, findsOneWidget);
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        expect(mockRepo.relistCalled, isTrue);
      },
    );

    // -------------------------------------------------------------
    // TEST 11: AuctionRepository Safe Response Data Extraction
    // -------------------------------------------------------------
    test(
      '11. AuctionRepository extracts data safely from various envelopes',
      () {
        final repo = AuctionRepository(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );
        expect(
          repo.extractDataMap({
            'success': true,
            'data': {'id': 10},
          }),
          equals({'id': 10}),
        );
        expect(repo.extractDataMap({'success': true, 'data': []}), isEmpty);
        expect(repo.extractDataMap({'success': true, 'data': null}), isEmpty);
        expect(repo.extractDataMap('invalid string'), isEmpty);
        expect(repo.extractDataMap(null), isEmpty);
      },
    );

    // -------------------------------------------------------------
    // TEST 12: Seller Auction Duration Selector & Payload Serialization
    // -------------------------------------------------------------
    test(
      '12. Seller auction duration selector presets and payload serialization',
      () {
        final now = DateTime.now();
        final end15m = now.add(const Duration(minutes: 15));
        final payload = SellerProductFormPayload(
          title: 'Đèn bàn vintage Pháp',
          description: 'Đèn bàn đồng nguyên khối',
          categoryId: 1,
          listingType: 'AUCTION',
          price: 500000,
          condition: 'GOOD',
          defectInfo: 'Có vết xước nhẹ chân đế',
          startingPrice: 500000,
          minBidIncrement: 50000,
          auctionStartsAt: now,
          auctionEndsAt: end15m,
        );
        final map = payload.toMap();
        expect(map['listing_type'], equals('AUCTION'));
        expect(map['starting_price'], equals(500000));
        expect(map['min_bid_increment'], equals(50000));
        expect(map['auction_starts_at'], equals(now.toIso8601String()));
        expect(map['auction_ends_at'], equals(end15m.toIso8601String()));
      },
    );

    // -------------------------------------------------------------
    // TEST 13: LiveBiddingRoomScreen Winner CTA Rendering
    // -------------------------------------------------------------
    testWidgets(
      '13. LiveBiddingRoomScreen displays Winner CTA when current user is winner with orderId',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        AuctionDetailModel makeDetail({
          required int id,
          int? winnerId,
          int? orderId,
        }) {
          return AuctionDetailModel(
            id: id,
            auctionCode: 'AUC-WIN-$id',
            productId: 10,
            sellerId: 2,
            startingPrice: 100000.0,
            minBidIncrement: 20000.0,
            minimumNextBid: 220000.0,
            currentHighestBid: 200000.0,
            bidCount: 5,
            watchCount: 3,
            status: 'COMPLETED',
            auctionEndsAt: DateTime.now().subtract(const Duration(minutes: 5)),
            productTitle: 'Máy ảnh Film Canon QL17 GIII',
            winnerId: winnerId,
            orderId: orderId,
            isOwner: false,
          );
        }

        // Subtest A: Current user is winner AND orderId is present
        final winnerDetail = makeDetail(id: 991, winnerId: 1, orderId: 505);
        mockRepo.stubAuctionDetail = winnerDetail;

        await tester.pumpWidget(
          createTestWidget(
            const LiveBiddingRoomScreen(auctionId: 991),
            scopeKey: const ValueKey('subtest-a'),
            overrides: [
              liveAuctionViewModelProvider(991).overrideWith((ref) {
                final vm = LiveAuctionViewModel(
                  auctionId: 991,
                  repository: mockRepo,
                  currentUserId: 1,
                  enablePolling: false,
                );
                vm.loadAuction();
                return vm;
              }),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('🏆 BẠN ĐÃ THẮNG ĐẤU GIÁ!'), findsOneWidget);
        expect(find.text('THANH TOÁN ĐƠN HÀNG NGAY'), findsOneWidget);

        // Subtest B: Current user is NOT winner
        final nonWinnerDetail = makeDetail(id: 992, winnerId: 99, orderId: 505);
        mockRepo.stubAuctionDetail = nonWinnerDetail;
        await tester.pumpWidget(
          createTestWidget(
            const LiveBiddingRoomScreen(auctionId: 992),
            scopeKey: const ValueKey('subtest-b'),
            overrides: [
              liveAuctionViewModelProvider(992).overrideWith((ref) {
                final vm = LiveAuctionViewModel(
                  auctionId: 992,
                  repository: mockRepo,
                  currentUserId: 1,
                  enablePolling: false,
                );
                vm.loadAuction();
                return vm;
              }),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('THANH TOÁN ĐƠN HÀNG NGAY'), findsNothing);
        expect(
          find.text('Phiên đấu giá đã kết thúc (COMPLETED)'),
          findsOneWidget,
        );

        // Subtest C: Current user is winner BUT orderId is null
        final winnerNoOrderDetail = makeDetail(
          id: 993,
          winnerId: 1,
          orderId: null,
        );
        mockRepo.stubAuctionDetail = winnerNoOrderDetail;
        await tester.pumpWidget(
          createTestWidget(
            const LiveBiddingRoomScreen(auctionId: 993),
            scopeKey: const ValueKey('subtest-c'),
            overrides: [
              liveAuctionViewModelProvider(993).overrideWith((ref) {
                final vm = LiveAuctionViewModel(
                  auctionId: 993,
                  repository: mockRepo,
                  currentUserId: 1,
                  enablePolling: false,
                );
                vm.loadAuction();
                return vm;
              }),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('THANH TOÁN ĐƠN HÀNG NGAY'), findsNothing);
        expect(
          find.text('Phiên đấu giá đã kết thúc (COMPLETED)'),
          findsOneWidget,
        );
      },
    );

    test('14. AuctionDetailModel parses my_bid_status WON and shows winner CTA when currentUserId is null', () {
      final parsed = AuctionDetailModel.fromJson({
        'id': 1005,
        'auction_code': 'AUC-DEMO-1005',
        'product_id': 2,
        'seller_id': 99,
        'status': 'ENDED_SOLD',
        'my_bid_status': 'WON',
        'winner': {'id': 11, 'display_name': 'Tiệm Đồ Si Nhà Gấu'},
        'order': {'id': 501},
      });

      expect(parsed.myBidStatus, 'WON');
      expect(parsed.winnerId, 11);
      expect(parsed.orderId, 501);
      expect(parsed.isCompleted, true);
    });

    testWidgets(
      '15. LiveBiddingRoomScreen renders Winner CTA in unauthenticated mode when myBidStatus is WON',
      (tester) async {
        mockRepo.stubAuctionDetail = AuctionDetailModel(
          id: 1005,
          auctionCode: 'AUC-DEMO-1005',
          productId: 2,
          sellerId: 99,
          startingPrice: 400000.0,
          minBidIncrement: 25000.0,
          minimumNextBid: 500000.0,
          currentHighestBid: 475000.0,
          bidCount: 1,
          watchCount: 0,
          status: 'ENDED_SOLD',
          auctionEndsAt: DateTime.now().subtract(const Duration(hours: 1)),
          productTitle: 'Áo Khoác Da Vintage Classic 90s',
          winnerId: 11,
          orderId: 501,
          myBidStatus: 'WON',
        );

        await tester.pumpWidget(
          createTestWidget(
            const LiveBiddingRoomScreen(auctionId: 1005),
            scopeKey: const ValueKey('unauth-winner-won'),
            overrides: [
              liveAuctionViewModelProvider(1005).overrideWith((ref) {
                final vm = LiveAuctionViewModel(
                  auctionId: 1005,
                  repository: mockRepo,
                  currentUserId: null,
                  enablePolling: false,
                );
                vm.loadAuction();
                return vm;
              }),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('🏆 BẠN ĐÃ THẮNG ĐẤU GIÁ!'), findsOneWidget);
        expect(find.text('THANH TOÁN ĐƠN HÀNG NGAY'), findsOneWidget);
      },
    );
  });
}
