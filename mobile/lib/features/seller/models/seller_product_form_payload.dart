/// Payload object packaging data for creating (M-SL-03) or updating/resubmitting (M-SL-04) a listing.
/// Enforces BR-PR-01 (Auction quantity locked to 1), BR-PR-03 (Mandatory defect info >= 5 chars, 5 conditions),
/// and NFR-SEC-03 (Max 10 images).
class SellerProductFormPayload {
  final String title;
  final String? description;
  final int categoryId;
  final int? brandId;
  final String listingType; // FIXED_PRICE / AUCTION
  final double price;
  final int availableQuantity;
  final String condition;
  final String defectInfo;
  final List<String> imageUrls;
  final bool submitForReview;

  // Auction specific
  final double? startingPrice;
  final double? minBidIncrement;
  final double? reservePrice;
  final DateTime? auctionStartsAt;
  final DateTime? auctionEndsAt;

  const SellerProductFormPayload({
    required this.title,
    this.description,
    required this.categoryId,
    this.brandId,
    this.listingType = 'FIXED_PRICE',
    required this.price,
    this.availableQuantity = 1,
    required this.condition,
    required this.defectInfo,
    this.imageUrls = const [],
    this.submitForReview = true,
    this.startingPrice,
    this.minBidIncrement,
    this.reservePrice,
    this.auctionStartsAt,
    this.auctionEndsAt,
  });

  /// Client-side validation ensuring strict adherence to Retro Market business rules.
  String? validate() {
    if (title.trim().length < 5) {
      return 'Tiêu đề sản phẩm phải có ít nhất 5 ký tự.';
    }
    if (categoryId <= 0) {
      return 'Vui lòng chọn danh mục cho sản phẩm.';
    }
    if (price <= 0) {
      return 'Giá bán sản phẩm phải lớn hơn 0 VNĐ.';
    }

    const validConditions = ['NEW_WITH_TAGS', 'LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN'];
    if (!validConditions.contains(condition.toUpperCase())) {
      return 'Tình trạng sản phẩm không hợp lệ (hỗ trợ 5 mức độ mới).';
    }

    // BR-PR-03: Mandatory defect info with minimum 5 non-whitespace characters
    if (defectInfo.trim().length < 5) {
      return 'Mô tả khuyết điểm là bắt buộc và phải có ít nhất 5 ký tự (BR-PR-03).';
    }

    if (imageUrls.length > 10) {
      return 'Tối đa chỉ được tải lên 10 hình ảnh cho mỗi sản phẩm.';
    }

    // BR-PR-01: Auction constraints
    if (listingType.toUpperCase() == 'AUCTION') {
      if (availableQuantity != 1) {
        return 'Sản phẩm đấu giá bắt buộc phải có số lượng bằng 1 (BR-PR-01).';
      }
      if (startingPrice == null || startingPrice! <= 0) {
        return 'Vui lòng nhập giá khởi điểm hợp lệ cho phiên đấu giá.';
      }
      if (minBidIncrement == null || minBidIncrement! <= 0) {
        return 'Vui lòng nhập bước giá tối thiểu cho phiên đấu giá.';
      }
      if (reservePrice != null && reservePrice! < startingPrice!) {
        return 'Giá bảo lưu không được nhỏ hơn giá khởi điểm.';
      }
      if (auctionStartsAt != null && auctionEndsAt != null && !auctionEndsAt!.isAfter(auctionStartsAt!)) {
        return 'Thời gian kết thúc phiên phải sau thời gian bắt đầu.';
      }
    }

    return null; // Valid
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'category_id': categoryId,
      'listing_type': listingType,
      'price': price,
      'total_quantity': listingType.toUpperCase() == 'AUCTION' ? 1 : availableQuantity,
      'available_quantity': listingType.toUpperCase() == 'AUCTION' ? 1 : availableQuantity,
      'condition': condition.toUpperCase(),
      'defect_info': defectInfo.trim(),
      'submit_for_review': submitForReview,
    };

    if (description != null && description!.trim().isNotEmpty) {
      map['description'] = description!.trim();
    }
    if (brandId != null && brandId! > 0) {
      map['brand_id'] = brandId;
    }
    if (imageUrls.isNotEmpty) {
      map['image_urls'] = imageUrls;
    }

    if (listingType.toUpperCase() == 'AUCTION') {
      if (startingPrice != null) map['starting_price'] = startingPrice;
      if (minBidIncrement != null) map['min_bid_increment'] = minBidIncrement;
      if (reservePrice != null) map['reserve_price'] = reservePrice;
      if (auctionStartsAt != null) map['auction_starts_at'] = auctionStartsAt!.toIso8601String();
      if (auctionEndsAt != null) map['auction_ends_at'] = auctionEndsAt!.toIso8601String();
    }

    return map;
  }
}
