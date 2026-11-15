import '../../../core/utils/safe_json_parser.dart';

/// Represents the latest auction state returned by the server on 409 AUCTION_OUTBID_CONFLICT
class OutbidConflictStateModel {
  final int auctionId;
  final double currentHighestBid;
  final double minimumNextBid;
  final int? leadingBidderId;
  final int bidCount;
  final DateTime auctionEndsAt;
  final int extendedCount;

  const OutbidConflictStateModel({
    required this.auctionId,
    required this.currentHighestBid,
    required this.minimumNextBid,
    this.leadingBidderId,
    required this.bidCount,
    required this.auctionEndsAt,
    this.extendedCount = 0,
  });

  factory OutbidConflictStateModel.fromJson(Map<String, dynamic> json) {
    return OutbidConflictStateModel(
      auctionId: SafeJsonParser.toInt(json['auction_id']),
      currentHighestBid: SafeJsonParser.toDouble(json['current_highest_bid'], defaultValue: 0.0),
      minimumNextBid: SafeJsonParser.toDouble(json['minimum_next_bid'], defaultValue: 0.0),
      leadingBidderId: SafeJsonParser.toNullableInt(json['leading_bidder_id']),
      bidCount: SafeJsonParser.toInt(json['bid_count'], defaultValue: 0),
      auctionEndsAt: SafeJsonParser.toNullableDateTime(json['auction_ends_at']) ??
          DateTime.now().add(const Duration(hours: 1)),
      extendedCount: SafeJsonParser.toInt(json['extended_count'], defaultValue: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auction_id': auctionId,
      'current_highest_bid': currentHighestBid,
      'minimum_next_bid': minimumNextBid,
      'leading_bidder_id': leadingBidderId,
      'bid_count': bidCount,
      'auction_ends_at': auctionEndsAt.toIso8601String(),
      'extended_count': extendedCount,
    };
  }
}
