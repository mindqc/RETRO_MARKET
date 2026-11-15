import '../../catalog/models/product_summary_model.dart';
import '../../home/models/featured_seller_model.dart';

/// Overview model for Saved Favorites and Followed Shops (M-PF-05)
class SavedEngagementOverviewModel {
  final List<ProductSummaryModel> favoriteProducts;
  final List<FeaturedSellerModel> followedShops;

  const SavedEngagementOverviewModel({
    this.favoriteProducts = const [],
    this.followedShops = const [],
  });

  factory SavedEngagementOverviewModel.fromJson(Map<String, dynamic> json) {
    List<ProductSummaryModel> prods = [];
    if (json['favorite_products'] is List) {
      for (final item in json['favorite_products'] as List) {
        if (item is Map<String, dynamic>) {
          prods.add(ProductSummaryModel.fromJson(item));
        } else if (item is Map) {
          prods.add(ProductSummaryModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (json['data'] is List) {
      // If endpoint returns direct paginated products
      for (final item in json['data'] as List) {
        if (item is Map<String, dynamic>) {
          prods.add(ProductSummaryModel.fromJson(item));
        } else if (item is Map) {
          prods.add(ProductSummaryModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    List<FeaturedSellerModel> shops = [];
    if (json['followed_shops'] is List) {
      for (final item in json['followed_shops'] as List) {
        if (item is Map<String, dynamic>) {
          shops.add(FeaturedSellerModel.fromJson(item));
        } else if (item is Map) {
          shops.add(FeaturedSellerModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return SavedEngagementOverviewModel(
      favoriteProducts: prods,
      followedShops: shops,
    );
  }

  SavedEngagementOverviewModel copyWith({
    List<ProductSummaryModel>? favoriteProducts,
    List<FeaturedSellerModel>? followedShops,
  }) {
    return SavedEngagementOverviewModel(
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      followedShops: followedShops ?? this.followedShops,
    );
  }
}
