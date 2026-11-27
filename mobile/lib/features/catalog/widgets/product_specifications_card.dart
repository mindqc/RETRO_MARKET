import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/product_detail_model.dart';

/// Key-value specification item rendered inside [ProductSpecificationsCard].
class ProductSpecItem {
  final String label;
  final String value;
  final IconData icon;

  const ProductSpecItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// Compact editorial card displaying product size, measurements, and material
/// specifications for vintage secondhand items.
///
/// Uses explicit fields from [ProductDetailModel] when present, parses details
/// from title/description when available, and derives sensible category-matched
/// defaults so buyers always see relevant sizing and material context.
class ProductSpecificationsCard extends StatelessWidget {
  final ProductDetailModel product;

  const ProductSpecificationsCard({
    super.key,
    required this.product,
  });

  /// Resolves clean, non-empty specification rows tailored to the product type.
  static List<ProductSpecItem> resolveSpecs(ProductDetailModel product) {
    final specs = <ProductSpecItem>[];
    final combinedText =
        '${product.displayTitle} ${product.description} ${product.category?.name ?? ''}'
            .toLowerCase();

    final bool isBottom = _containsAny(combinedText, [
      'quần',
      'jean',
      'jeans',
      'flare',
      'trouser',
      'trousers',
      'kaki',
      'cargo',
      'chinos',
      'selvedge',
      'chân váy',
      'váy',
    ]);
    final bool isTop = !isBottom &&
        _containsAny(combinedText, [
          'áo',
          'jacket',
          'bomber',
          'varsity',
          'trucker',
          'măng tô',
          'blazer',
          'cardigan',
          'sweater',
          'hoodie',
          'flannel',
          'sơ mi',
          'shirt',
          'tee',
          'polo',
          'outerwear',
          'dạ',
        ]);
    final bool isFootwear = _containsAny(combinedText, [
      'giày',
      'sneaker',
      'sneakers',
      'boot',
      'bốt',
      'dr. martens',
      'dép',
    ]);

    // 1. Size
    final String? resolvedSize = _nonEmpty(product.size) ??
        _extractSizeFromText(combinedText) ??
        _defaultSize(
          productId: product.id,
          isTop: isTop,
          isBottom: isBottom,
          isFootwear: isFootwear,
        );
    if (resolvedSize != null) {
      specs.add(
        ProductSpecItem(
          label: 'Size',
          value: resolvedSize,
          icon: Icons.straighten_rounded,
        ),
      );
    }

    // 2. Top measurements (Dài áo / Ngang áo)
    final String? shirtLength = _nonEmpty(product.shirtLength) ??
        _extractMeasurementCm(combinedText, ['dài áo', 'chiều dài áo']) ??
        (isTop ? _defaultTopLength(product.id) : null);
    if (shirtLength != null) {
      specs.add(
        ProductSpecItem(
          label: 'Dài áo',
          value: shirtLength,
          icon: Icons.height_rounded,
        ),
      );
    }

    final String? chestWidth = _nonEmpty(product.chestWidth) ??
        _extractMeasurementCm(combinedText, ['ngang áo', 'ngang ngực', 'rộng ngực']) ??
        (isTop ? _defaultChestWidth(product.id) : null);
    if (chestWidth != null) {
      specs.add(
        ProductSpecItem(
          label: 'Ngang áo',
          value: chestWidth,
          icon: Icons.swap_horiz_rounded,
        ),
      );
    }

    // 3. Bottom measurements (Dài quần / Độ rộng ống)
    final String? pantsLength = _nonEmpty(product.pantsLength) ??
        _extractMeasurementCm(combinedText, ['dài quần', 'chiều dài quần']) ??
        (isBottom ? _defaultPantsLength(product.id) : null);
    if (pantsLength != null) {
      specs.add(
        ProductSpecItem(
          label: 'Dài quần',
          value: pantsLength,
          icon: Icons.height_rounded,
        ),
      );
    }

    final String? legOpening = _nonEmpty(product.legOpening) ??
        _extractMeasurementCm(combinedText, ['độ rộng ống', 'rộng ống', 'ống quần', 'ống']) ??
        (isBottom ? _defaultLegOpening(product.id, combinedText) : null);
    if (legOpening != null) {
      specs.add(
        ProductSpecItem(
          label: 'Độ rộng ống',
          value: legOpening,
          icon: Icons.unfold_more_rounded,
        ),
      );
    }

    // 4. Material / Chất liệu
    final String? resolvedMaterial = _nonEmpty(product.material) ??
        _inferMaterial(combinedText);
    if (resolvedMaterial != null) {
      specs.add(
        ProductSpecItem(
          label: 'Chất liệu',
          value: resolvedMaterial,
          icon: Icons.texture_rounded,
        ),
      );
    }

    // 5. Brand (when available)
    final brandName = product.brand?.name.trim();
    if (brandName != null && brandName.isNotEmpty) {
      specs.add(
        ProductSpecItem(
          label: 'Thương hiệu',
          value: brandName,
          icon: Icons.local_offer_outlined,
        ),
      );
    }

    return specs;
  }

  static String? _nonEmpty(String? raw) {
    final v = raw?.trim();
    return (v != null && v.isNotEmpty) ? v : null;
  }

  static bool _containsAny(String source, List<String> keywords) {
    for (final kw in keywords) {
      if (source.contains(kw)) return true;
    }
    return false;
  }

  static String? _extractSizeFromText(String text) {
    final letterMatch = RegExp(
      r'\bsize\s*[:\-]?\s*(xxs|xs|s|m|l|xl|xxl|2xl|3xl|free\s*size|freesize)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (letterMatch != null) {
      final token = letterMatch.group(1)!.trim().toUpperCase();
      return token.contains('FREE') ? 'Freesize' : token;
    }

    final numericMatch = RegExp(
      r'\b(?:size|eu|us|w)\s*[:\-]?\s*(\d{2}(?:\s*/\s*l?\d{2})?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (numericMatch != null) {
      return numericMatch.group(1)!.trim().toUpperCase();
    }
    return null;
  }

  static String? _extractMeasurementCm(String text, List<String> labels) {
    for (final label in labels) {
      final pattern = RegExp(
        '${RegExp.escape(label)}\\s*[:\\-]?\\s*(\\d{2,3}(?:[\\.,]\\d)?)\\s*cm',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      if (match != null) {
        return '${match.group(1)} cm';
      }
    }
    return null;
  }

  static String? _defaultSize({
    required int productId,
    required bool isTop,
    required bool isBottom,
    required bool isFootwear,
  }) {
    final seed = productId.abs();
    if (isFootwear) {
      const shoeSizes = ['EU 39', 'EU 40', 'EU 41', 'EU 42'];
      return shoeSizes[seed % shoeSizes.length];
    }
    if (isBottom) {
      const waistSizes = ['M (W30)', 'L (W32)', 'M (W31)', 'XL (W34)'];
      return waistSizes[seed % waistSizes.length];
    }
    if (isTop) {
      const topSizes = ['M', 'L', 'XL', 'S'];
      return topSizes[seed % topSizes.length];
    }
    return null;
  }

  static String _defaultTopLength(int productId) {
    const lengths = ['68 cm', '70 cm', '72 cm', '66 cm'];
    return lengths[productId.abs() % lengths.length];
  }

  static String _defaultChestWidth(int productId) {
    const widths = ['56 cm', '58 cm', '60 cm', '54 cm'];
    return widths[productId.abs() % widths.length];
  }

  static String _defaultPantsLength(int productId) {
    const lengths = ['100 cm', '102 cm', '104 cm', '98 cm'];
    return lengths[productId.abs() % lengths.length];
  }

  static String _defaultLegOpening(int productId, String text) {
    if (text.contains('flare') || text.contains('ống loe')) {
      return '24 cm';
    }
    const openings = ['20 cm', '21 cm', '22 cm', '19 cm'];
    return openings[productId.abs() % openings.length];
  }

  static String _inferMaterial(String text) {
    if (_containsAny(text, ['da cừu'])) return 'Da cừu thật 100%';
    if (_containsAny(text, ['da bò', 'coach', 'đồ da', 'túi da', 'ví da', 'bốt da'])) {
      return 'Da bò thuộc thật';
    }
    if (_containsAny(text, ['da lộn', 'suede'])) return 'Da lộn & Cao su tự nhiên';
    if (_containsAny(text, ['dạ tweed', 'tweed'])) return 'Vải dạ Tweed cao cấp';
    if (_containsAny(text, ['len lông cừu', 'lông cừu', 'mohair'])) {
      return 'Len lông cừu tự nhiên';
    }
    if (_containsAny(text, ['len', 'cardigan', 'sweater', 'dệt kim', 'beret'])) {
      return 'Len sợi dệt dày dặn';
    }
    if (_containsAny(text, ['denim', 'jean', 'jeans', 'selvedge', 'trucker'])) {
      return 'Denim 100% Cotton';
    }
    if (_containsAny(text, ['flannel', 'caro'])) return 'Cotton Flannel mềm';
    if (_containsAny(text, ['đồng hồ', 'seiko', 'casio', 'watch'])) {
      return 'Thép không gỉ & Kính khoáng';
    }
    if (_containsAny(text, ['máy ảnh', 'camera', 'olympus', 'canon', 'nikon'])) {
      return 'Hợp kim cơ khí & Ống kính quang học';
    }
    if (_containsAny(text, ['cassette', 'đĩa than', 'vinyl'])) {
      return 'Vật liệu sưu tầm nguyên bản';
    }
    if (_containsAny(text, ['kaki', 'cargo', 'trouser'])) return 'Vải Kaki Cotton dày';
    if (_containsAny(text, ['giày', 'sneaker', 'boot', 'bốt'])) {
      return 'Da tổng hợp & Đế cao su cổ điển';
    }
    return 'Cotton Vintage tuyển chọn';
  }

  @override
  Widget build(BuildContext context) {
    final specs = resolveSpecs(product);
    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.straighten_rounded,
                size: 18,
                color: AppColors.pineDeep,
              ),
              const SizedBox(width: 8),
              Text(
                'Thông số sản phẩm',
                style: AppTypography.headingSmall.copyWith(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pineDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),
          for (var i = 0; i < specs.length; i++) ...[
            _buildSpecRow(specs[i]),
            if (i < specs.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Divider(height: 1, color: AppColors.borderSubtle),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow(ProductSpecItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(item.icon, size: 15.5, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 106,
          child: Text(
            item.label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.2,
              color: AppColors.textCharcoal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
