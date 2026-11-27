import '../../../core/utils/safe_json_parser.dart';
import 'product_image_model.dart';
import 'product_summary_model.dart';

/// Seller information snapshot attached to product detail.
class ProductSellerInfo {
  final int id;
  final String displayName;
  final String? shopName;
  final String? avatarUrl;
  final String? shopSlug;
  final double trustScore;
  final double averageRating;
  final int completedOrdersCount;

  const ProductSellerInfo({
    required this.id,
    required this.displayName,
    this.shopName,
    this.avatarUrl,
    this.shopSlug,
    this.trustScore = 100.0,
    this.averageRating = 5.0,
    this.completedOrdersCount = 0,
  });

  /// Prioritizes real shop name (`shop_name` / `seller_profile.shop_name`) over
  /// `display_name`, avoiding raw technical usernames/slugs (`seller_...`).
  String get displayShopName {
    final shop = shopName?.trim();
    if (shop != null &&
        shop.isNotEmpty &&
        !ProductSummaryModel.isTechnicalIdentifier(shop)) {
      return shop;
    }
    final display = displayName.trim();
    if (display.isNotEmpty &&
        !ProductSummaryModel.isTechnicalIdentifier(display)) {
      return display;
    }
    final slug = shopSlug?.trim();
    if (slug != null &&
        slug.isNotEmpty &&
        !ProductSummaryModel.isTechnicalIdentifier(slug)) {
      final words = slug
          .split(RegExp(r'[-_]+'))
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
      if (words.isNotEmpty) return words;
    }
    return 'Tiệm đồ si uy tín';
  }

  factory ProductSellerInfo.fromJson(Map<String, dynamic> json) {
    final sellerProfile =
        json['seller_profile'] is Map ? json['seller_profile'] as Map : null;
    final userProfile = json['profile'] is Map ? json['profile'] as Map : null;

    return ProductSellerInfo(
      id: SafeJsonParser.toInt(json['id']),
      displayName: SafeJsonParser.toStringValue(
        json['display_name'] ?? json['full_name'] ?? json['name'],
        defaultValue: 'Tiệm đồ si uy tín',
      ),
      shopName: SafeJsonParser.toNullableString(
        json['shop_name'] ??
            sellerProfile?['shop_name'] ??
            userProfile?['shop_name'],
      ),
      avatarUrl: SafeJsonParser.toNullableString(
        json['avatar_url'] ?? userProfile?['avatar_url'],
      ),
      shopSlug: SafeJsonParser.toNullableString(
        json['shop_slug'] ?? sellerProfile?['shop_slug'],
      ),
      trustScore: SafeJsonParser.toDouble(
        json['trust_score'] ?? sellerProfile?['trust_score'],
        defaultValue: 100.0,
      ),
      averageRating: SafeJsonParser.toDouble(
        json['average_rating'] ?? sellerProfile?['average_rating'],
        defaultValue: 5.0,
      ),
      completedOrdersCount: SafeJsonParser.toInt(
        json['completed_orders_count'] ??
            sellerProfile?['completed_orders_count'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'shop_name': shopName,
      'avatar_url': avatarUrl,
      'shop_slug': shopSlug,
      'trust_score': trustScore,
      'average_rating': averageRating,
      'completed_orders_count': completedOrdersCount,
    };
  }
}

/// Category brief for product detail.
class ProductCategoryBrief {
  final int id;
  final String name;
  final String? slug;

  const ProductCategoryBrief({
    required this.id,
    required this.name,
    this.slug,
  });

  factory ProductCategoryBrief.fromJson(Map<String, dynamic> json) {
    return ProductCategoryBrief(
      id: SafeJsonParser.toInt(json['id']),
      name: SafeJsonParser.toStringValue(json['name'], defaultValue: 'Đồ Vintage'),
      slug: SafeJsonParser.toNullableString(json['slug']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

/// Brand brief for product detail.
class ProductBrandBrief {
  final int id;
  final String name;
  final String? slug;
  final String? logoUrl;

  const ProductBrandBrief({
    required this.id,
    required this.name,
    this.slug,
    this.logoUrl,
  });

  factory ProductBrandBrief.fromJson(Map<String, dynamic> json) {
    return ProductBrandBrief(
      id: SafeJsonParser.toInt(json['id']),
      name: SafeJsonParser.toStringValue(json['name']),
      slug: SafeJsonParser.toNullableString(json['slug']),
      logoUrl: SafeJsonParser.toNullableString(json['logo_url']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug, 'logo_url': logoUrl};
}

/// Active auction info for auction-type products.
class ProductActiveAuctionInfo {
  final int id;
  final double startingPrice;
  final double currentHighestBid;
  final int bidCount;
  final DateTime? auctionEndsAt;
  final String status;

  const ProductActiveAuctionInfo({
    required this.id,
    required this.startingPrice,
    required this.currentHighestBid,
    this.bidCount = 0,
    this.auctionEndsAt,
    this.status = 'LIVE',
  });

  factory ProductActiveAuctionInfo.fromJson(Map<String, dynamic> json) {
    final startPrice = SafeJsonParser.toDouble(json['starting_price']);
    return ProductActiveAuctionInfo(
      id: SafeJsonParser.toInt(json['id']),
      startingPrice: startPrice,
      currentHighestBid: SafeJsonParser.toDouble(json['current_highest_bid'], defaultValue: startPrice),
      bidCount: SafeJsonParser.toInt(json['bid_count']),
      auctionEndsAt: SafeJsonParser.toNullableDateTime(json['auction_ends_at']),
      status: SafeJsonParser.toStringValue(json['status'], defaultValue: 'LIVE'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'starting_price': startingPrice,
      'current_highest_bid': currentHighestBid,
      'bid_count': bidCount,
      'auction_ends_at': auctionEndsAt?.toIso8601String(),
      'status': status,
    };
  }
}

/// Full product detail model matching Laravel ProductDetailResource.
class ProductDetailModel {
  final int id;
  final String productCode;
  final String title;
  final String slug;
  final String description;
  final double price;
  final double buyerProtectionFee;
  final double totalBuyerPayable;
  final String listingType;
  final String condition;
  final String? conditionDescription;
  final String? defectInfo;
  final String verificationLevel;
  final String status;
  final String? rejectionReason;
  final int totalQuantity;
  final int availableQuantity;
  final int favoriteCount;
  final String primaryImageUrl;
  final List<ProductImageModel> images;
  final ProductSellerInfo? seller;
  final ProductCategoryBrief? category;
  final ProductBrandBrief? brand;
  final ProductActiveAuctionInfo? activeAuction;
  final bool isOwner;
  final bool isFavorited;
  final List<ProductSummaryModel> relatedProducts;
  final String? size;
  final String? shirtLength;
  final String? chestWidth;
  final String? pantsLength;
  final String? legOpening;
  final String? material;

  const ProductDetailModel({
    required this.id,
    required this.productCode,
    required this.title,
    required this.slug,
    required this.description,
    required this.price,
    required this.buyerProtectionFee,
    required this.totalBuyerPayable,
    required this.listingType,
    required this.condition,
    this.conditionDescription,
    this.defectInfo,
    required this.verificationLevel,
    required this.status,
    this.rejectionReason,
    this.totalQuantity = 1,
    this.availableQuantity = 1,
    this.favoriteCount = 0,
    required this.primaryImageUrl,
    this.images = const [],
    this.seller,
    this.category,
    this.brand,
    this.activeAuction,
    this.isOwner = false,
    this.isFavorited = false,
    this.relatedProducts = const [],
    this.size,
    this.shirtLength,
    this.chestWidth,
    this.pantsLength,
    this.legOpening,
    this.material,
  });

  /// Human-readable product title avoiding raw technical codes like `prd_...`.
  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty &&
        !ProductSummaryModel.isTechnicalIdentifier(trimmed)) {
      return trimmed;
    }
    final cleanBrand = brand?.name.trim() ?? '';
    final cleanCat = category?.name.trim() ?? '';
    if (cleanCat.isNotEmpty && cleanBrand.isNotEmpty) {
      return '$cleanCat $cleanBrand';
    }
    if (cleanCat.isNotEmpty) {
      return 'Đồ si $cleanCat';
    }
    return 'Sản phẩm vintage tuyển chọn';
  }

  /// Factory parser supporting both top-level envelopes and raw product maps.
  factory ProductDetailModel.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> data = (rawJson['product'] is Map<String, dynamic>)
        ? rawJson['product'] as Map<String, dynamic>
        : rawJson;

    final double parsedPrice = SafeJsonParser.toDouble(data['price']);
    final double protectionFee = SafeJsonParser.toDouble(
      data['buyer_protection_fee'],
      defaultValue: (parsedPrice > 0 ? (parsedPrice * 0.06 + 7000).round().toDouble() : 0.0),
    );
    final double totalPayable = SafeJsonParser.toDouble(
      data['total_buyer_payable'],
      defaultValue: parsedPrice + protectionFee,
    );

    // Parse image list
    final List<ProductImageModel> parsedImages = [];
    if (data['images'] is List) {
      for (final img in (data['images'] as List)) {
        if (img is Map<String, dynamic>) {
          parsedImages.add(ProductImageModel.fromJson(img));
        } else if (img is Map) {
          parsedImages.add(
            ProductImageModel.fromJson(Map<String, dynamic>.from(img)),
          );
        }
      }
    }

    // Determine primary image (primary_image -> primary_image_url/image_url -> images.first)
    String primaryUrl = '';
    final rawPrimary = data['primary_image'];
    if (rawPrimary is Map) {
      primaryUrl = SafeJsonParser.toStringValue(
        rawPrimary['image_url'] ?? rawPrimary['url'] ?? rawPrimary['path'],
      );
    } else if (rawPrimary is String) {
      primaryUrl = rawPrimary.trim();
    }
    if (primaryUrl.isEmpty) {
      primaryUrl = SafeJsonParser.toStringValue(
        data['primary_image_url'] ?? data['image_url'],
      );
    }
    if (primaryUrl.isEmpty && parsedImages.isNotEmpty) {
      final primary = parsedImages.firstWhere(
        (img) => img.isPrimary,
        orElse: () => parsedImages.first,
      );
      primaryUrl = primary.imageUrl;
    }

    // Related products if present in envelope
    final List<ProductSummaryModel> parsedRelated = [];
    final relatedRaw = rawJson['related_products'] ?? data['related_products'];
    if (relatedRaw is List) {
      for (final rel in relatedRaw) {
        if (rel is Map<String, dynamic>) {
          parsedRelated.add(ProductSummaryModel.fromJson(rel));
        }
      }
    }

    final bool isOwnerValue = SafeJsonParser.toBool(rawJson['is_owner'] ?? data['is_owner']);
    final bool isFavoritedValue = SafeJsonParser.toBool(rawJson['is_favorited'] ?? data['is_favorited']);

    final specMap = data['specifications'] is Map
        ? data['specifications'] as Map
        : (data['measurements'] is Map ? data['measurements'] as Map : null);

    return ProductDetailModel(
      id: SafeJsonParser.toInt(data['id']),
      productCode: SafeJsonParser.toStringValue(data['product_code'], defaultValue: 'PRD-${data['id']}'),
      title: SafeJsonParser.toStringValue(data['title'], defaultValue: 'Sản phẩm Vintage'),
      slug: SafeJsonParser.toStringValue(data['slug']),
      description: SafeJsonParser.toStringValue(data['description']),
      price: parsedPrice,
      buyerProtectionFee: protectionFee,
      totalBuyerPayable: totalPayable,
      listingType: SafeJsonParser.toStringValue(data['listing_type'], defaultValue: 'FIXED_PRICE'),
      condition: SafeJsonParser.toStringValue(data['condition'], defaultValue: 'GOOD'),
      conditionDescription: SafeJsonParser.toNullableString(data['condition_description']),
      defectInfo: SafeJsonParser.toNullableString(data['defect_info']),
      verificationLevel: SafeJsonParser.toStringValue(data['verification_level'], defaultValue: 'UNVERIFIED'),
      status: SafeJsonParser.toStringValue(data['status'], defaultValue: 'APPROVED'),
      rejectionReason: SafeJsonParser.toNullableString(data['rejection_reason']),
      totalQuantity: SafeJsonParser.toInt(data['total_quantity'], defaultValue: 1),
      availableQuantity: SafeJsonParser.toInt(data['available_quantity'], defaultValue: 1),
      favoriteCount: SafeJsonParser.toInt(data['favorite_count']),
      primaryImageUrl: primaryUrl,
      images: parsedImages,
      seller: data['seller'] is Map<String, dynamic>
          ? ProductSellerInfo.fromJson(data['seller'] as Map<String, dynamic>)
          : null,
      category: data['category'] is Map<String, dynamic>
          ? ProductCategoryBrief.fromJson(data['category'] as Map<String, dynamic>)
          : null,
      brand: data['brand'] is Map<String, dynamic>
          ? ProductBrandBrief.fromJson(data['brand'] as Map<String, dynamic>)
          : null,
      activeAuction: data['active_auction'] is Map<String, dynamic>
          ? ProductActiveAuctionInfo.fromJson(data['active_auction'] as Map<String, dynamic>)
          : null,
      isOwner: isOwnerValue,
      isFavorited: isFavoritedValue,
      relatedProducts: parsedRelated,
      size: SafeJsonParser.toNullableString(
        data['size'] ?? specMap?['size'],
      ),
      shirtLength: SafeJsonParser.toNullableString(
        data['shirt_length'] ?? specMap?['shirt_length'],
      ),
      chestWidth: SafeJsonParser.toNullableString(
        data['chest_width'] ?? specMap?['chest_width'],
      ),
      pantsLength: SafeJsonParser.toNullableString(
        data['pants_length'] ?? specMap?['pants_length'],
      ),
      legOpening: SafeJsonParser.toNullableString(
        data['leg_opening'] ?? specMap?['leg_opening'],
      ),
      material: SafeJsonParser.toNullableString(
        data['material'] ?? specMap?['material'],
      ),
    );
  }

  ProductDetailModel copyWith({
    bool? isFavorited,
    int? favoriteCount,
    bool? isOwner,
    int? availableQuantity,
  }) {
    return ProductDetailModel(
      id: id,
      productCode: productCode,
      title: title,
      slug: slug,
      description: description,
      price: price,
      buyerProtectionFee: buyerProtectionFee,
      totalBuyerPayable: totalBuyerPayable,
      listingType: listingType,
      condition: condition,
      conditionDescription: conditionDescription,
      defectInfo: defectInfo,
      verificationLevel: verificationLevel,
      status: status,
      rejectionReason: rejectionReason,
      totalQuantity: totalQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      primaryImageUrl: primaryImageUrl,
      images: images,
      seller: seller,
      category: category,
      brand: brand,
      activeAuction: activeAuction,
      isOwner: isOwner ?? this.isOwner,
      isFavorited: isFavorited ?? this.isFavorited,
      relatedProducts: relatedProducts,
      size: size,
      shirtLength: shirtLength,
      chestWidth: chestWidth,
      pantsLength: pantsLength,
      legOpening: legOpening,
      material: material,
    );
  }
}
