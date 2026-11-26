import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../catalog/models/category_model.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';
import '../models/seller_product_item_model.dart';
import '../viewmodels/seller_product_form_view_model.dart';

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

  InputDecoration _editorialInputDecoration({
    required String labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: AppColors.surfaceWarm,
      border: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.borderWarm),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.borderWarm),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.pineDeep, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sellerProductFormViewModelProvider);
    final isAuction = vm.listingType == 'AUCTION';
    final hasRejection = vm.currentRejectionReason != null &&
        vm.currentRejectionReason!.isNotEmpty;
    final isInvalidId = widget.initialProduct == null && widget.productId <= 0;
    final isLoaded =
        (widget.initialProduct != null || vm.editingProductId != null) &&
            !isInvalidId;

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          hasRejection ? 'Sửa & Gửi duyệt lại' : 'Chỉnh sửa bài đăng',
          style: AppTypography.headingMedium.copyWith(fontSize: 19),
        ),
      ),
      bottomNavigationBar:
          isLoaded ? _buildBottomActionBar(vm, hasRejection) : null,
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
                        errorMessage: vm.errorMessage ??
                            'Không thể tải thông tin bài đăng.',
                        onRetry: () => _loadProductData(vm),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.pineDeep,
                        ),
                      ))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DEC-05: Pinned Rejection Banner in Crimson
                          if (hasRejection) ...[
                            _buildRejectionBanner(vm.currentRejectionReason!),
                            const SizedBox(height: 16),
                          ],

                          // Photos Section
                          _buildPhotosSection(vm),
                          const SizedBox(height: 16),

                          // Basic Info Card
                          _buildBasicInfoSection(vm, isAuction),
                          const SizedBox(height: 16),

                          // Condition & Defect Info (BR-PR-03)
                          _buildConditionAndDefectSection(vm),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.priceCrimsonSoft,
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(color: AppColors.priceCrimsonBorder, width: 1.4),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.priceCrimsonBorder),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.priceCrimson,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lý do từ chối kiểm duyệt (DEC-05)',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.priceCrimson,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(color: AppColors.priceCrimsonBorder),
            ),
            child: Text(
              reason,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.priceCrimson,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng cập nhật hình ảnh, thông tin khuyết điểm hoặc giá bán và nhấn "Gửi duyệt lại (Resubmit)". Khi gửi lại, lý do từ chối sẽ được xóa và chuyển về trạng thái Chờ duyệt.',
            style: AppTypography.caption.copyWith(
              color: AppColors.priceCrimson,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(SellerProductFormViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusBanner,
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
                style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.creamBadgeSoft,
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: Text(
                  '${vm.imageUrls.length + vm.imageFiles.length}/10',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.creamBadgeText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.imageUrls.length + vm.imageFiles.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
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
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _promptAddImageUrl(vm),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.pineDeep,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              icon: const Icon(Icons.link_rounded, size: 17),
              label: const Text(
                'Thêm ảnh bằng đường dẫn URL',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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
          borderRadius: DesignTokens.borderRadiusMd,
          child: FutureBuilder<Uint8List>(
            future: vm.imageFiles[index].readAsBytes(),
            builder: (context, snapshot) => snapshot.hasData
                ? Image.memory(
                    snapshot.data!,
                    width: 90,
                    height: 92,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 90,
                    height: 92,
                    color: AppColors.surfaceWarm,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.pineDeep,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => vm.removeImageFile(index),
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(DesignTokens.radiusMd),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: const Text(
              'Ảnh mới',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 9.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton(SellerProductFormViewModel vm) {
    return InkWell(
      onTap: () => _pickImages(vm),
      borderRadius: DesignTokens.borderRadiusMd,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: DesignTokens.borderRadiusMd,
          border: Border.all(
            color: AppColors.ctaTerracotta.withValues(alpha: 0.45),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.ctaTerracotta,
              size: 26,
            ),
            SizedBox(height: 5),
            Text(
              'Thêm ảnh',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ctaTerracotta,
              ),
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
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: DesignTokens.borderRadiusMd,
            border: Border.all(
              color: isPrimary
                  ? AppColors.ctaTerracotta
                  : AppColors.borderWarm,
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd - 1),
            child: RetroProductImage(
              imageUrl: url,
              title: vm.title,
              productId: widget.productId,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (isPrimary)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.ctaTerracotta.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(DesignTokens.radiusMd - 1),
                ),
              ),
              child: const Text(
                'Ảnh đại diện',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => vm.removeImageUrl(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
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
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
          side: const BorderSide(color: AppColors.borderWarm),
        ),
        title: Text(
          'Thêm liên kết ảnh',
          style: AppTypography.headingSmall.copyWith(fontSize: 17),
        ),
        content: TextField(
          controller: urlController,
          decoration: _editorialInputDecoration(
            labelText: 'URL hình ảnh (jpg, png, webp)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaTerracotta,
              foregroundColor: AppColors.textLight,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                vm.addImageUrl(urlController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    ).whenComplete(urlController.dispose);
  }

  Widget _buildBasicInfoSection(
    SellerProductFormViewModel vm,
    bool isAuction,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chi tiết sản phẩm',
            style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 14),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: _editorialInputDecoration(labelText: 'Tên sản phẩm *'),
            validator: (v) {
              if (v == null || v.trim().length < 5) {
                return 'Tên phải >= 5 ký tự';
              }
              return null;
            },
            onChanged: (v) => vm.title = v.trim(),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 5000,
            decoration: _editorialInputDecoration(
              labelText: 'Mô tả sản phẩm',
              hintText: 'Chất liệu, kiểu dáng, nguồn gốc, cách phối...',
              alignLabelWithHint: true,
            ),
            onChanged: (value) => vm.description = value,
          ),
          const SizedBox(height: 12),

          // Category Dropdown
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
                decoration: _editorialInputDecoration(
                  labelText: 'Danh mục *',
                  prefixIcon: const Icon(Icons.category_outlined),
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
                onChanged: taxonomyVm.isLoadingTaxonomy ||
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
          const SizedBox(height: 14),

          // Brand
          TextFormField(
            controller: _brandController,
            decoration: _editorialInputDecoration(labelText: 'Thương hiệu'),
            onChanged: (v) => vm.brandName = v.trim(),
          ),
          const SizedBox(height: 14),

          // Price & Quantity
          if (!isAuction) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: _editorialInputDecoration(
                      labelText: 'Giá bán (VNĐ) *',
                    ),
                    validator: (v) {
                      final p = double.tryParse(v ?? '');
                      if (p == null || p <= 0) return 'Giá phải > 0';
                      return null;
                    },
                    onChanged: (v) => vm.price = double.tryParse(v) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: _editorialInputDecoration(
                      labelText: 'Số lượng *',
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
              decoration: _editorialInputDecoration(
                labelText: 'Giá khởi điểm (VNĐ) *',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tình trạng đồ si & Minh bạch khuyết điểm',
            style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _conditions.map((cond) {
              final isSelected = vm.condition == cond.key;
              return ChoiceChip(
                label: Text(cond.label),
                selected: isSelected,
                selectedColor: AppColors.creamBadgeBg,
                backgroundColor: AppColors.surfaceWarm,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.creamBadgeBorder
                      : AppColors.borderWarm,
                ),
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.creamBadgeText
                      : AppColors.textCharcoal,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
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
            decoration: _editorialInputDecoration(
              labelText: 'Mô tả khuyết điểm & độ sờn rách (Bắt buộc) *',
              alignLabelWithHint: true,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: DesignTokens.bottomNavElevation,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: vm.isSubmitting
                      ? null
                      : () => _submitEditForm(vm, submitForReview: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryVintageBrown,
                    side: const BorderSide(color: AppColors.borderWarm),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Lưu thay đổi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  key: const Key('btn_resubmit_action'),
                  onPressed: vm.isSubmitting
                      ? null
                      : () => _submitEditForm(vm, submitForReview: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasRejection
                        ? AppColors.priceCrimson
                        : AppColors.ctaTerracotta,
                    foregroundColor: AppColors.textLight,
                    elevation: 0,
                    shape: const StadiumBorder(),
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
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
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
            backgroundColor: AppColors.priceCrimson,
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
