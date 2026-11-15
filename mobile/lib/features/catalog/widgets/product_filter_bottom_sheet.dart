import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/product_filter_query.dart';
import '../models/taxonomy_model.dart';

/// M-DS-03: Multi-Filter Bottom Sheet
class ProductFilterBottomSheet extends StatefulWidget {
  final ProductFilterQuery initialQuery;
  final TaxonomyModel? taxonomy;
  final ValueChanged<ProductFilterQuery> onApply;

  const ProductFilterBottomSheet({
    super.key,
    required this.initialQuery,
    this.taxonomy,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductFilterQuery initialQuery,
    TaxonomyModel? taxonomy,
    required ValueChanged<ProductFilterQuery> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
      ),
      builder: (ctx) => ProductFilterBottomSheet(
        initialQuery: initialQuery,
        taxonomy: taxonomy,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ProductFilterBottomSheet> createState() => _ProductFilterBottomSheetState();
}

class _ProductFilterBottomSheetState extends State<ProductFilterBottomSheet> {
  late String? _listingType;
  late String? _condition;
  late int? _categoryId;
  late int? _brandId;
  late String? _sort;

  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  String? _priceErrorMessage;

  @override
  void initState() {
    super.initState();
    _listingType = widget.initialQuery.listingType;
    _condition = widget.initialQuery.condition;
    _categoryId = widget.initialQuery.categoryId;
    _brandId = widget.initialQuery.brandId;
    _sort = widget.initialQuery.sort ?? 'newest';

    _minPriceController = TextEditingController(
      text: widget.initialQuery.minPrice != null
          ? widget.initialQuery.minPrice!.toInt().toString()
          : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialQuery.maxPrice != null
          ? widget.initialQuery.maxPrice!.toInt().toString()
          : '',
    );

    _minPriceController.addListener(_validatePrices);
    _maxPriceController.addListener(_validatePrices);
    _validatePrices();
  }

  @override
  void dispose() {
    _minPriceController.removeListener(_validatePrices);
    _maxPriceController.removeListener(_validatePrices);
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _validatePrices() {
    final minText = _minPriceController.text.trim();
    final maxText = _maxPriceController.text.trim();

    final min = double.tryParse(minText);
    final max = double.tryParse(maxText);

    if (min != null && max != null && min > max) {
      if (_priceErrorMessage != 'Giá tối thiểu không được lớn hơn giá tối đa') {
        setState(() {
          _priceErrorMessage = 'Giá tối thiểu không được lớn hơn giá tối đa';
        });
      }
    } else {
      if (_priceErrorMessage != null) {
        setState(() {
          _priceErrorMessage = null;
        });
      }
    }
  }

  bool get _isPriceValid => _priceErrorMessage == null;

  void _resetAll() {
    setState(() {
      _listingType = null;
      _condition = null;
      _categoryId = null;
      _brandId = null;
      _sort = 'newest';
      _minPriceController.clear();
      _maxPriceController.clear();
      _priceErrorMessage = null;
    });
  }

  void _applyFilters() {
    if (!_isPriceValid) return;

    final min = double.tryParse(_minPriceController.text.trim());
    final max = double.tryParse(_maxPriceController.text.trim());

    final updatedQuery = widget.initialQuery.copyWith(
      listingType: _listingType,
      condition: _condition,
      categoryId: _categoryId,
      brandId: _brandId,
      sort: _sort,
      minPrice: min,
      maxPrice: max,
      clearListingType: _listingType == null,
      clearCondition: _condition == null,
      clearCategory: _categoryId == null,
      clearBrand: _brandId == null,
      clearPriceRange: min == null && max == null,
    );

    widget.onApply(updatedQuery);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderWarm,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ lọc tìm kiếm',
                  style: TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textCharcoal,
                  ),
                ),
                TextButton(
                  onPressed: _resetAll,
                  child: const Text(
                    'Thiết lập lại',
                    style: TextStyle(
                      color: AppColors.primaryTerracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderWarm),

          // Scrollable Filter Sections
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Khoảng giá (Price Range)
                _buildSectionTitle('Khoảng giá (VNĐ)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Từ 0đ',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                            borderSide: const BorderSide(color: AppColors.borderWarm),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Đến ... đ',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                            borderSide: const BorderSide(color: AppColors.borderWarm),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_priceErrorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _priceErrorMessage!,
                    style: const TextStyle(
                      color: AppColors.statusDanger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // 2. Loại hình giao dịch (Listing Type)
                _buildSectionTitle('Hình thức bán'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Tất cả',
                      isSelected: _listingType == null,
                      onSelected: () => setState(() => _listingType = null),
                    ),
                    _buildChoiceChip(
                      label: 'Mua ngay (Giá cố định)',
                      isSelected: _listingType == 'FIXED_PRICE',
                      onSelected: () => setState(() => _listingType = 'FIXED_PRICE'),
                    ),
                    _buildChoiceChip(
                      label: 'Đấu giá (Sàn Live)',
                      isSelected: _listingType == 'AUCTION',
                      onSelected: () => setState(() => _listingType = 'AUCTION'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Tình trạng sản phẩm (Condition)
                _buildSectionTitle('Tình trạng sản phẩm'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Tất cả',
                      isSelected: _condition == null,
                      onSelected: () => setState(() => _condition = null),
                    ),
                    _buildChoiceChip(
                      label: 'Mới nguyên tag (100%)',
                      isSelected: _condition == 'NEW_WITH_TAGS',
                      onSelected: () => setState(() => _condition = 'NEW_WITH_TAGS'),
                    ),
                    _buildChoiceChip(
                      label: 'Như mới (95%+)',
                      isSelected: _condition == 'LIKE_NEW',
                      onSelected: () => setState(() => _condition = 'LIKE_NEW'),
                    ),
                    _buildChoiceChip(
                      label: 'Tốt (85%-90%)',
                      isSelected: _condition == 'GOOD',
                      onSelected: () => setState(() => _condition = 'GOOD'),
                    ),
                    _buildChoiceChip(
                      label: 'Chấp nhận được (70%-80%)',
                      isSelected: _condition == 'FAIR',
                      onSelected: () => setState(() => _condition = 'FAIR'),
                    ),
                    _buildChoiceChip(
                      label: 'Vintage Worn (Cũ bạc đẹp)',
                      isSelected: _condition == 'VINTAGE_WORN',
                      onSelected: () => setState(() => _condition = 'VINTAGE_WORN'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Sắp xếp (Sort)
                _buildSectionTitle('Sắp xếp theo'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Mới nhất',
                      isSelected: _sort == 'newest',
                      onSelected: () => setState(() => _sort = 'newest'),
                    ),
                    _buildChoiceChip(
                      label: 'Giá tăng dần',
                      isSelected: _sort == 'price_asc',
                      onSelected: () => setState(() => _sort = 'price_asc'),
                    ),
                    _buildChoiceChip(
                      label: 'Giá giảm dần',
                      isSelected: _sort == 'price_desc',
                      onSelected: () => setState(() => _sort = 'price_desc'),
                    ),
                    _buildChoiceChip(
                      label: 'Phổ biến nhất',
                      isSelected: _sort == 'popular',
                      onSelected: () => setState(() => _sort = 'popular'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTerracotta,
                  foregroundColor: AppColors.surfaceCard,
                  disabledBackgroundColor: AppColors.borderWarm,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                onPressed: _isPriceValid ? _applyFilters : null,
                child: const Text(
                  'Áp dụng bộ lọc',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTypography.fontHeading,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textCharcoal,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryTerracotta.withAlpha(40),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryTerracotta : AppColors.textCharcoal,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryTerracotta : AppColors.borderWarm,
      ),
    );
  }
}
