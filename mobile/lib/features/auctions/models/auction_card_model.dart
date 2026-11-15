import '../../../core/utils/safe_json_parser.dart';

/// Model representing an auction card in hub tabs (M-AC-01) or user personal auction tabs (M-AC-02)
class AuctionCardModel {
  final int id;
  final String auctionCode;
  final int productId;
  final int sellerId;
  final int? sessionId;
  final double startingPrice;
  final double minBidIncrement;
  final double currentHighestBid;
  final int bidCount;
  final int watchCount;
  final String status;
  final DateTime? auctionStartsAt;
  final DateTime auctionEndsAt;
  final int extendedCount;

  // Product info
  final String productTitle;
  final String? productSlug;
  final String? primaryImageUrl;
  final String? categoryName;
  final String? condition;

  // Seller info
  final String? sellerDisplayName;
  final String? sellerShopSlug;
  final double sellerTrustScore;

  // Bidder status
  final int? leadingBidderId;
  final String? leadingBidderName;
  final double? myHighestBid;
  final String? myBidStatus; // 'LEADING', 'OUTBID', 'WON', null
  final bool isWatching;
  final bool isOwner;

  const AuctionCardModel({
    required this.id,
    required this.auctionCode,
    required this.productId,
    required this.sellerId,
    this.sessionId,
    required this.startingPrice,
    required this.minBidIncrement,
    required this.currentHighestBid,
    required this.bidCount,
    required this.watchCount,
    required this.status,
    this.auctionStartsAt,
    required this.auctionEndsAt,
    this.extendedCount = 0,
    required this.productTitle,
    this.productSlug,
    this.primaryImageUrl,
    this.categoryName,
    this.condition,
    this.sellerDisplayName,
    this.sellerShopSlug,
    this.sellerTrustScore = 100.0,
    this.leadingBidderId,
    this.leadingBidderName,
    this.myHighestBid,
    this.myBidStatus,
    this.isWatching = false,
    this.isOwner = false,
  });

  /// True if current user is the leading bidder
  bool get isLeading => myBidStatus == 'LEADING' || (leadingBidderId != null && leadingBidderName != null);

  /// True if current user has been outbid
  bool get isOutbid => myBidStatus == 'OUTBID';

  /// True if auction has ended
  bool get isCompleted =>
      status == 'COMPLETED' ||
      status == 'ENDED_SOLD' ||
      status == 'ENDED_UNSOLD' ||
      status == 'WINNER_DEFAULTED' ||
      status == 'CANCELLED';

  /// True if auction is currently live
  bool get isLive => status == 'LIVE';

  /// True if auction is scheduled / upcoming
  bool get isScheduled => status == 'SCHEDULED';

  factory AuctionCardModel.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    // Product details
    String pTitle = 'Sản phẩm đấu giá retro';
    String? pSlug;
    String? imgUrl;
    String? catName;
    String? cond;

    if (json['product'] is Map) {
      final pMap = json['product'] as Map;
      pTitle = SafeJsonParser.toStringValue(pMap['title'], defaultValue: pTitle);
      pSlug = SafeJsonParser.toNullableString(pMap['slug']);
      imgUrl = SafeJsonParser.toNullableString(pMap['primary_image_url']);
      catName = SafeJsonParser.toNullableString(pMap['category_name']);
      cond = SafeJsonParser.toNullableString(pMap['condition']);
    }

    // Seller details
    String? sName;
    String? sSlug;
    double sTrust = 100.0;
    if (json['seller'] is Map) {
      final sMap = json['seller'] as Map;
      sName = SafeJsonParser.toNullableString(sMap['display_name']);
      sSlug = SafeJsonParser.toNullableString(sMap['shop_slug']);
      sTrust = SafeJsonParser.toDouble(sMap['trust_score'], defaultValue: 100.0);
    }

    // Leading bidder
    int? leadId;
    String? leadName;
    if (json['leading_bidder'] is Map) {
      final lMap = json['leading_bidder'] as Map;
      leadId = SafeJsonParser.toNullableInt(lMap['id']);
      leadName = SafeJsonParser.toNullableString(lMap['display_name']);
    }

    final sellerId = SafeJsonParser.toInt(json['seller_id']);
    final isOwner = (currentUserId != null && sellerId == currentUserId) ||
        SafeJsonParser.toBool(json['is_owner'], defaultValue: false);

    return AuctionCardModel(
      id: SafeJsonParser.toInt(json['id']),
      auctionCode: SafeJsonParser.toStringValue(json['auction_code']),
      productId: SafeJsonParser.toInt(json['product_id']),
      sellerId: sellerId,
      sessionId: SafeJsonParser.toNullableInt(json['session_id']),
      startingPrice: SafeJsonParser.toDouble(json['starting_price'], defaultValue: 0.0),
      minBidIncrement: SafeJsonParser.toDouble(json['min_bid_increment'], defaultValue: 10000.0),
      currentHighestBid: SafeJsonParser.toDouble(json['current_highest_bid'], defaultValue: 0.0),
      bidCount: SafeJsonParser.toInt(json['bid_count'], defaultValue: 0),
      watchCount: SafeJsonParser.toInt(json['watch_count'], defaultValue: 0),
      status: SafeJsonParser.toStringValue(json['status'], defaultValue: 'LIVE'),
      auctionStartsAt: SafeJsonParser.toNullableDateTime(json['auction_starts_at']),
      auctionEndsAt: SafeJsonParser.toNullableDateTime(json['auction_ends_at']) ??
          DateTime.now().add(const Duration(hours: 1)),
      extendedCount: SafeJsonParser.toInt(json['extended_count'], defaultValue: 0),
      productTitle: pTitle,
      productSlug: pSlug,
      primaryImageUrl: imgUrl,
      categoryName: catName,
      condition: cond,
      sellerDisplayName: sName,
      sellerShopSlug: sSlug,
      sellerTrustScore: sTrust,
      leadingBidderId: leadId,
      leadingBidderName: leadName,
      myHighestBid: SafeJsonParser.toNullableDouble(json['my_highest_bid']),
      myBidStatus: SafeJsonParser.toNullableString(json['my_bid_status']),
      isWatching: SafeJsonParser.toBool(json['is_watching'], defaultValue: false),
      isOwner: isOwner,
    );
  }

  AuctionCardModel copyWith({
    bool? isWatching,
    double? currentHighestBid,
    int? bidCount,
    DateTime? auctionEndsAt,
    int? extendedCount,
    String? status,
    String? myBidStatus,
    double? myHighestBid,
  }) {
    return AuctionCardModel(
      id: id,
      auctionCode: auctionCode,
      productId: productId,
      sellerId: sellerId,
      sessionId: sessionId,
      startingPrice: startingPrice,
      minBidIncrement: minBidIncrement,
      currentHighestBid: currentHighestBid ?? this.currentHighestBid,
      bidCount: bidCount ?? this.bidCount,
      watchCount: isWatching != null
          ? (isWatching ? watchCount + 1 : (watchCount > 0 ? watchCount - 1 : 0))
          : watchCount,
      status: status ?? this.status,
      auctionStartsAt: auctionStartsAt,
      auctionEndsAt: auctionEndsAt ?? this.auctionEndsAt,
      extendedCount: extendedCount ?? this.extendedCount,
      productTitle: productTitle,
      productSlug: productSlug,
      primaryImageUrl: primaryImageUrl,
      categoryName: categoryName,
      condition: condition,
      sellerDisplayName: sellerDisplayName,
      sellerShopSlug: sellerShopSlug,
      sellerTrustScore: sellerTrustScore,
      leadingBidderId: leadingBidderId,
      leadingBidderName: leadingBidderName,
      myHighestBid: myHighestBid ?? this.myHighestBid,
      myBidStatus: myBidStatus ?? this.myBidStatus,
      isWatching: isWatching ?? this.isWatching,
      isOwner: isOwner,
    );
  }
}
