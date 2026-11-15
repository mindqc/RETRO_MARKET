import '../../catalog/models/category_model.dart';
import '../../catalog/models/product_summary_model.dart';
import 'auction_summary_model.dart';
import 'featured_seller_model.dart';

/// Aggregated Home Feed model parsing response from GET /api/v1/home (M-HM-01)
class HomeFeedModel {
  final List<CategoryModel> categories;
  final List<AuctionSummaryModel> liveAuctions;
  final List<FeaturedSellerModel> featuredSellers;
  final List<ProductSummaryModel> latestProducts;

  const HomeFeedModel({
    this.categories = const [],
    this.liveAuctions = const [],
    this.featuredSellers = const [],
    this.latestProducts = const [],
  });

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) {
    // Categories
    final List<CategoryModel> cats = [];
    if (json['categories'] is List) {
      for (final item in json['categories'] as List) {
        if (item is Map) {
          cats.add(CategoryModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Live Auctions
    final List<AuctionSummaryModel> auctions = [];
    if (json['live_auctions'] is List) {
      for (final item in json['live_auctions'] as List) {
        if (item is Map) {
          auctions.add(AuctionSummaryModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Featured Sellers
    final List<FeaturedSellerModel> sellers = [];
    if (json['featured_sellers'] is List) {
      for (final item in json['featured_sellers'] as List) {
        if (item is Map) {
          sellers.add(FeaturedSellerModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Latest Products
    final List<ProductSummaryModel> products = [];
    if (json['latest_products'] is List) {
      for (final item in json['latest_products'] as List) {
        if (item is Map) {
          products.add(ProductSummaryModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return HomeFeedModel(
      categories: cats,
      liveAuctions: auctions,
      featuredSellers: sellers,
      latestProducts: products,
    );
  }

  HomeFeedModel copyWith({
    List<CategoryModel>? categories,
    List<AuctionSummaryModel>? liveAuctions,
    List<FeaturedSellerModel>? featuredSellers,
    List<ProductSummaryModel>? latestProducts,
  }) {
    return HomeFeedModel(
      categories: categories ?? this.categories,
      liveAuctions: liveAuctions ?? this.liveAuctions,
      featuredSellers: featuredSellers ?? this.featuredSellers,
      latestProducts: latestProducts ?? this.latestProducts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((c) => c.toJson()).toList(),
      'live_auctions': liveAuctions.map((a) => a.toJson()).toList(),
      'featured_sellers': featuredSellers.map((s) => s.toJson()).toList(),
      'latest_products': latestProducts.map((p) => p.toJson()).toList(),
    };
  }
}
