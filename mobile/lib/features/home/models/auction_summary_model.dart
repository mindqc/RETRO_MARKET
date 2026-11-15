import '../../../core/utils/safe_json_parser.dart';

/// Summary model for live/scheduled auctions on the Home feed (M-HM-01)
class AuctionSummaryModel {
  final int id;
  final int productId;
  final String title;
  final double currentBid;
  final int bidCount;
  final DateTime endsAt;
  final String? primaryImageUrl;
  final String status;
  final int extendedCount;
  final bool isOwner;
  final String? sellerDisplayName;

  const AuctionSummaryModel({
    required this.id,
    required this.productId,
    required this.title,
    required this.currentBid,
    required this.bidCount,
    required this.endsAt,
    this.primaryImageUrl,
    this.status = 'LIVE',
    this.extendedCount = 0,
    this.isOwner = false,
    this.sellerDisplayName,
  });

  factory AuctionSummaryModel.fromJson(Map<String, dynamic> json) {
    String? title;
    String? imageUrl;
    if (json['product'] is Map) {
      final pMap = json['product'] as Map;
      title = SafeJsonParser.toNullableString(pMap['title']);
      if (pMap['primary_image'] is Map) {
        final imgMap = pMap['primary_image'] as Map;
        imageUrl = SafeJsonParser.toNullableString(imgMap['image_url']);
      }
    }
    title ??= SafeJsonParser.toStringValue(json['title'], defaultValue: 'Phiên đấu giá retro');

    String? sName;
    if (json['seller'] is Map) {
      final sMap = json['seller'] as Map;
      sName = SafeJsonParser.toNullableString(sMap['display_name']);
    }

    final double bid = SafeJsonParser.toDouble(
      json['current_bid'] ?? json['starting_price'],
      defaultValue: 0.0,
    );

    final DateTime ends = SafeJsonParser.toNullableDateTime(json['auction_ends_at']) ??
        DateTime.now().add(const Duration(hours: 24));

    return AuctionSummaryModel(
      id: SafeJsonParser.toInt(json['id']),
      productId: SafeJsonParser.toInt(json['product_id']),
      title: title,
      currentBid: bid,
      bidCount: SafeJsonParser.toInt(json['bid_count'], defaultValue: 0),
      endsAt: ends,
      primaryImageUrl: imageUrl,
      status: SafeJsonParser.toStringValue(json['status'], defaultValue: 'LIVE'),
      extendedCount: SafeJsonParser.toInt(json['extended_count'], defaultValue: 0),
      isOwner: SafeJsonParser.toBool(json['is_owner'], defaultValue: false),
      sellerDisplayName: sName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'title': title,
      'current_bid': currentBid,
      'bid_count': bidCount,
      'auction_ends_at': endsAt.toIso8601String(),
      'primary_image_url': primaryImageUrl,
      'status': status,
      'extended_count': extendedCount,
      'is_owner': isOwner,
      'seller_display_name': sellerDisplayName,
    };
  }
}
