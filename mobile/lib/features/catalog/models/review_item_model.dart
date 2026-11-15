import '../../../core/utils/safe_json_parser.dart';

/// Review item representing a verified buyer review for seller storefront.
class ReviewItemModel {
  final int id;
  final int? orderId;
  final int? productId;
  final int rating;
  final String comment;
  final String reviewerName;
  final String? reviewerAvatarUrl;
  final String? productTitle;
  final String? productImageUrl;
  final bool isVerifiedPurchase;
  final DateTime? createdAt;

  const ReviewItemModel({
    required this.id,
    this.orderId,
    this.productId,
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.reviewerAvatarUrl,
    this.productTitle,
    this.productImageUrl,
    this.isVerifiedPurchase = true,
    this.createdAt,
  });

  String get userName => reviewerName;
  String? get userAvatarUrl => reviewerAvatarUrl;

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) {
    String revName = SafeJsonParser.toStringValue(json['reviewer_name']);
    String? revAvatar = SafeJsonParser.toNullableString(json['reviewer_avatar_url']);
    if (json['reviewer'] is Map<String, dynamic>) {
      final rev = json['reviewer'] as Map<String, dynamic>;
      if (revName.isEmpty) {
        revName = SafeJsonParser.toStringValue(rev['display_name'], defaultValue: 'Người mua ẩn danh');
      }
      revAvatar ??= SafeJsonParser.toNullableString(rev['avatar_url']);
    }
    if (revName.isEmpty) revName = 'Người mua đồ si';

    String? prodTitle = SafeJsonParser.toNullableString(json['product_title']);
    String? prodImg = SafeJsonParser.toNullableString(json['product_image_url']);
    if (json['product'] is Map<String, dynamic>) {
      final prod = json['product'] as Map<String, dynamic>;
      prodTitle ??= SafeJsonParser.toNullableString(prod['title']);
      prodImg ??= SafeJsonParser.toNullableString(prod['primary_image_url']);
    }

    return ReviewItemModel(
      id: SafeJsonParser.toInt(json['id']),
      orderId: SafeJsonParser.toNullableInt(json['order_id']),
      productId: SafeJsonParser.toNullableInt(json['product_id']),
      rating: SafeJsonParser.toInt(json['rating'], defaultValue: 5),
      comment: SafeJsonParser.toStringValue(json['comment']),
      reviewerName: revName,
      reviewerAvatarUrl: revAvatar,
      productTitle: prodTitle,
      productImageUrl: prodImg,
      isVerifiedPurchase: SafeJsonParser.toBool(json['is_verified_purchase'] ?? true),
      createdAt: SafeJsonParser.toNullableDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
      'reviewer_name': reviewerName,
      'reviewer_avatar_url': reviewerAvatarUrl,
      'product_title': productTitle,
      'product_image_url': productImageUrl,
      'is_verified_purchase': isVerifiedPurchase,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
