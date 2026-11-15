import '../../../core/utils/safe_json_parser.dart';

/// Metrics and action counters for the Seller Channel Hub (M-SL-01).
class SellerDashboardModel {
  final String shopName;
  final String? shopSlug;
  final double trustScore;
  final double walletBalance;
  final double escrowHeldBalance;
  final double averageRating;
  final int reviewCount;
  final int completedOrdersCount;
  final int paidOrdersCount;
  final int preparingOrdersCount;
  final int disputedOrdersCount;
  final int pendingReviewCount;
  final int rejectedProductsCount;
  final int activeProductsCount;
  final int soldProductsCount;

  const SellerDashboardModel({
    required this.shopName,
    this.shopSlug,
    this.trustScore = 100.0,
    this.walletBalance = 0.0,
    this.escrowHeldBalance = 0.0,
    this.averageRating = 5.0,
    this.reviewCount = 0,
    this.completedOrdersCount = 0,
    this.paidOrdersCount = 0,
    this.preparingOrdersCount = 0,
    this.disputedOrdersCount = 0,
    this.pendingReviewCount = 0,
    this.rejectedProductsCount = 0,
    this.activeProductsCount = 0,
    this.soldProductsCount = 0,
  });

  factory SellerDashboardModel.fromJson(Map<String, dynamic> json) {
    final actionCounters = json['action_counters'] is Map<String, dynamic>
        ? json['action_counters'] as Map<String, dynamic>
        : <String, dynamic>{};

    return SellerDashboardModel(
      shopName: SafeJsonParser.toStringValue(
        json['shop_name'] ?? json['name'] ?? json['display_name'],
        defaultValue: 'Tiệm Đồ Si Vintage',
      ),
      shopSlug: SafeJsonParser.toNullableString(json['shop_slug']),
      trustScore: SafeJsonParser.toDouble(json['trust_score'], defaultValue: 100.0),
      walletBalance: SafeJsonParser.toDouble(json['wallet_balance']),
      escrowHeldBalance: SafeJsonParser.toDouble(json['escrow_held_balance']),
      averageRating: SafeJsonParser.toDouble(json['average_rating'], defaultValue: 5.0),
      reviewCount: SafeJsonParser.toInt(json['review_count']),
      completedOrdersCount: SafeJsonParser.toInt(json['completed_orders_count']),
      paidOrdersCount: SafeJsonParser.toInt(
        actionCounters['orders_pending_shipment'] ?? json['paid_orders_count'],
      ),
      preparingOrdersCount: SafeJsonParser.toInt(
        actionCounters['cancellation_requests'] ?? json['preparing_orders_count'],
      ),
      disputedOrdersCount: SafeJsonParser.toInt(
        actionCounters['open_disputes'] ?? json['disputed_orders_count'],
      ),
      pendingReviewCount: SafeJsonParser.toInt(
        actionCounters['products_pending_review'] ?? json['pending_review_count'],
      ),
      rejectedProductsCount: SafeJsonParser.toInt(
        actionCounters['products_rejected'] ?? json['rejected_products_count'],
      ),
      activeProductsCount: SafeJsonParser.toInt(
        actionCounters['products_approved'] ?? json['active_products_count'],
      ),
      soldProductsCount: SafeJsonParser.toInt(
        actionCounters['products_sold'] ?? json['sold_products_count'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_name': shopName,
      'shop_slug': shopSlug,
      'trust_score': trustScore,
      'wallet_balance': walletBalance,
      'escrow_held_balance': escrowHeldBalance,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'completed_orders_count': completedOrdersCount,
      'action_counters': {
        'orders_pending_shipment': paidOrdersCount,
        'cancellation_requests': preparingOrdersCount,
        'open_disputes': disputedOrdersCount,
        'products_pending_review': pendingReviewCount,
        'products_rejected': rejectedProductsCount,
        'products_approved': activeProductsCount,
        'products_sold': soldProductsCount,
      },
    };
  }
}
