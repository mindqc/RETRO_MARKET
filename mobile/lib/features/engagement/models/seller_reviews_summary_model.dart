import '../../../core/utils/safe_json_parser.dart';
import '../../catalog/models/review_item_model.dart';

/// Aggregated summary model for Seller Reviews list (M-RV-02)
class SellerReviewsSummaryModel {
  final int sellerId;
  final String shopName;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> starDistribution;
  final List<ReviewItemModel> reviews;

  const SellerReviewsSummaryModel({
    required this.sellerId,
    required this.shopName,
    this.averageRating = 5.0,
    this.totalReviews = 0,
    this.starDistribution = const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    this.reviews = const [],
  });

  factory SellerReviewsSummaryModel.fromJson(Map<String, dynamic> json) {
    List<ReviewItemModel> revs = [];
    final rawList = json['data'] ?? json['reviews'];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          revs.add(ReviewItemModel.fromJson(item));
        } else if (item is Map) {
          revs.add(ReviewItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    if (json['star_distribution'] is Map) {
      final sMap = json['star_distribution'] as Map;
      sMap.forEach((k, v) {
        final star = SafeJsonParser.toInt(k);
        if (star >= 1 && star <= 5) {
          dist[star] = SafeJsonParser.toInt(v);
        }
      });
    } else {
      // Calculate from revs if not provided
      for (final r in revs) {
        if (r.rating >= 1 && r.rating <= 5) {
          dist[r.rating] = (dist[r.rating] ?? 0) + 1;
        }
      }
    }

    final total = SafeJsonParser.toInt(json['total_reviews'], defaultValue: revs.length);
    double avg = SafeJsonParser.toDouble(json['average_rating'], defaultValue: 0.0);
    if (avg == 0.0 && revs.isNotEmpty) {
      avg = revs.map((r) => r.rating).reduce((a, b) => a + b) / revs.length;
    } else if (avg == 0.0) {
      avg = 5.0;
    }

    return SellerReviewsSummaryModel(
      sellerId: SafeJsonParser.toInt(json['seller_id']),
      shopName: SafeJsonParser.toStringValue(json['shop_name'], defaultValue: 'Tiệm đồ si vintage'),
      averageRating: avg,
      totalReviews: total,
      starDistribution: dist,
      reviews: revs,
    );
  }

  SellerReviewsSummaryModel copyWith({
    List<ReviewItemModel>? reviews,
  }) {
    return SellerReviewsSummaryModel(
      sellerId: sellerId,
      shopName: shopName,
      averageRating: averageRating,
      totalReviews: totalReviews,
      starDistribution: starDistribution,
      reviews: reviews ?? this.reviews,
    );
  }
}
