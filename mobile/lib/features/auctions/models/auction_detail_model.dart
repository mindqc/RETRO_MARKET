import '../../../core/utils/safe_json_parser.dart';
import 'auction_bid_item_model.dart';

/// Full detail model for the Live Bidding Room (M-AC-03)
class AuctionDetailModel {
  final int id;
  final String auctionCode;
  final int productId;
  final int sellerId;
  final int? sessionId;
  final double startingPrice;
  final double minBidIncrement;
  final double minimumNextBid;
  final double currentHighestBid;
  final bool hasReservePrice;
  final bool reservePriceMet;
  final double? reservePrice;
  final int bidCount;
  final int watchCount;
  final String status;
  final DateTime? auctionStartsAt;
  final DateTime auctionEndsAt;
  final int extendedCount;
  final DateTime? lastExtendedAt;
  final bool closedEarlyBySeller;
  final DateTime? closedAt;
  final DateTime? serverTime;

  // Product
  final String productTitle;
  final String? productSlug;
  final String? productDescription;
  final String? primaryImageUrl;
  final List<String> productImages;
  final String? categoryName;
  final String? condition;
  final bool authenticityGuarantee;

  // Seller
  final String? sellerDisplayName;
  final String? sellerAvatarUrl;
  final String? sellerShopSlug;
  final double sellerTrustScore;

  // Leading & Winner
  final int? leadingBidderId;
  final String? leadingBidderName;
  final String? leadingBidderAvatarUrl;
  final int? winnerId;
  final String? winnerDisplayName;
  final String? winnerAvatarUrl;
  final int? orderId;
  final int? paymentId;
  final DateTime? paymentDeadlineAt;

  // User state
  final String? myBidStatus;
  final bool isOwner;
  final bool isWatching;
  final bool isLeading;
  final bool isOutbid;

  // Bid history
  final List<AuctionBidItemModel> recentBids;

  const AuctionDetailModel({
    required this.id,
    required this.auctionCode,
    required this.productId,
    required this.sellerId,
    this.sessionId,
    required this.startingPrice,
    required this.minBidIncrement,
    required this.minimumNextBid,
    required this.currentHighestBid,
    this.hasReservePrice = false,
    this.reservePriceMet = false,
    this.reservePrice,
    required this.bidCount,
    required this.watchCount,
    required this.status,
    this.auctionStartsAt,
    required this.auctionEndsAt,
    this.extendedCount = 0,
    this.lastExtendedAt,
    this.closedEarlyBySeller = false,
    this.closedAt,
    this.serverTime,
    required this.productTitle,
    this.productSlug,
    this.productDescription,
    this.primaryImageUrl,
    this.productImages = const [],
    this.categoryName,
    this.condition,
    this.authenticityGuarantee = false,
    this.sellerDisplayName,
    this.sellerAvatarUrl,
    this.sellerShopSlug,
    this.sellerTrustScore = 100.0,
    this.leadingBidderId,
    this.leadingBidderName,
    this.leadingBidderAvatarUrl,
    this.winnerId,
    this.winnerDisplayName,
    this.winnerAvatarUrl,
    this.orderId,
    this.paymentId,
    this.paymentDeadlineAt,
    this.myBidStatus,
    this.isOwner = false,
    this.isWatching = false,
    this.isLeading = false,
    this.isOutbid = false,
    this.recentBids = const [],
  });

  bool get isLive => status == 'LIVE';
  bool get isScheduled => status == 'SCHEDULED';
  bool get isCompleted =>
      status == 'COMPLETED' ||
      status == 'ENDED_SOLD' ||
      status == 'ENDED_UNSOLD' ||
      status == 'WINNER_DEFAULTED' ||
      status == 'CANCELLED';

  bool get canCloseEarly => isOwner && isLive && bidCount > 0;
  bool get canRelist =>
      isOwner && (status == 'ENDED_UNSOLD' || status == 'WINNER_DEFAULTED');

  factory AuctionDetailModel.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    // Determine whether json is top-level show payload: { "auction": {...}, "recent_bids": [...], ... }
    // or direct AuctionDetailResource: { "id": 1, "auction_code": "...", ... }
    final Map<String, dynamic> aMap = (json['auction'] is Map)
        ? Map<String, dynamic>.from(json['auction'] as Map)
        : json;

    final id = SafeJsonParser.toInt(aMap['id']);
    final code = SafeJsonParser.toStringValue(aMap['auction_code']);
    final pId = SafeJsonParser.toInt(aMap['product_id']);
    final sId = SafeJsonParser.toInt(aMap['seller_id']);
    final sessId = SafeJsonParser.toNullableInt(aMap['session_id']);

    final sPrice = SafeJsonParser.toDouble(
      aMap['starting_price'],
      defaultValue: 0.0,
    );
    final minInc = SafeJsonParser.toDouble(
      aMap['min_bid_increment'],
      defaultValue: 10000.0,
    );
    final curHighest = SafeJsonParser.toDouble(
      aMap['current_highest_bid'],
      defaultValue: sPrice,
    );

    final minNext = SafeJsonParser.toDouble(
      json['minimum_next_bid'] ?? aMap['minimum_next_bid'],
      defaultValue: curHighest + minInc,
    );

    final hasRes = SafeJsonParser.toBool(
      json['has_reserve_price'] ?? aMap['has_reserve_price'],
      defaultValue: false,
    );
    final resMet = SafeJsonParser.toBool(
      json['reserve_price_met'] ?? aMap['reserve_price_met'],
      defaultValue: false,
    );
    final resPrice = SafeJsonParser.toNullableDouble(
      json['reserve_price'] ?? aMap['reserve_price'],
    );

    final bCount = SafeJsonParser.toInt(aMap['bid_count'], defaultValue: 0);
    final wCount = SafeJsonParser.toInt(aMap['watch_count'], defaultValue: 0);
    final stat = SafeJsonParser.toStringValue(
      aMap['status'],
      defaultValue: 'LIVE',
    );

    final aStarts = SafeJsonParser.toNullableDateTime(
      aMap['auction_starts_at'],
    );
    final aEnds =
        SafeJsonParser.toNullableDateTime(aMap['auction_ends_at']) ??
        DateTime.now().add(const Duration(hours: 1));
    final extCount = SafeJsonParser.toInt(
      aMap['extended_count'],
      defaultValue: 0,
    );
    final lastExt = SafeJsonParser.toNullableDateTime(aMap['last_extended_at']);
    final closedEarly = SafeJsonParser.toBool(
      aMap['closed_early_by_seller'],
      defaultValue: false,
    );
    final closedAt = SafeJsonParser.toNullableDateTime(aMap['closed_at']);

    final sTime = SafeJsonParser.toNullableDateTime(
      json['server_time'] ?? aMap['server_time'],
    );

    // Product info
    String pTitle = 'Sản phẩm đấu giá retro';
    String? pSlug;
    String? pDesc;
    String? primImg;
    List<String> imgs = [];
    String? catName;
    String? cond;
    bool authGuar = false;

    if (aMap['product'] is Map) {
      final pData = aMap['product'] as Map;
      pTitle = SafeJsonParser.toStringValue(
        pData['title'],
        defaultValue: pTitle,
      );
      pSlug = SafeJsonParser.toNullableString(pData['slug']);
      pDesc = SafeJsonParser.toNullableString(pData['description']);
      primImg = SafeJsonParser.toNullableString(pData['primary_image_url']);
      catName = SafeJsonParser.toNullableString(pData['category_name']);
      cond = SafeJsonParser.toNullableString(pData['condition']);
      authGuar = SafeJsonParser.toBool(
        pData['authenticity_guarantee'],
        defaultValue: false,
      );

      if (pData['images'] is List) {
        for (final item in pData['images'] as List) {
          if (item is Map) {
            final url = SafeJsonParser.toNullableString(item['image_url']);
            if (url != null && url.isNotEmpty) imgs.add(url);
          } else if (item is String && item.isNotEmpty) {
            imgs.add(item);
          }
        }
      }
    }
    if (imgs.isEmpty && primImg != null && primImg.isNotEmpty) {
      imgs.add(primImg);
    }

    // Seller info
    String? sName;
    String? sAvatar;
    String? sSlug;
    double sTrust = 100.0;
    if (aMap['seller'] is Map) {
      final sData = aMap['seller'] as Map;
      sName = SafeJsonParser.toNullableString(sData['display_name']);
      sAvatar = SafeJsonParser.toNullableString(sData['avatar_url']);
      sSlug = SafeJsonParser.toNullableString(sData['shop_slug']);
      sTrust = SafeJsonParser.toDouble(
        sData['trust_score'],
        defaultValue: 100.0,
      );
    }

    // Leading bidder
    int? leadId;
    String? leadName;
    String? leadAvatar;
    if (aMap['leading_bidder'] is Map) {
      final lData = aMap['leading_bidder'] as Map;
      leadId = SafeJsonParser.toNullableInt(lData['id']);
      leadName = SafeJsonParser.toNullableString(lData['display_name']);
      leadAvatar = SafeJsonParser.toNullableString(lData['avatar_url']);
    }

    // Winner
    int? winId;
    String? winName;
    String? winAvatar;
    if (aMap['winner'] is Map) {
      final wData = aMap['winner'] as Map;
      winId = SafeJsonParser.toNullableInt(wData['id']);
      winName = SafeJsonParser.toNullableString(wData['display_name']);
      winAvatar = SafeJsonParser.toNullableString(wData['avatar_url']);
    }

    // Order & Payment
    int? ordId;
    int? payId;
    DateTime? payDeadline;
    if (aMap['order'] is Map) {
      final oData = aMap['order'] as Map;
      ordId = SafeJsonParser.toNullableInt(oData['id']);
      payDeadline = SafeJsonParser.toNullableDateTime(
        oData['payment_expires_at'],
      );
      if (oData['payments'] is List && (oData['payments'] as List).isNotEmpty) {
        final pFirst = (oData['payments'] as List).first;
        if (pFirst is Map) {
          payId = SafeJsonParser.toNullableInt(pFirst['id']);
        }
      }
    }

    // User permissions & status
    final isOwnerVal = json['is_owner'] != null
        ? SafeJsonParser.toBool(json['is_owner'])
        : (currentUserId != null && sId == currentUserId);

    final isWatchVal = SafeJsonParser.toBool(
      json['is_watching'] ?? aMap['is_watching'],
      defaultValue: false,
    );

    final isLeadVal = json['is_leading'] != null
        ? SafeJsonParser.toBool(json['is_leading'])
        : (currentUserId != null && leadId == currentUserId);

    // Recent bids
    List<AuctionBidItemModel> bids = [];
    final rawBidsList = json['recent_bids'] ?? aMap['recent_bids'];
    if (rawBidsList is List) {
      for (final b in rawBidsList) {
        if (b is Map<String, dynamic>) {
          bids.add(
            AuctionBidItemModel.fromJson(b, currentUserId: currentUserId),
          );
        } else if (b is Map) {
          bids.add(
            AuctionBidItemModel.fromJson(
              Map<String, dynamic>.from(b),
              currentUserId: currentUserId,
            ),
          );
        }
      }
    }

    return AuctionDetailModel(
      id: id,
      auctionCode: code,
      productId: pId,
      sellerId: sId,
      sessionId: sessId,
      startingPrice: sPrice,
      minBidIncrement: minInc,
      minimumNextBid: minNext,
      currentHighestBid: curHighest,
      hasReservePrice: hasRes,
      reservePriceMet: resMet,
      reservePrice: resPrice,
      bidCount: bCount,
      watchCount: wCount,
      status: stat,
      auctionStartsAt: aStarts,
      auctionEndsAt: aEnds,
      extendedCount: extCount,
      lastExtendedAt: lastExt,
      closedEarlyBySeller: closedEarly,
      closedAt: closedAt,
      serverTime: sTime,
      productTitle: pTitle,
      productSlug: pSlug,
      productDescription: pDesc,
      primaryImageUrl: primImg,
      productImages: imgs,
      categoryName: catName,
      condition: cond,
      authenticityGuarantee: authGuar,
      sellerDisplayName: sName,
      sellerAvatarUrl: sAvatar,
      sellerShopSlug: sSlug,
      sellerTrustScore: sTrust,
      leadingBidderId: leadId,
      leadingBidderName: leadName,
      leadingBidderAvatarUrl: leadAvatar,
      winnerId: winId,
      winnerDisplayName: winName,
      winnerAvatarUrl: winAvatar,
      orderId: ordId,
      paymentId: payId,
      paymentDeadlineAt: payDeadline,
      myBidStatus: SafeJsonParser.toNullableString(
        json['my_bid_status'] ?? aMap['my_bid_status'],
      ),
      isOwner: isOwnerVal,
      isWatching: isWatchVal,
      isLeading: isLeadVal,
      isOutbid:
          !isLeadVal &&
          currentUserId != null &&
          bids.any((b) => b.bidderId == currentUserId),
      recentBids: bids,
    );
  }

  AuctionDetailModel copyWith({
    double? currentHighestBid,
    double? minimumNextBid,
    int? bidCount,
    DateTime? auctionEndsAt,
    int? extendedCount,
    DateTime? lastExtendedAt,
    bool? isWatching,
    bool? isLeading,
    bool? isOutbid,
    List<AuctionBidItemModel>? recentBids,
    String? status,
    bool? reservePriceMet,
    int? leadingBidderId,
    String? leadingBidderName,
    String? leadingBidderAvatarUrl,
    int? winnerId,
    String? winnerDisplayName,
    int? orderId,
  }) {
    return AuctionDetailModel(
      id: id,
      auctionCode: auctionCode,
      productId: productId,
      sellerId: sellerId,
      sessionId: sessionId,
      startingPrice: startingPrice,
      minBidIncrement: minBidIncrement,
      minimumNextBid: minimumNextBid ?? this.minimumNextBid,
      currentHighestBid: currentHighestBid ?? this.currentHighestBid,
      hasReservePrice: hasReservePrice,
      reservePriceMet: reservePriceMet ?? this.reservePriceMet,
      reservePrice: reservePrice,
      bidCount: bidCount ?? this.bidCount,
      watchCount: isWatching != null
          ? (isWatching
                ? watchCount + 1
                : (watchCount > 0 ? watchCount - 1 : 0))
          : watchCount,
      status: status ?? this.status,
      auctionStartsAt: auctionStartsAt,
      auctionEndsAt: auctionEndsAt ?? this.auctionEndsAt,
      extendedCount: extendedCount ?? this.extendedCount,
      lastExtendedAt: lastExtendedAt ?? this.lastExtendedAt,
      closedEarlyBySeller: closedEarlyBySeller,
      closedAt: closedAt,
      serverTime: serverTime,
      productTitle: productTitle,
      productSlug: productSlug,
      productDescription: productDescription,
      primaryImageUrl: primaryImageUrl,
      productImages: productImages,
      categoryName: categoryName,
      condition: condition,
      authenticityGuarantee: authenticityGuarantee,
      sellerDisplayName: sellerDisplayName,
      sellerAvatarUrl: sellerAvatarUrl,
      sellerShopSlug: sellerShopSlug,
      sellerTrustScore: sellerTrustScore,
      leadingBidderId: leadingBidderId ?? this.leadingBidderId,
      leadingBidderName: leadingBidderName ?? this.leadingBidderName,
      leadingBidderAvatarUrl:
          leadingBidderAvatarUrl ?? this.leadingBidderAvatarUrl,
      winnerId: winnerId ?? this.winnerId,
      winnerDisplayName: winnerDisplayName ?? this.winnerDisplayName,
      winnerAvatarUrl: winnerAvatarUrl,
      orderId: orderId ?? this.orderId,
      paymentId: paymentId,
      paymentDeadlineAt: paymentDeadlineAt,
      myBidStatus: myBidStatus,
      isOwner: isOwner,
      isWatching: isWatching ?? this.isWatching,
      isLeading: isLeading ?? this.isLeading,
      isOutbid: isOutbid ?? this.isOutbid,
      recentBids: recentBids ?? this.recentBids,
    );
  }
}
