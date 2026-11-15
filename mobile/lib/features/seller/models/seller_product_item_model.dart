import '../../../core/utils/safe_json_parser.dart';

/// Model representing a product in the Seller Listings Manager (M-SL-02).
/// Supports 7 product statuses, 5 condition ratings, rejection reasons (DEC-05), and relist flags (DEC-02).
class SellerProductItemModel {
  final int id;
  final String productCode;
  final String title;
  final String slug;
  final double price;
  final String listingType;
  final String condition;
  final String? defectInfo;
  final String status;
  final int availableQuantity;
  final int totalQuantity;
  final String? primaryImageUrl;
  final String? rejectionReason;
  final bool canRelist;
  final int? categoryId;
  final String? categoryName;
  final int? brandId;
  final String? brandName;

  // Auction specific configuration
  final double? startingPrice;
  final double? bidIncrement;
  final double? reservePrice;
  final DateTime? auctionStartsAt;
  final DateTime? auctionEndsAt;

  const SellerProductItemModel({
    required this.id,
    required this.productCode,
    required this.title,
    required this.slug,
    required this.price,
    required this.listingType,
    required this.condition,
    this.defectInfo,
    required this.status,
    this.availableQuantity = 1,
    this.totalQuantity = 1,
    this.primaryImageUrl,
    this.rejectionReason,
    this.canRelist = false,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    this.startingPrice,
    this.bidIncrement,
    this.reservePrice,
    this.auctionStartsAt,
    this.auctionEndsAt,
  });

  factory SellerProductItemModel.fromJson(Map<String, dynamic> json) {
    String? imgUrl = SafeJsonParser.toNullableString(json['primary_image_url'] ?? json['image_url']);
    if (imgUrl == null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      final first = (json['images'] as List).first;
      if (first is Map<String, dynamic>) {
        imgUrl = SafeJsonParser.toNullableString(first['image_url']);
      }
    }

    int? catId = SafeJsonParser.toNullableInt(json['category_id']);
    String? catName = SafeJsonParser.toNullableString(json['category_name']);
    if (json['category'] is Map<String, dynamic>) {
      final cat = json['category'] as Map<String, dynamic>;
      catId ??= SafeJsonParser.toNullableInt(cat['id']);
      catName ??= SafeJsonParser.toNullableString(cat['name']);
    }

    int? bId = SafeJsonParser.toNullableInt(json['brand_id']);
    String? bName = SafeJsonParser.toNullableString(json['brand_name']);
    if (json['brand'] is Map<String, dynamic>) {
      final b = json['brand'] as Map<String, dynamic>;
      bId ??= SafeJsonParser.toNullableInt(b['id']);
      bName ??= SafeJsonParser.toNullableString(b['name']);
    }

    // Check auction info
    double? startPrice = SafeJsonParser.toNullableDouble(json['starting_price']);
    double? increment = SafeJsonParser.toNullableDouble(json['min_bid_increment'] ?? json['bid_increment']);
    double? reserve = SafeJsonParser.toNullableDouble(json['reserve_price']);
    DateTime? aStarts = SafeJsonParser.toNullableDateTime(json['auction_starts_at']);
    DateTime? aEnds = SafeJsonParser.toNullableDateTime(json['auction_ends_at']);

    if (json['active_auction'] is Map<String, dynamic>) {
      final auc = json['active_auction'] as Map<String, dynamic>;
      startPrice ??= SafeJsonParser.toNullableDouble(auc['starting_price']);
      increment ??= SafeJsonParser.toNullableDouble(auc['min_bid_increment']);
      reserve ??= SafeJsonParser.toNullableDouble(auc['reserve_price']);
      aStarts ??= SafeJsonParser.toNullableDateTime(auc['starts_at'] ?? auc['auction_starts_at']);
      aEnds ??= SafeJsonParser.toNullableDateTime(auc['ends_at'] ?? auc['auction_ends_at']);
    }

    final rawStatus = SafeJsonParser.toStringValue(json['status'], defaultValue: 'DRAFT').toUpperCase();
    final bool relistable = SafeJsonParser.toBool(
      json['can_relist'] ?? (rawStatus == 'AUCTION_ENDED' || (rawStatus == 'REJECTED' && json['listing_type'] == 'AUCTION')),
    );

    return SellerProductItemModel(
      id: SafeJsonParser.toInt(json['id']),
      productCode: SafeJsonParser.toStringValue(json['product_code'], defaultValue: 'PRD-${json['id']}'),
      title: SafeJsonParser.toStringValue(json['title'], defaultValue: 'Sản phẩm vintage'),
      slug: SafeJsonParser.toStringValue(json['slug']),
      price: SafeJsonParser.toDouble(json['price']),
      listingType: SafeJsonParser.toStringValue(json['listing_type'], defaultValue: 'FIXED_PRICE'),
      condition: SafeJsonParser.toStringValue(json['condition'], defaultValue: 'GOOD'),
      defectInfo: SafeJsonParser.toNullableString(json['defect_info']),
      status: rawStatus,
      availableQuantity: SafeJsonParser.toInt(json['available_quantity'], defaultValue: 1),
      totalQuantity: SafeJsonParser.toInt(json['total_quantity'], defaultValue: 1),
      primaryImageUrl: imgUrl,
      rejectionReason: SafeJsonParser.toNullableString(json['rejection_reason']),
      canRelist: relistable,
      categoryId: catId,
      categoryName: catName,
      brandId: bId,
      brandName: bName,
      startingPrice: startPrice,
      bidIncrement: increment,
      reservePrice: reserve,
      auctionStartsAt: aStarts,
      auctionEndsAt: aEnds,
    );
  }

  SellerProductItemModel copyWith({
    String? status,
    String? rejectionReason,
    bool? canRelist,
    int? availableQuantity,
  }) {
    return SellerProductItemModel(
      id: id,
      productCode: productCode,
      title: title,
      slug: slug,
      price: price,
      listingType: listingType,
      condition: condition,
      defectInfo: defectInfo,
      status: status ?? this.status,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      totalQuantity: totalQuantity,
      primaryImageUrl: primaryImageUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      canRelist: canRelist ?? this.canRelist,
      categoryId: categoryId,
      categoryName: categoryName,
      brandId: brandId,
      brandName: brandName,
      startingPrice: startingPrice,
      bidIncrement: bidIncrement,
      reservePrice: reservePrice,
      auctionStartsAt: auctionStartsAt,
      auctionEndsAt: auctionEndsAt,
    );
  }
}
