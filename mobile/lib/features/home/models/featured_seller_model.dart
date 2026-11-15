import '../../../core/utils/safe_json_parser.dart';

/// Featured vintage seller model displayed on Home & Discovery (M-HM-01, M-HM-02)
class FeaturedSellerModel {
  final int id;
  final int userId;
  final String shopName;
  final String shopSlug;
  final String? bio;
  final double trustScore;
  final int completedOrdersCount;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;

  const FeaturedSellerModel({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.shopSlug,
    this.bio,
    this.trustScore = 100.0,
    this.completedOrdersCount = 0,
    this.avatarUrl,
    this.ratingAvg = 5.0,
    this.ratingCount = 0,
  });

  double get rating => ratingAvg;
  int get activeListingsCount => completedOrdersCount;

  factory FeaturedSellerModel.fromJson(Map<String, dynamic> json) {
    String? avatar;
    if (json['user'] is Map) {
      final uMap = json['user'] as Map;
      if (uMap['profile'] is Map) {
        final pMap = uMap['profile'] as Map;
        avatar = SafeJsonParser.toNullableString(pMap['avatar_url']);
      }
    }
    avatar ??= SafeJsonParser.toNullableString(json['avatar_url']);

    return FeaturedSellerModel(
      id: SafeJsonParser.toInt(json['id']),
      userId: SafeJsonParser.toInt(json['user_id']),
      shopName: SafeJsonParser.toStringValue(json['shop_name'], defaultValue: 'Tiệm đồ si Retro'),
      shopSlug: SafeJsonParser.toStringValue(json['shop_slug']),
      bio: SafeJsonParser.toNullableString(json['bio']),
      trustScore: SafeJsonParser.toDouble(json['trust_score'], defaultValue: 100.0),
      completedOrdersCount: SafeJsonParser.toInt(json['completed_orders_count'], defaultValue: 0),
      avatarUrl: avatar,
      ratingAvg: SafeJsonParser.toDouble(json['rating_avg'], defaultValue: 5.0),
      ratingCount: SafeJsonParser.toInt(json['rating_count'], defaultValue: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shop_name': shopName,
      'shop_slug': shopSlug,
      'bio': bio,
      'trust_score': trustScore,
      'completed_orders_count': completedOrdersCount,
      'avatar_url': avatarUrl,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
    };
  }
}
