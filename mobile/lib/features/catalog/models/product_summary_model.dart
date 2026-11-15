import '../../../core/utils/safe_json_parser.dart';

/// Summary model for products displayed in lists, discovery feeds, and search results.
class ProductSummaryModel {
  final int id;
  final String productCode;
  final String title;
  final String slug;
  final String listingType;
  final String condition;
  final double price;
  final int availableQuantity;
  final int favoriteCount;
  final String status;
  final bool isFavorited;
  final bool isOwner;
  final String? primaryImageUrl;
  final String? primaryThumbnailUrl;
  final int? sellerId;
  final String? sellerDisplayName;
  final String? sellerAvatarUrl;
  final String? sellerShopSlug;
  final double? sellerTrustScore;
  final int? categoryId;
  final String? categoryName;
  final int? brandId;
  final String? brandName;
  final DateTime? approvedAt;

  const ProductSummaryModel({
    required this.id,
    required this.productCode,
    required this.title,
    required this.slug,
    required this.listingType,
    required this.condition,
    required this.price,
    this.availableQuantity = 1,
    this.favoriteCount = 0,
    required this.status,
    this.isFavorited = false,
    this.isOwner = false,
    this.primaryImageUrl,
    this.primaryThumbnailUrl,
    this.sellerId,
    this.sellerDisplayName,
    this.sellerAvatarUrl,
    this.sellerShopSlug,
    this.sellerTrustScore,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    this.approvedAt,
  });

  bool get isAuction => listingType.toUpperCase() == 'AUCTION';
  bool get isFixedPrice => listingType.toUpperCase() == 'FIXED_PRICE';
  String? get sellerName => sellerDisplayName;

  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    // Primary image parsing
    String? primaryImg;
    String? thumbImg;
    if (json['primary_image'] is Map) {
      final imgMap = json['primary_image'] as Map;
      primaryImg = SafeJsonParser.toNullableString(imgMap['image_url']);
      thumbImg = SafeJsonParser.toNullableString(imgMap['thumbnail_url']) ?? primaryImg;
    }

    // Seller parsing
    int? sId;
    String? sName;
    String? sAvatar;
    String? sShopSlug;
    double? sTrust;
    if (json['seller'] is Map) {
      final sMap = json['seller'] as Map;
      sId = SafeJsonParser.toNullableInt(sMap['id']);
      sName = SafeJsonParser.toNullableString(sMap['display_name']);
      sAvatar = SafeJsonParser.toNullableString(sMap['avatar_url']);
      sShopSlug = SafeJsonParser.toNullableString(sMap['shop_slug']);
      sTrust = SafeJsonParser.toNullableDouble(sMap['trust_score']);
    }

    // Category parsing
    int? catId;
    String? catName;
    if (json['category'] is Map) {
      final catMap = json['category'] as Map;
      catId = SafeJsonParser.toNullableInt(catMap['id']);
      catName = SafeJsonParser.toNullableString(catMap['name']);
    }

    // Brand parsing
    int? bId;
    String? bName;
    if (json['brand'] is Map) {
      final bMap = json['brand'] as Map;
      bId = SafeJsonParser.toNullableInt(bMap['id']);
      bName = SafeJsonParser.toNullableString(bMap['name']);
    }

    return ProductSummaryModel(
      id: SafeJsonParser.toInt(json['id']),
      productCode: SafeJsonParser.toStringValue(json['product_code']),
      title: SafeJsonParser.toStringValue(json['title']),
      slug: SafeJsonParser.toStringValue(json['slug']),
      listingType: SafeJsonParser.toStringValue(json['listing_type'], defaultValue: 'FIXED_PRICE'),
      condition: SafeJsonParser.toStringValue(json['condition'], defaultValue: 'GOOD'),
      price: SafeJsonParser.toDouble(json['price']),
      availableQuantity: SafeJsonParser.toInt(json['available_quantity'], defaultValue: 1),
      favoriteCount: SafeJsonParser.toInt(json['favorite_count'], defaultValue: 0),
      status: SafeJsonParser.toStringValue(json['status'], defaultValue: 'APPROVED'),
      isFavorited: SafeJsonParser.toBool(json['is_favorited'], defaultValue: false),
      isOwner: SafeJsonParser.toBool(json['is_owner'], defaultValue: false),
      primaryImageUrl: primaryImg,
      primaryThumbnailUrl: thumbImg,
      sellerId: sId,
      sellerDisplayName: sName,
      sellerAvatarUrl: sAvatar,
      sellerShopSlug: sShopSlug,
      sellerTrustScore: sTrust,
      categoryId: catId,
      categoryName: catName,
      brandId: bId,
      brandName: bName,
      approvedAt: SafeJsonParser.toNullableDateTime(json['approved_at']),
    );
  }

  ProductSummaryModel copyWith({
    int? id,
    String? productCode,
    String? title,
    String? slug,
    String? listingType,
    String? condition,
    double? price,
    int? availableQuantity,
    int? favoriteCount,
    String? status,
    bool? isFavorited,
    bool? isOwner,
    String? primaryImageUrl,
    String? primaryThumbnailUrl,
    int? sellerId,
    String? sellerDisplayName,
    String? sellerAvatarUrl,
    String? sellerShopSlug,
    double? sellerTrustScore,
    int? categoryId,
    String? categoryName,
    int? brandId,
    String? brandName,
    DateTime? approvedAt,
  }) {
    return ProductSummaryModel(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      listingType: listingType ?? this.listingType,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      status: status ?? this.status,
      isFavorited: isFavorited ?? this.isFavorited,
      isOwner: isOwner ?? this.isOwner,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      primaryThumbnailUrl: primaryThumbnailUrl ?? this.primaryThumbnailUrl,
      sellerId: sellerId ?? this.sellerId,
      sellerDisplayName: sellerDisplayName ?? this.sellerDisplayName,
      sellerAvatarUrl: sellerAvatarUrl ?? this.sellerAvatarUrl,
      sellerShopSlug: sellerShopSlug ?? this.sellerShopSlug,
      sellerTrustScore: sellerTrustScore ?? this.sellerTrustScore,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_code': productCode,
      'title': title,
      'slug': slug,
      'listing_type': listingType,
      'condition': condition,
      'price': price,
      'available_quantity': availableQuantity,
      'favorite_count': favoriteCount,
      'status': status,
      'is_favorited': isFavorited,
      'is_owner': isOwner,
      'primary_image': primaryImageUrl != null
          ? {
              'image_url': primaryImageUrl,
              'thumbnail_url': primaryThumbnailUrl ?? primaryImageUrl,
            }
          : null,
      'seller': sellerId != null
          ? {
              'id': sellerId,
              'display_name': sellerDisplayName,
              'avatar_url': sellerAvatarUrl,
              'shop_slug': sellerShopSlug,
              'trust_score': sellerTrustScore,
            }
          : null,
      'category': categoryId != null
          ? {
              'id': categoryId,
              'name': categoryName,
            }
          : null,
      'brand': brandId != null
          ? {
              'id': brandId,
              'name': brandName,
            }
          : null,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }
}
