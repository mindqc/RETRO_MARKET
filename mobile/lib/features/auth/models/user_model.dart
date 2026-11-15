import '../../../core/utils/safe_json_parser.dart';

/// User profile details (avatar, bio, seasonal decor preference)
class UserProfileModel {
  final int? id;
  final String? avatarUrl;
  final String? bio;
  final bool seasonalDecorEnabled;

  const UserProfileModel({
    this.id,
    this.avatarUrl,
    this.bio,
    this.seasonalDecorEnabled = true,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserProfileModel();
    }
    return UserProfileModel(
      id: SafeJsonParser.toInt(json['id']),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      seasonalDecorEnabled: SafeJsonParser.toBool(
        json['seasonal_decor_enabled'],
        defaultValue: true,
      ),
    );
  }

  UserProfileModel copyWith({
    int? id,
    String? avatarUrl,
    String? bio,
    bool? seasonalDecorEnabled,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      seasonalDecorEnabled: seasonalDecorEnabled ?? this.seasonalDecorEnabled,
    );
  }
}

/// Seller profile details (shop slug, ratings, wallet and escrow balances)
class SellerProfileModel {
  final int? id;
  final String? shopSlug;
  final double trustScore;
  final double averageRating;
  final int reviewCount;
  final int completedOrdersCount;
  final double walletBalance;
  final double escrowHeldBalance;

  const SellerProfileModel({
    this.id,
    this.shopSlug,
    this.trustScore = 100.0,
    this.averageRating = 5.0,
    this.reviewCount = 0,
    this.completedOrdersCount = 0,
    this.walletBalance = 0.0,
    this.escrowHeldBalance = 0.0,
  });

  factory SellerProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SellerProfileModel();
    }
    return SellerProfileModel(
      id: SafeJsonParser.toInt(json['id']),
      shopSlug: json['shop_slug']?.toString(),
      trustScore: SafeJsonParser.toDouble(json['trust_score'], defaultValue: 100.0),
      averageRating: SafeJsonParser.toDouble(json['average_rating'], defaultValue: 5.0),
      reviewCount: SafeJsonParser.toInt(json['review_count'], defaultValue: 0),
      completedOrdersCount: SafeJsonParser.toInt(json['completed_orders_count'], defaultValue: 0),
      walletBalance: SafeJsonParser.toDouble(json['wallet_balance'], defaultValue: 0.0),
      escrowHeldBalance: SafeJsonParser.toDouble(json['escrow_held_balance'], defaultValue: 0.0),
    );
  }

  SellerProfileModel copyWith({
    int? id,
    String? shopSlug,
    double? trustScore,
    double? averageRating,
    int? reviewCount,
    int? completedOrdersCount,
    double? walletBalance,
    double? escrowHeldBalance,
  }) {
    return SellerProfileModel(
      id: id ?? this.id,
      shopSlug: shopSlug ?? this.shopSlug,
      trustScore: trustScore ?? this.trustScore,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedOrdersCount: completedOrdersCount ?? this.completedOrdersCount,
      walletBalance: walletBalance ?? this.walletBalance,
      escrowHeldBalance: escrowHeldBalance ?? this.escrowHeldBalance,
    );
  }
}

/// Standardized User model for authenticated identity across Buyer and Seller domains (BR-AC-01)
class UserModel {
  final int id;
  final String displayName;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? statusReason;
  final DateTime? suspendedUntil;
  final DateTime? lastLoginAt;
  final UserProfileModel? profile;
  final SellerProfileModel? sellerProfile;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.statusReason,
    this.suspendedUntil,
    this.lastLoginAt,
    this.profile,
    this.sellerProfile,
    this.createdAt,
  });

  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';
  bool get isSellerActive => sellerProfile != null && (sellerProfile!.shopSlug != null);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: SafeJsonParser.toInt(json['id']),
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'buyer_seller',
      status: json['status']?.toString() ?? 'ACTIVE',
      statusReason: json['status_reason']?.toString(),
      suspendedUntil: SafeJsonParser.toDateTime(json['suspended_until']),
      lastLoginAt: SafeJsonParser.toDateTime(json['last_login_at']),
      profile: json['profile'] is Map<String, dynamic>
          ? UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : (json['profile'] is Map ? UserProfileModel.fromJson(Map<String, dynamic>.from(json['profile'] as Map)) : null),
      sellerProfile: json['seller_profile'] is Map<String, dynamic>
          ? SellerProfileModel.fromJson(json['seller_profile'] as Map<String, dynamic>)
          : (json['seller_profile'] is Map ? SellerProfileModel.fromJson(Map<String, dynamic>.from(json['seller_profile'] as Map)) : null),
      createdAt: SafeJsonParser.toDateTime(json['created_at']),
    );
  }

  UserModel copyWith({
    int? id,
    String? displayName,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? statusReason,
    DateTime? suspendedUntil,
    DateTime? lastLoginAt,
    UserProfileModel? profile,
    SellerProfileModel? sellerProfile,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profile: profile ?? this.profile,
      sellerProfile: sellerProfile ?? this.sellerProfile,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
