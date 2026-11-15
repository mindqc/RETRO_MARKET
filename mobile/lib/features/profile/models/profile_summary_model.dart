import '../../../core/utils/safe_json_parser.dart';
import '../../auth/models/user_model.dart';

/// Unified Account Profile Summary with order status breakdown (M-PF-01)
class ProfileSummaryModel {
  final UserModel user;
  final Map<String, int> orderStatusCounts;
  final int favoritesCount;
  final int followingCount;

  const ProfileSummaryModel({
    required this.user,
    this.orderStatusCounts = const {},
    this.favoritesCount = 0,
    this.followingCount = 0,
  });

  int get pendingPaymentCount => orderStatusCounts['PENDING_PAYMENT'] ?? 0;
  int get paidCount => orderStatusCounts['PAID'] ?? 0;
  int get preparingCount => orderStatusCounts['PREPARING'] ?? 0;
  int get shippedCount => orderStatusCounts['SHIPPED'] ?? 0;
  int get deliveredCount => orderStatusCounts['DELIVERED'] ?? 0;
  int get completedCount => orderStatusCounts['COMPLETED'] ?? 0;
  int get disputedCount => orderStatusCounts['DISPUTED'] ?? 0;

  int get totalActiveOrders =>
      pendingPaymentCount + paidCount + preparingCount + shippedCount + deliveredCount + disputedCount;

  factory ProfileSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : <String, dynamic>{});

    final Map<String, int> counts = {};
    if (json['order_status_counts'] is Map) {
      final rawCounts = json['order_status_counts'] as Map;
      rawCounts.forEach((key, value) {
        counts[key.toString()] = SafeJsonParser.toInt(value, defaultValue: 0);
      });
    }

    return ProfileSummaryModel(
      user: UserModel.fromJson(rawUser),
      orderStatusCounts: counts,
      favoritesCount: SafeJsonParser.toInt(json['favorites_count'], defaultValue: 0),
      followingCount: SafeJsonParser.toInt(json['following_count'], defaultValue: 0),
    );
  }

  ProfileSummaryModel copyWith({
    UserModel? user,
    Map<String, int>? orderStatusCounts,
    int? favoritesCount,
    int? followingCount,
  }) {
    return ProfileSummaryModel(
      user: user ?? this.user,
      orderStatusCounts: orderStatusCounts ?? this.orderStatusCounts,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}
