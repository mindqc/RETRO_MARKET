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
  final String? sellerShopName;
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
    this.sellerShopName,
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

  /// True when a string looks like a raw technical identifier or username slug
  /// (e.g. `prd_d95a1879`, `PRD-2026-0001`, `seller_a1b2c3`, `usr_99`).
  static bool isTechnicalIdentifier(String? raw) {
    if (raw == null) return true;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return true;
    final techPattern = RegExp(
      r'^(prd|prod|item|seller|usr|user|shop)[_-][a-z0-9_-]+$',
      caseSensitive: false,
    );
    if (techPattern.hasMatch(trimmed)) return true;
    // Also catch code-like tokens with no spaces and underscores + hex/digits (e.g. `d95a1879_test`)
    if (!trimmed.contains(' ') &&
        trimmed.contains('_') &&
        RegExp(r'^[a-z0-9_.-]+$', caseSensitive: false).hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  /// Human-readable product title for UI cards (falls back cleanly if raw code).
  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty && !isTechnicalIdentifier(trimmed)) {
      return trimmed;
    }
    final cleanBrand = brandName?.trim() ?? '';
    final cleanCat = categoryName?.trim() ?? '';
    if (cleanCat.isNotEmpty && cleanBrand.isNotEmpty) {
      return '$cleanCat $cleanBrand';
    }
    if (cleanCat.isNotEmpty) {
      return 'Đồ si $cleanCat';
    }
    return 'Sản phẩm vintage tuyển chọn';
  }

  /// Prioritizes real shop name (`shop_name` / `seller_profile.shop_name`) then
  /// `display_name`, avoiding raw technical usernames/slugs (`seller_...`).
  String? get displaySellerName {
    final shop = sellerShopName?.trim();
    if (shop != null && shop.isNotEmpty && !isTechnicalIdentifier(shop)) {
      return shop;
    }
    final display = sellerDisplayName?.trim();
    if (display != null &&
        display.isNotEmpty &&
        !isTechnicalIdentifier(display)) {
      return display;
    }
    final slug = sellerShopSlug?.trim();
    if (slug != null && slug.isNotEmpty && !isTechnicalIdentifier(slug)) {
      final words = slug
          .split(RegExp(r'[-_]+'))
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
      if (words.isNotEmpty) return words;
    }
    final hasAnySellerRef = sellerId != null ||
        (shop != null && shop.isNotEmpty) ||
        (display != null && display.isNotEmpty) ||
        (slug != null && slug.isNotEmpty);
    return hasAnySellerRef ? 'Tiệm đồ si uy tín' : null;
  }

  String? get sellerName => displaySellerName;

  static String? _extractImageUrlFromDynamic(dynamic raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (raw is Map) {
      return SafeJsonParser.toNullableString(
        raw['image_url'] ?? raw['url'] ?? raw['path'] ?? raw['thumbnail_url'],
      );
    }
    return null;
  }

  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    // Primary image parsing: primary_image (Map or String) -> primary_image_url -> images.first
    String? primaryImg;
    String? thumbImg;
    final rawPrimary = json['primary_image'];
    if (rawPrimary is Map) {
      primaryImg = SafeJsonParser.toNullableString(
        rawPrimary['image_url'] ?? rawPrimary['url'] ?? rawPrimary['path'],
      );
      thumbImg = SafeJsonParser.toNullableString(rawPrimary['thumbnail_url']) ??
          primaryImg;
    } else if (rawPrimary is String && rawPrimary.trim().isNotEmpty) {
      primaryImg = rawPrimary.trim();
      thumbImg = primaryImg;
    }

    primaryImg ??= SafeJsonParser.toNullableString(
      json['primary_image_url'] ?? json['image_url'],
    );
    thumbImg ??= SafeJsonParser.toNullableString(json['thumbnail_url']) ??
        primaryImg;

    if ((primaryImg == null || primaryImg.trim().isEmpty) &&
        json['images'] is List) {
      final rawImages = json['images'] as List;
      Map? chosenMap;
      String? chosenUrl;
      for (final item in rawImages) {
        if (item is Map &&
            SafeJsonParser.toBool(item['is_primary'], defaultValue: false)) {
          final candidate = _extractImageUrlFromDynamic(item);
          if (candidate != null) {
            chosenMap = item;
            chosenUrl = candidate;
            break;
          }
        }
      }
      if (chosenUrl == null) {
        for (final item in rawImages) {
          final candidate = _extractImageUrlFromDynamic(item);
          if (candidate != null) {
            if (item is Map) chosenMap = item;
            chosenUrl = candidate;
            break;
          }
        }
      }
      if (chosenUrl != null) {
        primaryImg = chosenUrl;
        thumbImg = chosenMap != null
            ? (SafeJsonParser.toNullableString(chosenMap['thumbnail_url']) ??
                chosenUrl)
            : chosenUrl;
      }
    }

    // Seller parsing (prioritizing shop_name / seller_profile.shop_name -> display_name)
    int? sId;
    String? sShopName;
    String? sName;
    String? sAvatar;
    String? sShopSlug;
    double? sTrust;
    if (json['seller'] is Map) {
      final sMap = json['seller'] as Map;
      final sellerProfile = sMap['seller_profile'] is Map
          ? sMap['seller_profile'] as Map
          : null;
      final userProfile =
          sMap['profile'] is Map ? sMap['profile'] as Map : null;

      sId = SafeJsonParser.toNullableInt(sMap['id']);
      sShopName = SafeJsonParser.toNullableString(
        sMap['shop_name'] ??
            sellerProfile?['shop_name'] ??
            userProfile?['shop_name'],
      );
      sName = SafeJsonParser.toNullableString(
        sMap['display_name'] ?? sMap['full_name'] ?? sMap['name'],
      );
      sAvatar = SafeJsonParser.toNullableString(
        sMap['avatar_url'] ?? userProfile?['avatar_url'],
      );
      sShopSlug = SafeJsonParser.toNullableString(
        sMap['shop_slug'] ?? sellerProfile?['shop_slug'],
      );
      sTrust = SafeJsonParser.toNullableDouble(
        sMap['trust_score'] ?? sellerProfile?['trust_score'],
      );
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
      listingType: SafeJsonParser.toStringValue(
        json['listing_type'],
        defaultValue: 'FIXED_PRICE',
      ),
      condition: SafeJsonParser.toStringValue(
        json['condition'],
        defaultValue: 'GOOD',
      ),
      price: SafeJsonParser.toDouble(json['price']),
      availableQuantity: SafeJsonParser.toInt(
        json['available_quantity'],
        defaultValue: 1,
      ),
      favoriteCount: SafeJsonParser.toInt(
        json['favorite_count'],
        defaultValue: 0,
      ),
      status: SafeJsonParser.toStringValue(
        json['status'],
        defaultValue: 'APPROVED',
      ),
      isFavorited: SafeJsonParser.toBool(
        json['is_favorited'],
        defaultValue: false,
      ),
      isOwner: SafeJsonParser.toBool(json['is_owner'], defaultValue: false),
      primaryImageUrl: primaryImg,
      primaryThumbnailUrl: thumbImg,
      sellerId: sId,
      sellerShopName: sShopName,
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
    String? sellerShopName,
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
      sellerShopName: sellerShopName ?? this.sellerShopName,
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
              'shop_name': sellerShopName,
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
