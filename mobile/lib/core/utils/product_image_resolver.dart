/// Resolves authentic vintage product photography, condition freshness percentages,
/// compact category labels, and nearby distance labels across Retro Market (izithrift).
///
/// Priority order for product imagery:
/// 1. Real uploaded / custom product image URLs (from backend or user upload)
/// 2. Bundled local studio vintage photography assets under `assets/images/products/`
///    matched intelligently by product title, category, and deterministic ID.
class ProductImageResolver {
  ProductImageResolver._();

  static const String assetVarsityJacket =
      'assets/images/products/vintage_varsity_jacket.jpg';
  static const String assetKnitCardigan =
      'assets/images/products/vintage_knit_cardigan.jpg';
  static const String assetDenimJeans =
      'assets/images/products/vintage_denim_jeans.jpg';
  static const String assetLeatherBag =
      'assets/images/products/vintage_leather_bag.jpg';
  static const String assetRetroSneakers =
      'assets/images/products/vintage_retro_sneakers.jpg';
  static const String assetMechanicalWatch =
      'assets/images/products/vintage_mechanical_watch.jpg';
  static const String assetFilmCamera =
      'assets/images/products/vintage_film_camera.jpg';
  static const String assetFlannelShirt =
      'assets/images/products/vintage_flannel_shirt.jpg';

  static const List<String> allBundledAssets = [
    assetVarsityJacket,
    assetKnitCardigan,
    assetDenimJeans,
    assetLeatherBag,
    assetRetroSneakers,
    assetMechanicalWatch,
    assetFilmCamera,
    assetFlannelShirt,
  ];

  /// Curated demo photo choices for Seller Create Listing & Create Auction pickers
  /// when device gallery access is unavailable or for quick university demos.
  static const List<DemoPhotoOption> curatedDemoPhotos = [
    DemoPhotoOption(
      assetPath: assetVarsityJacket,
      label: 'Áo khoác Varsity 90s',
      categoryHint: 'Áo khoác',
    ),
    DemoPhotoOption(
      assetPath: assetKnitCardigan,
      label: 'Áo len Cardigan cổ điển',
      categoryHint: 'Áo len',
    ),
    DemoPhotoOption(
      assetPath: assetFlannelShirt,
      label: 'Sơ mi Flannel kẻ caro',
      categoryHint: 'Áo',
    ),
    DemoPhotoOption(
      assetPath: assetDenimJeans,
      label: 'Quần Jean Selvedge 90s',
      categoryHint: 'Quần',
    ),
    DemoPhotoOption(
      assetPath: assetRetroSneakers,
      label: 'Sneaker Retro da lộn',
      categoryHint: 'Giày',
    ),
    DemoPhotoOption(
      assetPath: assetLeatherBag,
      label: 'Túi đeo chéo da bò thật',
      categoryHint: 'Túi xách',
    ),
    DemoPhotoOption(
      assetPath: assetMechanicalWatch,
      label: 'Đồng hồ cơ cổ điển',
      categoryHint: 'Phụ kiện',
    ),
    DemoPhotoOption(
      assetPath: assetFilmCamera,
      label: 'Máy ảnh phim SLR cổ',
      categoryHint: 'Đồ cổ',
    ),
  ];

  /// Known generic/placeholder or duplicated seeder URLs that should be upgraded
  /// to item-specific vintage studio assets so every product has a distinct, relevant image.
  static bool isGenericOrBrokenUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return true;
    final lower = rawUrl.trim().toLowerCase();
    if (lower.contains('placeholder.jpg') ||
        lower.contains('izithrift.local') ||
        lower.contains('example.com') ||
        lower.contains('photo-1544441893-675973e31985') ||
        lower.contains('photo-1523381210434-271e8be1f52b') ||
        lower.contains('photo-1512436991641-6745cdb1723f')) {
      return true;
    }
    return false;
  }

  /// True when the resolved path points to a bundled Flutter local asset.
  static bool isLocalAsset(String path) => path.startsWith('assets/');

  /// Resolves the best display image (remote URL or bundled asset path) for any product/auction.
  static String resolveImage({
    String? rawUrl,
    String? title,
    String? categoryName,
    int id = 0,
  }) {
    if (!isGenericOrBrokenUrl(rawUrl)) {
      return rawUrl!.trim();
    }
    return fallbackAssetFor(
      title: title,
      categoryName: categoryName,
      id: id,
    );
  }

  /// Returns a curated local gallery (2–3 distinct related angles/assets) for detail screens
  /// when the backend only supplies placeholder images or a single image.
  static List<String> resolveGallery({
    required List<String> rawUrls,
    String? primaryUrl,
    String? title,
    String? categoryName,
    int id = 0,
  }) {
    final validRemote = <String>[];
    for (final url in rawUrls) {
      if (!isGenericOrBrokenUrl(url) && !validRemote.contains(url.trim())) {
        validRemote.add(url.trim());
      }
    }
    if (validRemote.isNotEmpty) {
      return validRemote;
    }
    if (!isGenericOrBrokenUrl(primaryUrl)) {
      return [primaryUrl!.trim()];
    }

    final primary = fallbackAssetFor(
      title: title,
      categoryName: categoryName,
      id: id,
    );
    return [primary];
  }

  /// Deterministically maps product title/category keywords to a matching vintage product photo.
  static String fallbackAssetFor({
    String? title,
    String? categoryName,
    int id = 0,
  }) {
    final text = '${title ?? ''} ${categoryName ?? ''}'.toLowerCase();

    if (_containsAny(text, ['máy ảnh', 'camera', 'canon', 'nikon', 'olympus', 'minolta', 'film', 'phim', 'điện tử'])) {
      return assetFilmCamera;
    }
    if (_containsAny(text, ['đồng hồ', 'watch', 'watches', 'seiko', 'omega', 'citizen', 'casio', 'phụ kiện', 'accessories', 'kính', 'nhẫn', 'dây chuyền', 'khăn'])) {
      return assetMechanicalWatch;
    }
    if (_containsAny(text, ['túi', 'ví', 'balo', 'cặp', 'bag', 'bags', 'leather bag', 'satchel', 'tote', 'coach', 'đồ da'])) {
      return assetLeatherBag;
    }
    if (_containsAny(text, ['giày', 'sneaker', 'sneakers', 'boot', 'dép', 'nike', 'adidas', 'converse', 'new balance', 'vans', 'puma', 'asics'])) {
      return assetRetroSneakers;
    }
    if (_containsAny(text, ['quần', 'jean', 'jeans', 'flare', 'trouser', 'trousers', 'levi', 'kaki', 'cargo', 'chinos', 'selvedge'])) {
      return assetDenimJeans;
    }
    if (_containsAny(text, ['len', 'cardigan', 'sweater', 'sweaters', 'nỉ', 'hoodie', 'knit', 'mohair', 'dệt kim', 'mùa đông'])) {
      return assetKnitCardigan;
    }
    if (_containsAny(text, ['flannel', 'sơ mi', 'caro', 'shirt', 'vintage shirt', 'american tee', 'boxy tee', 'tee', 'polo', 'thun'])) {
      return assetFlannelShirt;
    }
    if (_containsAny(text, ['denim jacket', 'khoác', 'outerwear', 'varsity', 'bomber', 'jacket', 'workwear', 'carhartt', 'măng tô', 'dạ', 'blazer', 'trucker'])) {
      return assetVarsityJacket;
    }

    final safeIdx = (id.abs()) % allBundledAssets.length;
    return allBundledAssets[safeIdx];
  }

  static bool _containsAny(String source, List<String> keywords) {
    for (final kw in keywords) {
      if (source.contains(kw)) return true;
    }
    return false;
  }

  /// Consistent frontend condition-to-freshness percentage mapping (presentation only).
  /// - NEW_WITH_TAGS → 100%
  /// - LIKE_NEW → 95%
  /// - GOOD → 85%
  /// - FAIR → 70%
  /// - VINTAGE_WORN → 60%
  static int conditionPercent(String rawCondition) {
    switch (rawCondition.toUpperCase()) {
      case 'NEW_WITH_TAGS':
        return 100;
      case 'LIKE_NEW':
        return 95;
      case 'GOOD':
        return 85;
      case 'FAIR':
        return 70;
      case 'VINTAGE_WORN':
        return 60;
      default:
        return 85;
    }
  }

  static String conditionPercentLabel(String rawCondition) =>
      '${conditionPercent(rawCondition)}%';

  /// Human-readable freshness format for product cards (e.g. "Độ mới: 95%").
  static String conditionFreshnessLabel(String rawCondition) =>
      'Độ mới: ${conditionPercent(rawCondition)}%';

  static String conditionDescription(String rawCondition) {
    switch (rawCondition.toUpperCase()) {
      case 'NEW_WITH_TAGS':
        return 'Mới 100%, còn nguyên tem mác chưa qua sử dụng';
      case 'LIKE_NEW':
        return 'Độ mới ~95%, đã mặc 1–2 lần, không lỗi đáng kể';
      case 'GOOD':
        return 'Độ mới ~85%, sử dụng ít, phom dáng và chất vải tốt';
      case 'FAIR':
        return 'Độ mới ~70%, có dấu hiệu sử dụng rõ, đã mô tả chi tiết';
      case 'VINTAGE_WORN':
        return 'Độ mới ~60%, màu fade & chất sờn vintage nguyên bản';
      default:
        return 'Đã kiểm tra kỹ tình trạng sản phẩm';
    }
  }

  /// Compact marketplace category pill text for 2-column grid & carousels.
  static String shortCategoryLabel(String? categoryName, {String? title}) {
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      final cleaned = categoryName.trim();
      if (cleaned.length <= 18) return cleaned;
      return cleaned.split('&').first.trim();
    }
    final text = (title ?? '').toLowerCase();
    if (_containsAny(text, ['máy ảnh', 'camera', 'canon', 'nikon', 'phim'])) {
      return 'Đồ cổ';
    }
    if (_containsAny(text, ['đồng hồ', 'watch', 'seiko', 'casio'])) {
      return 'Watches';
    }
    if (_containsAny(text, ['túi', 'ví', 'balo', 'bag', 'tote'])) {
      return 'Leather Bags';
    }
    if (_containsAny(text, ['giày', 'sneaker', 'boot'])) {
      return 'Sneakers';
    }
    if (_containsAny(text, ['flare', 'ống loe'])) {
      return 'Flare Jeans';
    }
    if (_containsAny(text, ['denim jacket', 'trucker', 'khoác jean'])) {
      return 'Denim Jacket';
    }
    if (_containsAny(text, ['boxy'])) {
      return 'Boxy Tee';
    }
    if (_containsAny(text, ['american tee', 'thun mỹ', 'band tee'])) {
      return 'American Tee';
    }
    if (_containsAny(text, ['quần âu', 'trouser', 'kaki', 'cargo'])) {
      return 'Trousers';
    }
    if (_containsAny(text, ['len', 'sweater', 'cardigan'])) {
      return 'Sweaters';
    }
    if (_containsAny(text, ['khoác', 'varsity', 'bomber', 'jacket', 'outerwear'])) {
      return 'Outerwear';
    }
    if (_containsAny(text, ['sơ mi', 'flannel', 'shirt'])) {
      return 'Vintage Shirt';
    }
    return 'Accessories';
  }

  /// Deterministic nearby distance (km) for demo display when GPS distance is absent.
  /// Easily replaceable with real backend `distance_km` when location services are wired.
  static String nearbyDistanceLabel({
    double? realDistanceKm,
    int productId = 0,
    int? sellerId,
  }) {
    if (realDistanceKm != null && realDistanceKm > 0) {
      return _formatKm(realDistanceKm);
    }
    const demoDistances = <double>[
      0.8,
      1.2,
      1.7,
      2.3,
      3.1,
      3.5,
      4.2,
      5.4,
      6.8,
      8.0,
    ];
    final seed = ((sellerId ?? 0) * 3 + productId).abs();
    return _formatKm(demoDistances[seed % demoDistances.length]);
  }

  static String _formatKm(double km) {
    if (km >= 8 && km == km.roundToDouble()) {
      return '${km.toInt()} km';
    }
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}

class DemoPhotoOption {
  final String assetPath;
  final String label;
  final String categoryHint;

  const DemoPhotoOption({
    required this.assetPath,
    required this.label,
    required this.categoryHint,
  });
}
