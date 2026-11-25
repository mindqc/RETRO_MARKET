import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/server_time_service.dart';
import '../../../core/utils/safe_json_parser.dart';
import '../models/auction_bid_item_model.dart';
import '../models/auction_card_model.dart';
import '../models/auction_detail_model.dart';

/// Repository managing Scheduled Auctions, Live Bidding Room, Anti-Sniping & Relist (P7-10)
class AuctionRepository {
  final DioClient dioClient;

  AuctionRepository({required this.dioClient});

  Map<String, dynamic> _extractDataMap(dynamic rawData) {
    if (rawData is! Map) return <String, dynamic>{};

    final data = rawData['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  /// Visible for testing safe data extraction.
  Map<String, dynamic> extractDataMap(dynamic rawData) =>
      _extractDataMap(rawData);

  /// Lists auctions for Hub tabs: live, ending_soon, upcoming, completed (M-AC-01)
  /// GET /api/v1/auctions
  Future<PaginatedResponse<AuctionCardModel>> fetchHubAuctions({
    String tab = 'live',
    int page = 1,
    int perPage = 12,
    int? currentUserId,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.auctions,
      queryParameters: {'tab': tab, 'page': page, 'per_page': perPage},
    );

    final data = response.data ?? {};
    final serverTime = SafeJsonParser.toNullableDateTime(data['server_time']);
    if (serverTime != null) {
      ServerTimeService.instance.syncWithServer(serverTime);
    }

    return PaginatedResponse.fromJson(
      data,
      (json) => AuctionCardModel.fromJson(
        json as Map<String, dynamic>,
        currentUserId: currentUserId,
      ),
    );
  }

  /// Lists user's personal auction activities: participating, watchlist, won (M-AC-02)
  /// GET /api/v1/auctions/mine
  Future<PaginatedResponse<AuctionCardModel>> fetchMyAuctions({
    String tab = 'participating',
    int page = 1,
    int perPage = 12,
    int? currentUserId,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.myAuctions,
      queryParameters: {'tab': tab, 'page': page, 'per_page': perPage},
    );

    final data = response.data ?? {};
    final serverTime = SafeJsonParser.toNullableDateTime(data['server_time']);
    if (serverTime != null) {
      ServerTimeService.instance.syncWithServer(serverTime);
    }

    return PaginatedResponse.fromJson(
      data,
      (json) => AuctionCardModel.fromJson(
        json as Map<String, dynamic>,
        currentUserId: currentUserId,
      ),
    );
  }

  /// Retrieves full auction room detail (M-AC-03)
  /// GET /api/v1/auctions/{id}
  Future<AuctionDetailModel> fetchAuctionDetail(
    int auctionId, {
    int? currentUserId,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.auctionDetail(auctionId),
    );

    final data = _extractDataMap(response.data);
    final serverTime = SafeJsonParser.toNullableDateTime(
      data['server_time'] ?? response.data?['server_time'],
    );
    if (serverTime != null) {
      ServerTimeService.instance.syncWithServer(serverTime);
    }

    return AuctionDetailModel.fromJson(data, currentUserId: currentUserId);
  }

  /// Lists all bids of an auction with pagination
  /// GET /api/v1/auctions/{id}/bids
  Future<PaginatedResponse<AuctionBidItemModel>> fetchAuctionBids(
    int auctionId, {
    int page = 1,
    int perPage = 20,
    int? currentUserId,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.auctionBids(auctionId),
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final data = response.data ?? {};
    return PaginatedResponse.fromJson(
      data,
      (json) => AuctionBidItemModel.fromJson(
        json as Map<String, dynamic>,
        currentUserId: currentUserId,
      ),
    );
  }

  /// Places a concurrent bid on an active auction (M-AC-04 / BR-AU-03)
  /// POST /api/v1/auctions/{id}/bids
  Future<Map<String, dynamic>> placeBid(
    int auctionId,
    double bidAmount, {
    int? currentUserId,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.auctionBids(auctionId),
      data: {'bid_amount': bidAmount},
    );

    final data = _extractDataMap(response.data);

    final auctionData = data['auction'] is Map
        ? Map<String, dynamic>.from(data['auction'] as Map)
        : <String, dynamic>{};

    final bidData = data['bid'] is Map
        ? Map<String, dynamic>.from(data['bid'] as Map)
        : <String, dynamic>{};
    final triggeredAntiSniping = SafeJsonParser.toBool(
      data['triggered_anti_sniping'],
      defaultValue: false,
    );

    return {
      'auction': AuctionDetailModel.fromJson(
        auctionData,
        currentUserId: currentUserId,
      ),
      'bid': AuctionBidItemModel.fromJson(
        bidData,
        currentUserId: currentUserId,
      ),
      'triggered_anti_sniping': triggeredAntiSniping,
    };
  }

  /// Toggles watch / unwatch an auction (M-AC-01 / Watchlist)
  /// POST /api/v1/auctions/{id}/watch
  Future<bool> toggleWatch(int auctionId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.auctionWatch(auctionId),
    );

    final data = _extractDataMap(response.data);
    return SafeJsonParser.toBool(data['is_watching'], defaultValue: false);
  }

  /// Seller closes an auction early (M-AC-05 / BR-AU-05 / AF-06)
  /// POST /api/v1/auctions/{id}/close-early
  Future<AuctionDetailModel> closeEarly(
    int auctionId, {
    int? currentUserId,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.auctionCloseEarly(auctionId),
    );

    final data = _extractDataMap(response.data);
    final auctionData = data['auction'] is Map
        ? Map<String, dynamic>.from(data['auction'] as Map)
        : data;

    return AuctionDetailModel.fromJson(
      auctionData,
      currentUserId: currentUserId,
    );
  }

  /// Seller relists an unsold or defaulted auction product (M-AC-06 / DEC-02 / AF-09)
  /// POST /api/v1/seller/products/{id}/relist
  Future<AuctionDetailModel> relistAuction(
    int productId, {
    required double startingPrice,
    required double minBidIncrement,
    required DateTime auctionStartsAt,
    required DateTime auctionEndsAt,
    double? reservePrice,
    int? currentUserId,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.sellerRelist(productId),
      data: {
        'starting_price': startingPrice,
        'min_bid_increment': minBidIncrement,
        'auction_starts_at': auctionStartsAt.toIso8601String(),
        'auction_ends_at': auctionEndsAt.toIso8601String(),
        'reserve_price': ?reservePrice,
      },
    );

    final data = _extractDataMap(response.data);
    return AuctionDetailModel.fromJson(data, currentUserId: currentUserId);
  }
}

/// Riverpod provider for AuctionRepository
final auctionRepositoryProvider = Provider<AuctionRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuctionRepository(dioClient: dioClient);
});
