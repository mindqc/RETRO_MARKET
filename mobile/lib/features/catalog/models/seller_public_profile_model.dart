import '../../../core/utils/safe_json_parser.dart';
import '../../home/models/auction_summary_model.dart';
import 'product_summary_model.dart';
import 'review_item_model.dart';

/// Public storefront profile of a vintage shop / seller.
class SellerPublicProfileModel {
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? shopSlug;
  final String? bio;
  final double trustScore;
  final double averageRating;
  final int reviewCount;
  final int completedOrdersCount;
  final int followersCount;
  final DateTime? joinedAt;
  final bool isFollowing;
  final bool isOwner;
  final bool seasonalDecorEnabled;
  final List<ProductSummaryModel> activeListings;
  final List<AuctionSummaryModel> auctions;
  final List<ProductSummaryModel> soldListings;
  final List<ReviewItemModel> reviews;

  const SellerPublicProfileModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.coverImageUrl,
    this.shopSlug,
    this.bio,
    this.trustScore = 100.0,
    this.averageRating = 5.0,
    this.reviewCount = 0,
    this.completedOrdersCount = 0,
    this.followersCount = 0,
    this.joinedAt,
    this.isFollowing = false,
    this.isOwner = false,
    this.seasonalDecorEnabled = false,
    this.activeListings = const [],
    this.auctions = const [],
    this.soldListings = const [],
    this.reviews = const [],
  });

  factory SellerPublicProfileModel.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> sellerData = (rawJson['seller'] is Map<String, dynamic>)
        ? rawJson['seller'] as Map<String, dynamic>
        : rawJson;

    final int id = SafeJsonParser.toInt(sellerData['id'] ?? sellerData['user_id'] ?? rawJson['user_id']);
    final String name = SafeJsonParser.toStringValue(
      sellerData['display_name'] ?? rawJson['display_name'],
      defaultValue: 'Tiệm Đồ Si Cổ Điển',
    );
    final String? avatar = SafeJsonParser.toNullableString(sellerData['avatar_url'] ?? rawJson['avatar_url']);
    final String? cover = SafeJsonParser.toNullableString(
      sellerData['cover_image_url'] ?? rawJson['cover_image_url'] ??
      'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=1200&q=80',
    );
    final String? slug = SafeJsonParser.toNullableString(sellerData['shop_slug'] ?? rawJson['shop_slug']);
    final String? bioText = SafeJsonParser.toNullableString(sellerData['bio'] ?? rawJson['bio']);

    final double score = SafeJsonParser.toDouble(sellerData['trust_score'] ?? rawJson['trust_score'], defaultValue: 100.0);
    final double rating = SafeJsonParser.toDouble(sellerData['average_rating'] ?? rawJson['average_rating'], defaultValue: 5.0);
    final int revCount = SafeJsonParser.toInt(sellerData['review_count'] ?? rawJson['review_count']);
    final int orders = SafeJsonParser.toInt(sellerData['completed_orders_count'] ?? rawJson['completed_orders_count']);
    final int followers = SafeJsonParser.toInt(rawJson['followers_count'] ?? sellerData['followers_count']);
    final bool following = SafeJsonParser.toBool(rawJson['is_following'] ?? sellerData['is_following']);
    final bool owner = SafeJsonParser.toBool(rawJson['is_owner'] ?? sellerData['is_owner']);
    final bool decor = SafeJsonParser.toBool(sellerData['seasonal_decor_enabled'] ?? rawJson['seasonal_decor_enabled']);
    final DateTime? joined = SafeJsonParser.toNullableDateTime(sellerData['created_at'] ?? rawJson['joined_at']);

    // Parse active products if present
    final List<ProductSummaryModel> activeProds = [];
    final prodsRaw = rawJson['products'] ?? rawJson['active_listings'];
    if (prodsRaw is List) {
      for (final p in prodsRaw) {
        if (p is Map<String, dynamic>) {
          activeProds.add(ProductSummaryModel.fromJson(p));
        }
      }
    }

    // Parse sold listings
    final List<ProductSummaryModel> soldProds = [];
    final soldRaw = rawJson['sold_listings'];
    if (soldRaw is List) {
      for (final p in soldRaw) {
        if (p is Map<String, dynamic>) {
          soldProds.add(ProductSummaryModel.fromJson(p));
        }
      }
    }

    // Parse auctions
    final List<AuctionSummaryModel> aucs = [];
    final aucsRaw = rawJson['auctions'];
    if (aucsRaw is List) {
      for (final a in aucsRaw) {
        if (a is Map<String, dynamic>) {
          aucs.add(AuctionSummaryModel.fromJson(a));
        }
      }
    }

    // Parse reviews
    final List<ReviewItemModel> revs = [];
    final revsRaw = rawJson['reviews'];
    if (revsRaw is List) {
      for (final r in revsRaw) {
        if (r is Map<String, dynamic>) {
          revs.add(ReviewItemModel.fromJson(r));
        }
      }
    }

    return SellerPublicProfileModel(
      userId: id,
      displayName: name,
      avatarUrl: avatar,
      coverImageUrl: cover,
      shopSlug: slug,
      bio: bioText,
      trustScore: score,
      averageRating: rating,
      reviewCount: revCount,
      completedOrdersCount: orders,
      followersCount: followers,
      joinedAt: joined,
      isFollowing: following,
      isOwner: owner,
      seasonalDecorEnabled: decor,
      activeListings: activeProds,
      auctions: aucs,
      soldListings: soldProds,
      reviews: revs,
    );
  }

  SellerPublicProfileModel copyWith({
    bool? isFollowing,
    int? followersCount,
    List<ProductSummaryModel>? activeListings,
    List<AuctionSummaryModel>? auctions,
    List<ProductSummaryModel>? soldListings,
    List<ReviewItemModel>? reviews,
  }) {
    return SellerPublicProfileModel(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      coverImageUrl: coverImageUrl,
      shopSlug: shopSlug,
      bio: bio,
      trustScore: trustScore,
      averageRating: averageRating,
      reviewCount: reviewCount,
      completedOrdersCount: completedOrdersCount,
      followersCount: followersCount ?? this.followersCount,
      joinedAt: joinedAt,
      isFollowing: isFollowing ?? this.isFollowing,
      isOwner: isOwner,
      seasonalDecorEnabled: seasonalDecorEnabled,
      activeListings: activeListings ?? this.activeListings,
      auctions: auctions ?? this.auctions,
      soldListings: soldListings ?? this.soldListings,
      reviews: reviews ?? this.reviews,
    );
  }
}
