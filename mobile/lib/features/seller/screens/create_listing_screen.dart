import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/seller_product_form_view_model.dart';
import '../../catalog/models/category_model.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';

/// M-SL-03: Create Product Listing Screen
/// Enforces BR-PR-01 (Auction locked quantity = 1), BR-PR-03 (Mandatory defect info >= 5 chars, 5 condition levels).
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _defectController;
  late TextEditingController _brandController;
  late TextEditingController _startPriceController;
  late TextEditingController _bidIncrementController;

  static const List<Duration> _auctionDurationPresets = [
    Duration(minutes: 15),
    Duration(hours: 1),
    Duration(hours: 24),
    Duration(days: 3),
  ];

  String _auctionDurationLabel(Duration duration) {
    if (duration == const Duration(minutes: 15)) {
      return '15 phút (Demo)';
    }

    if (duration == const Duration(hours: 1)) {
      return '1 giờ';
    }

    if (duration == const Duration(hours: 24)) {
      return '24 giờ';
    }

    if (duration == const Duration(days: 3)) {
      return '3 ngày';
    }

    return '${duration.inMinutes} phút';
  }

  Duration _selectedAuctionDuration(SellerProductFormViewModel vm) {
    final startsAt = vm.auctionStartsAt;
    final endsAt = vm.auctionEndsAt;

    if (startsAt != null && endsAt != null) {
      final currentDuration = endsAt.difference(startsAt);

      for (final preset in _auctionDurationPresets) {
        if (currentDuration == preset) {
          return preset;
        }
      }
    }

    return const Duration(minutes: 15);
  }

  void _setAuctionDuration(SellerProductFormViewModel vm, Duration duration) {
    final now = DateTime.now();

    setState(() {
      vm.auctionStartsAt = now;
      vm.auctionEndsAt = now.add(duration);
    });
  }

  List<CategoryModel> _flattenCategories(List<CategoryModel> categories) {
    final result = <CategoryModel>[];
    for (final parent in categories) {
      result.add(parent);
      if (parent.children.isNotEmpty) {
        result.addAll(parent.children);
      }
    }
    return result;
  }

  Future<void> _loadTaxonomy({bool forceRefresh = false}) async {
    await ref
        .read(catalogSearchViewModelProvider)
        .loadTaxonomy(forceRefresh: forceRefresh);
  }

  Future<void> _pickImages(SellerProductFormViewModel vm) async {
    final remaining = [
      8 - vm.imageFiles.length,
      10 - vm.imageUrls.length - vm.imageFiles.length,
    ].reduce((a, b) => a < b ? a : b);
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã chọn tối đa 8 ảnh tải lên từ thiết bị.'),
        ),
      );
      return;
    }
    try {
      final selected = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (!mounted || selected.isEmpty) return;
      vm.addImageFiles(selected);
      if (selected.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chỉ nhận thêm $remaining ảnh để không vượt giới hạn 8 ảnh/request.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
      }
    }
  }

  static const List<_ConditionOption> _conditions = [
    _ConditionOption('NEW_WITH_TAGS', 'Mới còn tag'),
    _ConditionOption('LIKE_NEW', 'Như mới (99%)'),
    _ConditionOption('GOOD', 'Tốt (90%)'),
    _ConditionOption('FAIR', 'Khá (80%)'),
    _ConditionOption('VINTAGE_WORN', 'Dấu ấn vintage'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _defectController = TextEditingController();
    _brandController = TextEditingController();
    _startPriceController = TextEditingController();
    _bidIncrementController = TextEditingController(text: '10000');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(sellerProductFormViewModelProvider);
      vm.initForCreate();
      _loadTaxonomy();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _defectController.dispose();
    _brandController.dispose();
    _startPriceController.dispose();
    _bidIncrementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sellerProductFormViewModelProvider);
    final isAuction = vm.listingType == 'AUCTION';

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(title: const Text('Đăng bán sản phẩm mới'), elevation: 0),
      bottomNavigationBar: _buildBottomActionBar(vm),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Listing Type Toggle (Fixed Price vs Auction)
                _buildListingTypeSelector(vm),

                const SizedBox(height: DesignTokens.spaceLg),

                // 2. Photo Upload Section (Up to 10 photos)
                _buildPhotosSection(vm),

                const SizedBox(height: DesignTokens.spaceLg),

                // 3. Basic Information Card
                _buildBasicInfoSection(vm, isAuction),

                const SizedBox(height: DesignTokens.spaceLg),

                // 4. Condition & Defect Info (BR-PR-03)
                _buildConditionAndDefectSection(vm),

                const SizedBox(height: DesignTokens.space2xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingTypeSelector(SellerProductFormViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => vm.setListingType('FIXED_PRICE'),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: vm.listingType == 'FIXED_PRICE'
                      ? AppColors.primaryTerracotta
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Center(
                  child: Text(
                    '🏷️ Bán giá cố định',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: vm.listingType == 'FIXED_PRICE'
                          ? AppColors.textLight
                          : AppColors.textCharcoal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () {
                vm.setListingType('AUCTION');
                _quantityController.text = '1';

                // Demo default: a short auction that can be tested immediately.
                _setAuctionDuration(vm, const Duration(minutes: 15));
              },
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: vm.listingType == 'AUCTION'
                      ? AppColors.christmasBerryRed
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Center(
                  child: Text(
                    '🔨 Đấu giá trực tiếp',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: vm.listingType == 'AUCTION'
                          ? AppColors.textLight
                          : AppColors.textCharcoal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(SellerProductFormViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hình ảnh sản phẩm (Tối đa 10 ảnh)',
                style: AppTypography.headingSmall.copyWith(fontSize: 15),
              ),
              Text(
                '${vm.imageUrls.length + vm.imageFiles.length}/10',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.imageUrls.length + vm.imageFiles.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == vm.imageUrls.length + vm.imageFiles.length) {
                  return _buildAddPhotoButton(vm);
                }
                if (index < vm.imageUrls.length) {
                  return _buildPhotoThumbnail(vm, index);
                }
                return _buildLocalPhotoThumbnail(
                  vm,
                  index - vm.imageUrls.length,
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _promptAddImageUrl(vm),
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Thêm ảnh bằng đường dẫn URL'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPhotoThumbnail(SellerProductFormViewModel vm, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          child: FutureBuilder<Uint8List>(
            future: vm.imageFiles[index].readAsBytes(),
            builder: (context, snapshot) => snapshot.hasData
                ? Image.memory(
                    snapshot.data!,
                    width: 88,
                    height: 90,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 88,
                    height: 90,
                    color: AppColors.surfaceWarm,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => vm.removeImageFile(index),
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: const Text(
              'Ảnh mới',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton(SellerProductFormViewModel vm) {
    return InkWell(
      onTap: () => _pickImages(vm),
      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          border: Border.all(color: AppColors.borderWarm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primaryTerracotta,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Thêm ảnh',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(SellerProductFormViewModel vm, int index) {
    final url = vm.imageUrls[index];
    final isPrimary = index == 0;

    return Stack(
      children: [
        Container(
          width: 88,
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            border: Border.all(
              color: isPrimary
                  ? AppColors.primaryTerracotta
                  : AppColors.borderWarm,
              width: isPrimary ? 2 : 1,
            ),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        if (isPrimary)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: AppColors.primaryTerracotta.withValues(alpha: 0.9),
              child: const Text(
                'Ảnh đại diện',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => vm.removeImageUrl(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _promptAddImageUrl(SellerProductFormViewModel vm) {
    final urlController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1551028719-00167b16eac5',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm liên kết ảnh'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL hình ảnh (jpg, png, webp)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTerracotta,
            ),
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                vm.addImageUrl(urlController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(SellerProductFormViewModel vm, bool isAuction) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chi tiết sản phẩm',
            style: AppTypography.headingSmall.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 12),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tên sản phẩm vintage / retro *',
              hintText: 'VD: Áo khoác da Bomber Vintage thập niên 90s',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 5) {
                return 'Tên sản phẩm phải có ít nhất 5 ký tự';
              }
              return null;
            },
            onChanged: (v) => vm.title = v.trim(),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 5000,
            decoration: const InputDecoration(
              labelText: 'Mô tả sản phẩm',
              hintText: 'Chất liệu, kiểu dáng, nguồn gốc, cách phối...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onChanged: (value) => vm.description = value,
          ),

          const SizedBox(height: 12),

          // Category Dropdown — active categories from taxonomy API.
          Builder(
            builder: (context) {
              final taxonomyVm = ref.watch(catalogSearchViewModelProvider);
              final taxonomy = taxonomyVm.taxonomy;
              final categories = taxonomy == null
                  ? <CategoryModel>[]
                  : _flattenCategories(taxonomy.categories);
              final selectedCategoryId = vm.categoryId;
              final hasSelectedCategory = categories.any(
                (category) => category.id == selectedCategoryId,
              );
              return DropdownButtonFormField<int>(
                value: hasSelectedCategory ? selectedCategoryId : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Danh mục *',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: const OutlineInputBorder(),
                  helperText: taxonomyVm.isLoadingTaxonomy
                      ? 'Đang tải danh mục...'
                      : taxonomyVm.taxonomyError,
                  errorText: taxonomyVm.taxonomyError,
                  suffixIcon: taxonomyVm.taxonomyError != null
                      ? IconButton(
                          tooltip: 'Thử tải lại',
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            _loadTaxonomy(forceRefresh: true);
                          },
                        )
                      : null,
                ),
                hint: Text(
                  taxonomyVm.isLoadingTaxonomy
                      ? 'Đang tải danh mục...'
                      : 'Chọn danh mục sản phẩm',
                ),
                items: categories.map((category) {
                  final parent = category.parentId == null
                      ? null
                      : taxonomy?.categories
                            .where((root) => root.id == category.parentId)
                            .firstOrNull;
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(
                      parent == null
                          ? category.name
                          : '${parent.name} › ${category.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged:
                    taxonomyVm.isLoadingTaxonomy ||
                        taxonomyVm.taxonomyError != null ||
                        categories.isEmpty
                    ? null
                    : (categoryId) {
                        if (categoryId == null) return;
                        final category = categories.firstWhere(
                          (item) => item.id == categoryId,
                        );
                        vm.setCategory(category.id, category.name);
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn danh mục sản phẩm';
                  }
                  return null;
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Brand (Optional)
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(
              labelText: 'Thương hiệu / Nhãn hiệu (Tùy chọn)',
              hintText: 'VD: Levi\'s, Burberry, Harley Davidson...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => vm.brandName = v.trim(),
          ),

          const SizedBox(height: 12),

          // Pricing and Quantity based on Listing Type
          if (!isAuction) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá bán (VNĐ) *',
                      hintText: 'VD: 350000',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final p = double.tryParse(v ?? '');
                      if (p == null || p <= 0) return 'Giá phải > 0';
                      return null;
                    },
                    onChanged: (v) => vm.price = double.tryParse(v) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final q = int.tryParse(v ?? '');
                      if (q == null || q < 1) return '>= 1';
                      return null;
                    },
                    onChanged: (v) => vm.quantity = int.tryParse(v) ?? 1,
                  ),
                ),
              ],
            ),
          ] else ...[
            // BR-PR-01: Auction Form with strictly locked quantity = 1
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceSm),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                border: Border.all(color: const Color(0xFFFFE799)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFFB47800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'BR-PR-01: Sản phẩm đấu giá là độc bản secondhand, số lượng khả dụng cố định là 1.',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF7A5100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá khởi điểm (VNĐ) *',
                      hintText: 'VD: 100000',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final p = double.tryParse(v ?? '');
                      if (p == null || p <= 0) return 'Giá KĐ > 0';
                      return null;
                    },
                    onChanged: (v) {
                      final p = double.tryParse(v) ?? 0.0;
                      vm.startingPrice = p;
                      vm.price = p;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _bidIncrementController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bước giá tối thiểu *',
                      hintText: '10000',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final inc = double.tryParse(v ?? '');
                      if (inc == null || inc < 1000) return '>= 1,000đ';
                      return null;
                    },
                    onChanged: (v) =>
                        vm.minBidIncrement = double.tryParse(v) ?? 10000.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời lượng phiên đấu giá',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _auctionDurationPresets.map((duration) {
                    final selected = _selectedAuctionDuration(vm) == duration;

                    return ChoiceChip(
                      label: Text(_auctionDurationLabel(duration)),
                      selected: selected,
                      onSelected: (value) {
                        if (!value) return;
                        _setAuctionDuration(vm, duration);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                if (vm.auctionStartsAt != null && vm.auctionEndsAt != null)
                  Text(
                    'Bắt đầu: ${vm.auctionStartsAt!.toLocal()}\n'
                    'Kết thúc: ${vm.auctionEndsAt!.toLocal()}',
                    style: AppTypography.caption,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionAndDefectSection(SellerProductFormViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tình trạng đồ si & Minh bạch khuyết điểm',
                style: AppTypography.headingSmall.copyWith(fontSize: 15),
              ),
              const SizedBox(width: 4),
              const Text('🔍'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn 1 trong 5 mức chuẩn mực tình trạng sản phẩm:',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),

          // 5-Tier Condition Choice Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _conditions.map((cond) {
              final isSelected = vm.condition == cond.key;
              return ChoiceChip(
                label: Text(cond.label),
                selected: isSelected,
                selectedColor: AppColors.primaryTerracotta,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textCharcoal,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.surfaceWarm,
                onSelected: (selected) {
                  if (selected) vm.setCondition(cond.key);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // BR-PR-03: Mandatory Defect Info (>= 5 chars)
          TextFormField(
            key: const Key('input_defect_info'),
            controller: _defectController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Mô tả khuyết điểm & độ sờn rách (Bắt buộc) *',
              hintText: 'VD: Có vết xước nhẹ 2cm ở ve áo trái, khóa kéo đồng trơn tru không lỗi.',
              helperText: 'Bắt buộc tối thiểu 5 ký tự để bảo vệ quyền lợi người mua & người bán.',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 5) {
                return 'BR-PR-03: Mô tả khuyết điểm là bắt buộc (tối thiểu 5 ký tự).';
              }
              return null;
            },
            onChanged: (v) => vm.defectInfo = v.trim(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(SellerProductFormViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceLg,
        vertical: DesignTokens.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        children: [
          // Lưu bản nháp
          Expanded(
            child: OutlinedButton(
              key: const Key('btn_save_draft'),
              onPressed: vm.isSubmitting
                  ? null
                  : () => _submitForm(vm, submitForReview: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF84664C),
                side: const BorderSide(color: AppColors.borderWarm),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
              child: const Text(
                'Lưu bản nháp',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Gửi phê duyệt ngay
          Expanded(
            flex: 2,
            child: ElevatedButton(
              key: const Key('btn_submit_for_review'),
              onPressed: vm.isSubmitting
                  ? null
                  : () => _submitForm(vm, submitForReview: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTerracotta,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
              child: vm.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Gửi phê duyệt ngay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm(
    SellerProductFormViewModel vm, {
    required bool submitForReview,
  }) async {
    if (submitForReview) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    } else {
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập tên sản phẩm trước khi lưu nháp.'),
          ),
        );
        return;
      }
      vm.title = _titleController.text.trim();
      vm.description = _descriptionController.text.trim();
      vm.defectInfo = _defectController.text.trim();
    }

    final res = await vm.submit(submitForReview: submitForReview);
    if (mounted) {
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              submitForReview
                  ? 'Đã gửi duyệt sản phẩm "${res.title}" thành công!'
                  : 'Đã lưu bản nháp "${res.title}".',
            ),
          ),
        );
        context.pushReplacement(AppRoutes.sellerListings);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusDanger,
            content: Text(
              vm.state.maybeWhen(
                error: (err, _) => err,
                orElse: () => 'Lỗi khi lưu sản phẩm.',
              ),
            ),
          ),
        );
      }
    }
  }
}

class _ConditionOption {
  final String key;
  final String label;

  const _ConditionOption(this.key, this.label);
}
