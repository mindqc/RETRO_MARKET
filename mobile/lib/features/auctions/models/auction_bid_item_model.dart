import '../../../core/utils/safe_json_parser.dart';

/// Model representing an individual bid in an auction
class AuctionBidItemModel {
  final int id;
  final int auctionId;
  final int bidderId;
  final double bidAmount;
  final double previousHighestBid;
  final bool triggeredAntiSniping;
  final DateTime createdAt;
  final String bidderName;
  final String? bidderAvatarUrl;
  final bool isMine;
  final bool isLeading;

  const AuctionBidItemModel({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.bidAmount,
    this.previousHighestBid = 0.0,
    this.triggeredAntiSniping = false,
    required this.createdAt,
    required this.bidderName,
    this.bidderAvatarUrl,
    this.isMine = false,
    this.isLeading = false,
  });

  factory AuctionBidItemModel.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final bidderId = SafeJsonParser.toInt(json['bidder_id']);
    String rawName = '';
    String? avatar;

    if (json['bidder'] is Map) {
      final bMap = json['bidder'] as Map;
      rawName = SafeJsonParser.toStringValue(bMap['display_name']);
      avatar = SafeJsonParser.toNullableString(bMap['avatar_url']);
    }

    if (rawName.isEmpty) {
      rawName = SafeJsonParser.toStringValue(json['masked_bidder_name'], defaultValue: 'u***$bidderId');
    }

    final isMine = (currentUserId != null && bidderId == currentUserId) ||
        SafeJsonParser.toBool(json['is_mine'], defaultValue: false);

    return AuctionBidItemModel(
      id: SafeJsonParser.toInt(json['id']),
      auctionId: SafeJsonParser.toInt(json['auction_id']),
      bidderId: bidderId,
      bidAmount: SafeJsonParser.toDouble(json['bid_amount'], defaultValue: 0.0),
      previousHighestBid: SafeJsonParser.toDouble(json['previous_highest_bid'], defaultValue: 0.0),
      triggeredAntiSniping: SafeJsonParser.toBool(json['triggered_anti_sniping'], defaultValue: false),
      createdAt: SafeJsonParser.toNullableDateTime(json['created_at']) ?? DateTime.now(),
      bidderName: rawName,
      bidderAvatarUrl: avatar,
      isMine: isMine,
      isLeading: SafeJsonParser.toBool(json['is_leading'], defaultValue: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'bidder_id': bidderId,
      'bid_amount': bidAmount,
      'previous_highest_bid': previousHighestBid,
      'triggered_anti_sniping': triggeredAntiSniping,
      'created_at': createdAt.toIso8601String(),
      'bidder': {
        'id': bidderId,
        'display_name': bidderName,
        'avatar_url': bidderAvatarUrl,
      },
      'is_mine': isMine,
      'is_leading': isLeading,
    };
  }
}
