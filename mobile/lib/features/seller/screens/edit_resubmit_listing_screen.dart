import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/seller_product_item_model.dart';
import '../viewmodels/seller_product_form_view_model.dart';
import '../../catalog/models/category_model.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';

/// M-SL-04: Edit & Resubmit Product Listing Screen
/// Enforces DEC-05 (Rejection reason inspection banner & clearance on resubmission),
/// BR-PR-01 (Auction quantity lock = 1), and BR-PR-03 (Mandatory defect info >= 5 chars).
class EditResubmitListingScreen extends ConsumerStatefulWidget {
  final int productId;
  final SellerProductItemModel? initialProduct;

  const EditResubmitListingScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  ConsumerState<EditResubmitListingScreen> createState() =>
      _EditResubmitListingScreenState();
}

class _EditResubmitListingScreenState
    extends ConsumerState<EditResubmitListingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _defectController;
  late TextEditingController _brandController;
  late TextEditingController _startPriceController;
  late TextEditingController _bidIncrementController;

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
      _loadTaxonomy();
      if (widget.initialProduct != null) {
        _populateFields(widget.initialProduct!, vm);
      } else if (widget.productId > 0) {
        _loadProductData(vm);
      }
    });
  }

  Future<void> _loadProductData(SellerProductFormViewModel vm) async {
    final product = await vm.loadProductForEdit(widget.productId);
    if (mounted && product != null) {
      _populateFields(product, vm);
    }
  }

  void _populateFields(
    SellerProductItemModel product,
    SellerProductFormViewModel vm,
  ) {
    vm.initForEdit(product);
    _titleController.text = product.title;
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price.toStringAsFixed(0);
    _quantityController.text = product.availableQuantity.toString();
    _defectController.text = product.defectInfo ?? '';
    _brandController.text = product.brandName ?? '';
    if (product.startingPrice != null) {
      _startPriceController.text = product.startingPrice!.toStringAsFixed(0);
    }
    if (product.bidIncrement != null) {
      _bidIncrementController.text = product.bidIncrement!.toStringAsFixed(0);
    }
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
    final hasRejection =
        vm.currentRejectionReason != null &&
        vm.currentRejectionReason!.isNotEmpty;
    final isInvalidId = widget.initialProduct == null && widget.productId <= 0;
    final isLoaded =
        (widget.initialProduct != null || vm.editingProductId != null) &&
        !isInvalidId;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text(
          hasRejection ? 'Sửa & Gửi duyệt lại' : 'Chỉnh sửa bài đăng',
        ),
        elevation: 0,
      ),
      bottomNavigationBar: isLoaded
          ? _buildBottomActionBar(vm, hasRejection)
          : null,
      body: SafeArea(
        child: isInvalidId
            ? RetroEmptyStateView(
                title: 'Sản phẩm không hợp lệ',
                message: 'Mã sản phẩm không hợp lệ hoặc không còn tồn tại.',
                icon: Icons.error_outline,
                actionLabel: 'Quay lại danh sách bài đăng',
                onAction: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.sellerListings);
                  }
                },
              )
            : !isLoaded
            ? (vm.state.isError
                  ? RetroErrorRetryView(
                      errorMessage:
                          vm.errorMessage ??
                          'Không thể tải thông tin bài đăng.',
                      onRetry: () => _loadProductData(vm),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryTerracotta,
                      ),
                    ))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DEC-05: Pinned Rejection Banner in Burgundy/Red
                      if (hasRejection) ...[
                        _buildRejectionBanner(vm.currentRejectionReason!),
                        const SizedBox(height: DesignTokens.spaceLg),
                      ],

                      // Photos Section
                      _buildPhotosSection(vm),

                      const SizedBox(height: DesignTokens.spaceLg),

                      // Basic Info Card
                      _buildBasicInfoSection(vm, isAuction),

                      const SizedBox(height: DesignTokens.spaceLg),

                      // Condition & Defect Info (BR-PR-03)
                      _buildConditionAndDefectSection(vm),

                      const SizedBox(height: DesignTokens.space2xl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRejectionBanner(String reason) {
    return Container(
      key: const Key('banner_rejection_reason'),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.statusDanger, width: 1.5),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.statusDanger,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Lý do từ chối kiểm duyệt (DEC-05)',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.statusDanger,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spaceSm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(color: const Color(0xFFF8B4B4)),
            ),
            child: Text(
              reason,
              style: AppTypography.bodySmall.copyWith(
                color: const Color(0xFF9B1C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vui lòng cập nhật hình ảnh, thông tin khuyết điểm hoặc giá bán và nhấn "Gửi duyệt lại (Resubmit)". Khi gửi lại, lý do từ chối sẽ được xóa và chuyển về trạng thái Chờ duyệt.',
            style: AppTypography.caption.copyWith(
              color: AppColors.statusDanger,
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
                'Hình ảnh sản phẩm',
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
    final urlController = TextEditingController();
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
              labelText: 'Tên sản phẩm *',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 5) {
                return 'Tên phải >= 5 ký tự';
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
                      : null,
                  errorText: taxonomyVm.taxonomyError,
                  suffixIcon: taxonomyVm.taxonomyError != null
                      ? IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Tải lại danh mục',
                          onPressed: () => _loadTaxonomy(forceRefresh: true),
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
                        (taxonomyVm.taxonomyError != null &&
                            categories.isEmpty) ||
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

          // Brand
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(
              labelText: 'Thương hiệu',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => vm.brandName = v.trim(),
          ),

          const SizedBox(height: 12),

          // Price & Quantity
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
            TextFormField(
              controller: _startPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá khởi điểm (VNĐ) *',
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
          Text(
            'Tình trạng đồ si & Minh bạch khuyết điểm',
            style: AppTypography.headingSmall.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),

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

          // BR-PR-03: Mandatory Defect Info
          TextFormField(
            key: const Key('input_defect_info_edit'),
            controller: _defectController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Mô tả khuyết điểm & độ sờn rách (Bắt buộc) *',
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

  Widget _buildBottomActionBar(
    SellerProductFormViewModel vm,
    bool hasRejection,
  ) {
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
          // Lưu thay đổi nháp
          Expanded(
            child: OutlinedButton(
              onPressed: vm.isSubmitting
                  ? null
                  : () => _submitEditForm(vm, submitForReview: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF84664C),
                side: const BorderSide(color: AppColors.borderWarm),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
              child: const Text(
                'Lưu thay đổi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Gửi duyệt lại / Cập nhật
          Expanded(
            flex: 2,
            child: ElevatedButton(
              key: const Key('btn_resubmit_action'),
              onPressed: vm.isSubmitting
                  ? null
                  : () => _submitEditForm(vm, submitForReview: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasRejection
                    ? AppColors.statusDanger
                    : AppColors.primaryTerracotta,
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
                  : Text(
                      hasRejection
                          ? 'Gửi duyệt lại (Resubmit)'
                          : 'Lưu & Gửi phê duyệt',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEditForm(
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
          const SnackBar(content: Text('Vui lòng nhập tên sản phẩm')),
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
                  ? 'Đã gửi duyệt lại sản phẩm "${res.title}". Lý do từ chối đã được xóa!'
                  : 'Đã lưu thay đổi sản phẩm.',
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
                orElse: () => 'Lỗi khi cập nhật sản phẩm.',
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
