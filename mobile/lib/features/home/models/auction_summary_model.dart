import '../../../core/utils/safe_json_parser.dart';

/// Summary model for live/scheduled auctions on the Home feed (M-HM-01)
class AuctionSummaryModel {
  final int id;
  final int productId;
  final String title;
  final double currentBid;
  final double? startingPrice;
  final int bidCount;
  final int watchCount;
  final DateTime? startsAt;
  final DateTime endsAt;
  final String? primaryImageUrl;
  final String status;
  final int extendedCount;
  final bool isOwner;
  final String? sellerDisplayName;
  final String? categoryName;
  final String? condition;

  const AuctionSummaryModel({
    required this.id,
    required this.productId,
    required this.title,
    required this.currentBid,
    this.startingPrice,
    required this.bidCount,
    this.watchCount = 0,
    this.startsAt,
    required this.endsAt,
    this.primaryImageUrl,
    this.status = 'LIVE',
    this.extendedCount = 0,
    this.isOwner = false,
    this.sellerDisplayName,
    this.categoryName,
    this.condition,
  });

  bool get isScheduled => status.toUpperCase() == 'SCHEDULED';
  bool get isLive => status.toUpperCase() == 'LIVE';
  bool get isEndingSoon {
    if (!isLive) return false;
    final diff = endsAt.difference(DateTime.now());
    return diff.inSeconds > 0 && diff.inMinutes <= 10;
  }

  factory AuctionSummaryModel.fromJson(Map<String, dynamic> json) {
    String? title;
    String? imageUrl;
    String? catName;
    String? cond;
    if (json['product'] is Map) {
      final pMap = json['product'] as Map;
      title = SafeJsonParser.toNullableString(pMap['title']);
      catName = SafeJsonParser.toNullableString(pMap['category_name']);
      cond = SafeJsonParser.toNullableString(pMap['condition']);
      if (pMap['primary_image'] is Map) {
        final imgMap = pMap['primary_image'] as Map;
        imageUrl = SafeJsonParser.toNullableString(imgMap['image_url']);
      } else {
        imageUrl = SafeJsonParser.toNullableString(pMap['primary_image_url']);
      }
    }
    title ??= SafeJsonParser.toStringValue(
      json['title'],
      defaultValue: 'Phiên đấu giá retro',
    );
    imageUrl ??= SafeJsonParser.toNullableString(json['primary_image_url']);

    String? sName;
    if (json['seller'] is Map) {
      final sMap = json['seller'] as Map;
      sName = SafeJsonParser.toNullableString(sMap['display_name']);
    }

    final double? startPrice = SafeJsonParser.toNullableDouble(
      json['starting_price'],
    );
    final double bid = SafeJsonParser.toDouble(
      json['current_bid'] ?? json['current_highest_bid'] ?? startPrice,
      defaultValue: 0.0,
    );

    final DateTime? starts = SafeJsonParser.toNullableDateTime(
      json['auction_starts_at'],
    );
    final DateTime ends =
        SafeJsonParser.toNullableDateTime(json['auction_ends_at']) ??
        DateTime.now().add(const Duration(hours: 24));

    return AuctionSummaryModel(
      id: SafeJsonParser.toInt(json['id']),
      productId: SafeJsonParser.toInt(json['product_id']),
      title: title,
      currentBid: bid,
      startingPrice: startPrice,
      bidCount: SafeJsonParser.toInt(json['bid_count'], defaultValue: 0),
      watchCount: SafeJsonParser.toInt(json['watch_count'], defaultValue: 0),
      startsAt: starts,
      endsAt: ends,
      primaryImageUrl: imageUrl,
      status: SafeJsonParser.toStringValue(
        json['status'],
        defaultValue: 'LIVE',
      ),
      extendedCount: SafeJsonParser.toInt(
        json['extended_count'],
        defaultValue: 0,
      ),
      isOwner: SafeJsonParser.toBool(json['is_owner'], defaultValue: false),
      sellerDisplayName: sName,
      categoryName: catName,
      condition: cond,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'title': title,
      'current_bid': currentBid,
      'starting_price': startingPrice,
      'bid_count': bidCount,
      'watch_count': watchCount,
      'auction_starts_at': startsAt?.toIso8601String(),
      'auction_ends_at': endsAt.toIso8601String(),
      'primary_image_url': primaryImageUrl,
      'status': status,
      'extended_count': extendedCount,
      'is_owner': isOwner,
      'seller_display_name': sellerDisplayName,
      'category_name': categoryName,
      'condition': condition,
    };
  }
}
