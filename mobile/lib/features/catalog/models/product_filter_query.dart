/// Immutable filter query object for product searches (M-DS-02, M-DS-03)
class ProductFilterQuery {
  final String? q;
  final int? categoryId;
  final int? brandId;
  final String? listingType;
  final String? condition;
  final String? verificationLevel;
  final double? minPrice;
  final double? maxPrice;
  final String? sort;
  final int page;
  final int perPage;

  const ProductFilterQuery({
    this.q,
    this.categoryId,
    this.brandId,
    this.listingType,
    this.condition,
    this.verificationLevel,
    this.minPrice,
    this.maxPrice,
    this.sort = 'newest',
    this.page = 1,
    this.perPage = 12,
  });

  /// Client-side price range validation: minPrice <= maxPrice
  bool get isPriceRangeValid {
    if (minPrice != null && maxPrice != null) {
      return minPrice! <= maxPrice!;
    }
    return true;
  }

  /// Check whether any non-keyword, non-sort filter is actively set
  bool get hasActiveFilters => activeFilterCount > 0;

  int get activeFilterCount {
    int count = 0;
    if (categoryId != null) count++;
    if (brandId != null) count++;
    if (listingType != null && listingType!.isNotEmpty) count++;
    if (condition != null && condition!.isNotEmpty) count++;
    if (verificationLevel != null && verificationLevel!.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    return count;
  }

  ProductFilterQuery copyWith({
    String? q,
    int? categoryId,
    int? brandId,
    String? listingType,
    String? condition,
    String? verificationLevel,
    double? minPrice,
    double? maxPrice,
    String? sort,
    int? page,
    int? perPage,
    bool clearQ = false,
    bool clearCategory = false,
    bool clearBrand = false,
    bool clearListingType = false,
    bool clearCondition = false,
    bool clearVerificationLevel = false,
    bool clearPriceRange = false,
  }) {
    return ProductFilterQuery(
      q: clearQ ? null : (q ?? this.q),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      brandId: clearBrand ? null : (brandId ?? this.brandId),
      listingType: clearListingType ? null : (listingType ?? this.listingType),
      condition: clearCondition ? null : (condition ?? this.condition),
      verificationLevel: clearVerificationLevel ? null : (verificationLevel ?? this.verificationLevel),
      minPrice: clearPriceRange ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPriceRange ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  /// Reset all filters back to default while keeping search keyword
  ProductFilterQuery resetFilters() {
    return ProductFilterQuery(
      q: q,
      page: 1,
      perPage: perPage,
      sort: 'newest',
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};

    if (q != null && q!.trim().isNotEmpty) {
      params['q'] = q!.trim();
    }
    if (categoryId != null) {
      params['category_id'] = categoryId;
    }
    if (brandId != null) {
      params['brand_id'] = brandId;
    }
    if (listingType != null && listingType!.isNotEmpty) {
      params['listing_type'] = listingType;
    }
    if (condition != null && condition!.isNotEmpty) {
      params['condition'] = condition;
    }
    if (verificationLevel != null && verificationLevel!.isNotEmpty) {
      params['verification_level'] = verificationLevel;
    }
    if (minPrice != null && minPrice! >= 0) {
      params['min_price'] = minPrice;
    }
    if (maxPrice != null && maxPrice! >= 0) {
      params['max_price'] = maxPrice;
    }
    if (sort != null && sort!.isNotEmpty) {
      params['sort'] = sort;
    }
    params['page'] = page;
    params['per_page'] = perPage;

    return params;
  }
}
