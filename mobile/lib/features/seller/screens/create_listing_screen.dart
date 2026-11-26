import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/product_image_resolver.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../../catalog/models/category_model.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';
import '../models/seller_product_item_model.dart';
import '../viewmodels/seller_product_form_view_model.dart';

/// M-SL-03: Create Product Listing Screen ("Đăng bán đồ")
/// Enforces:
/// - BR-PR-01: Auction quantity locked to 1
/// - BR-PR-03: Mandatory defect info >= 5 chars, 5 condition tiers with % freshness
/// - Strict Moderation Workflow: All submissions enter PENDING_REVIEW (never auto-published)
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
  late TextEditingController _locationController;
  late TextEditingController _shippingController;
  late TextEditingController _startPriceController;
  late TextEditingController _bidIncrementController;

  static const List<Duration> _auctionDurationPresets = [
    Duration(minutes: 15),
    Duration(hours: 1),
    Duration(hours: 24),
    Duration(days: 3),
  ];

  static const List<_ConditionOption> _conditions = [
    _ConditionOption('NEW_WITH_TAGS', 'Mới còn tag (100%)'),
    _ConditionOption('LIKE_NEW', 'Như mới (95%)'),
    _ConditionOption('GOOD', 'Tốt (85%)'),
    _ConditionOption('FAIR', 'Khá (70%)'),
    _ConditionOption('VINTAGE_WORN', 'Dấu ấn vintage (60%)'),
  ];

  String _auctionDurationLabel(Duration duration) {
    if (duration == const Duration(minutes: 15)) return '15 phút (Demo)';
    if (duration == const Duration(hours: 1)) return '1 giờ';
    if (duration == const Duration(hours: 24)) return '24 giờ';
    if (duration == const Duration(days: 3)) return '3 ngày';
    return '${duration.inMinutes} phút';
  }

  Duration _selectedAuctionDuration(SellerProductFormViewModel vm) {
    final startsAt = vm.auctionStartsAt;
    final endsAt = vm.auctionEndsAt;

    if (startsAt != null && endsAt != null) {
      final currentDuration = endsAt.difference(startsAt);
      for (final preset in _auctionDurationPresets) {
        if (currentDuration == preset) return preset;
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _defectController = TextEditingController();
    _brandController = TextEditingController();
    _locationController = TextEditingController(text: 'Quận 1, TP. Hồ Chí Minh');
    _shippingController = TextEditingController(
      text: 'Giao hàng toàn quốc • Cho kiểm tra trước khi nhận',
    );
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
    _locationController.dispose();
    _shippingController.dispose();
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

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Đăng bán sản phẩm mới',
          style: AppTypography.headingMedium.copyWith(fontSize: 19),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showPreviewSheet(vm),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.pineDeep,
            ),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text(
              'Xem trước',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(vm),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Moderation workflow reminder banner
                _buildModerationNoticeBanner(),
                const SizedBox(height: 14),

                // 1. Listing Type Toggle (Fixed Price vs Auction)
                _buildListingTypeSelector(vm),
                const SizedBox(height: 16),

                // 2. Photo Upload Section (Up to 10 photos + Cover Selection)
                _buildPhotosSection(vm),
                const SizedBox(height: 16),

                // 3. Basic Information Card
                _buildBasicInfoSection(vm, isAuction),
                const SizedBox(height: 16),

                // 4. Condition & Defect Info (BR-PR-03)
                _buildConditionAndDefectSection(vm),
                const SizedBox(height: 16),

                // 5. Location & Shipping Options
                _buildLocationAndShippingSection(vm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModerationNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.creamBadgeSoft,
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(color: AppColors.creamBadgeBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: AppColors.pineDeep,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Mọi bài đăng mới đều trải qua bước kiểm duyệt (Đang chờ duyệt) trước khi hiển thị công khai trên sàn.',
              style: AppTypography.caption.copyWith(
                color: AppColors.creamBadgeText,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingTypeSelector(SellerProductFormViewModel vm) {
    final isFixed = vm.listingType == 'FIXED_PRICE';
    final isAuction = vm.listingType == 'AUCTION';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusFull,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => vm.setListingType('FIXED_PRICE'),
                  borderRadius: DesignTokens.borderRadiusFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isFixed
                          ? AppColors.ctaTerracotta
                          : Colors.transparent,
                      borderRadius: DesignTokens.borderRadiusFull,
                    ),
                    child: Center(
                      child: Text(
                        '🏷️ Bán giá cố định',
                        style: AppTypography.labelStrong.copyWith(
                          fontSize: 13.5,
                          color: isFixed
                              ? AppColors.textLight
                              : AppColors.textCharcoal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () {
                    vm.setListingType('AUCTION');
                    _quantityController.text = '1';
                    _setAuctionDuration(vm, const Duration(minutes: 15));
                  },
                  borderRadius: DesignTokens.borderRadiusFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isAuction ? AppColors.pineDeep : Colors.transparent,
                      borderRadius: DesignTokens.borderRadiusFull,
                    ),
                    child: Center(
                      child: Text(
                        '🔨 Đấu giá trực tiếp',
                        style: AppTypography.labelStrong.copyWith(
                          fontSize: 13.5,
                          color: isAuction
                              ? AppColors.creamBadgeBg
                              : AppColors.textCharcoal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isAuction) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  context.pushReplacement(AppRoutes.sellerCreateAuction),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.pineDeep,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.schedule_rounded, size: 15),
              label: const Text(
                'Mở trang Tạo phiên đấu giá chuyên sâu (chọn ngày/giờ mở) →',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotosSection(SellerProductFormViewModel vm) {
    final totalPhotos = vm.imageUrls.length + vm.imageFiles.length;

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
              Expanded(
                child: Text(
                  'Hình ảnh sản phẩm (Tối đa 10 ảnh)',
                  style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.creamBadgeSoft,
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: Text(
                  '$totalPhotos/10',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.creamBadgeText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chụp rõ mặt trước, nhãn mác và khuyết điểm. Nhấn vào ảnh để đặt làm Ảnh bìa.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: totalPhotos + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == totalPhotos) {
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openDemoPhotoLibrarySheet(vm),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pineDeep,
                  backgroundColor: AppColors.creamBadgeSoft,
                  side: const BorderSide(color: AppColors.creamBadgeBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text(
                  'Chọn ảnh mẫu Vintage',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: () => _promptAddImageUrl(vm),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.pineDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.link_rounded, size: 17),
                label: const Text(
                  'Thêm ảnh bằng URL',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDemoPhotoLibrarySheet(SellerProductFormViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius2xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thư viện ảnh sản phẩm Vintage',
                      style: AppTypography.headingSmall.copyWith(fontSize: 16.5),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'Chọn nhanh ảnh đồ si rõ nét để xem trước hoặc trình diễn đăng bài.',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: GridView.builder(
                  itemCount: ProductImageResolver.curatedDemoPhotos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, idx) {
                    final option = ProductImageResolver.curatedDemoPhotos[idx];
                    final alreadyAdded =
                        vm.imageUrls.contains(option.assetPath);
                    return InkWell(
                      onTap: () {
                        if (!alreadyAdded) {
                          vm.addImageUrl(option.assetPath);
                        }
                        Navigator.pop(ctx);
                      },
                      borderRadius: DesignTokens.borderRadiusMd,
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: DesignTokens.borderRadiusMd,
                                  child: Image.asset(
                                    option.assetPath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (alreadyAdded)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.pineDeep.withValues(
                                        alpha: 0.55,
                                      ),
                                      borderRadius: DesignTokens.borderRadiusMd,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPhotoThumbnail(SellerProductFormViewModel vm, int index) {
    final isPrimary = vm.imageUrls.isEmpty && index == 0;
    return GestureDetector(
      onTap: () => vm.setPrimaryImageFile(index),
      child: Stack(
        children: [
          Container(
            width: 92,
            height: 98,
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(
                color:
                    isPrimary ? AppColors.ctaTerracotta : AppColors.borderWarm,
                width: isPrimary ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd - 1),
              child: FutureBuilder<Uint8List>(
                future: vm.imageFiles[index].readAsBytes(),
                builder: (context, snapshot) => snapshot.hasData
                    ? Image.memory(
                        snapshot.data!,
                        width: 92,
                        height: 98,
                        fit: BoxFit.cover,
                      )
                    : Container(
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
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppColors.ctaTerracotta.withValues(alpha: 0.92)
                    : Colors.black54,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(DesignTokens.radiusMd - 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                isPrimary ? 'Ảnh bìa' : 'Đặt ảnh bìa',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton(SellerProductFormViewModel vm) {
    return InkWell(
      onTap: () => _pickImages(vm),
      borderRadius: DesignTokens.borderRadiusMd,
      child: Container(
        width: 92,
        height: 98,
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

    return GestureDetector(
      onTap: () => vm.setPrimaryImageUrl(index),
      child: Stack(
        children: [
          Container(
            width: 92,
            height: 98,
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(
                color:
                    isPrimary ? AppColors.ctaTerracotta : AppColors.borderWarm,
                width: isPrimary ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd - 1),
              child: RetroProductImage(
                imageUrl: url,
                title: vm.title,
                productId: index + 1,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppColors.ctaTerracotta.withValues(alpha: 0.92)
                    : Colors.black54,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(DesignTokens.radiusMd - 1),
                ),
              ),
              child: Text(
                isPrimary ? 'Ảnh bìa' : 'Đặt ảnh bìa',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
      ),
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
            hintText: 'https://...',
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
            decoration: _editorialInputDecoration(
              labelText: 'Tên sản phẩm vintage / retro *',
              hintText: 'VD: Áo khoác da Bomber Vintage thập niên 90s',
            ),
            validator: (v) {
              if (v == null || v.trim().length < 5) {
                return 'Tên sản phẩm phải có ít nhất 5 ký tự';
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
              hintText: 'Chất liệu, số đo, kiểu dáng, nguồn gốc, cách phối...',
              alignLabelWithHint: true,
            ),
            onChanged: (value) => vm.description = value,
          ),
          const SizedBox(height: 12),

          // Category Dropdown — active categories from taxonomy API with offline demo fallback.
          Builder(
            builder: (context) {
              final taxonomyVm = ref.watch(catalogSearchViewModelProvider);
              final taxonomy = taxonomyVm.taxonomy;
              final apiCategories = taxonomy == null
                  ? <CategoryModel>[]
                  : _flattenCategories(taxonomy.categories);
              final categories = apiCategories.isNotEmpty
                  ? apiCategories
                  : (!taxonomyVm.isLoadingTaxonomy
                      ? RetroDemoMarketplaceStore.fallbackCategories
                      : <CategoryModel>[]);
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
                onChanged: taxonomyVm.isLoadingTaxonomy || categories.isEmpty
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

          // Brand (Optional)
          TextFormField(
            controller: _brandController,
            decoration: _editorialInputDecoration(
              labelText: 'Thương hiệu / Nhãn hiệu (Tùy chọn)',
              hintText: 'VD: Levi\'s, Burberry, Harley Davidson...',
            ),
            onChanged: (v) => vm.brandName = v.trim(),
          ),
          const SizedBox(height: 14),

          // Pricing and Quantity based on Listing Type
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
                      hintText: 'VD: 350000',
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
            // BR-PR-01: Auction Form with strictly locked quantity = 1
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.creamBadgeSoft,
                borderRadius: DesignTokens.borderRadiusMd,
                border: Border.all(color: AppColors.creamBadgeBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.creamBadgeText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'BR-PR-01: Sản phẩm đấu giá là độc bản secondhand, số lượng khả dụng cố định là 1.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.creamBadgeText,
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
                    decoration: _editorialInputDecoration(
                      labelText: 'Giá khởi điểm (VNĐ) *',
                      hintText: 'VD: 100000',
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
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _bidIncrementController,
                    keyboardType: TextInputType.number,
                    decoration: _editorialInputDecoration(
                      labelText: 'Bước giá tối thiểu *',
                      hintText: '10000',
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
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời lượng phiên đấu giá',
                  style: AppTypography.labelStrong.copyWith(fontSize: 13),
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
                      selectedColor: AppColors.pineDeep,
                      backgroundColor: AppColors.surfaceWarm,
                      side: BorderSide(
                        color: selected
                            ? AppColors.pineDeep
                            : AppColors.borderWarm,
                      ),
                      shape: const StadiumBorder(),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.creamBadgeBg
                            : AppColors.textCharcoal,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (value) {
                        if (!value) return;
                        _setAuctionDuration(vm, duration);
                      },
                    );
                  }).toList(),
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
            children: [
              Expanded(
                child: Text(
                  'Tình trạng đồ si & Minh bạch khuyết điểm',
                  style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
                ),
              ),
              const SizedBox(width: 4),
              const Text('🔍'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn 1 trong 5 mức chuẩn mực tình trạng sản phẩm:',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
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
          const SizedBox(height: 8),
          Text(
            ProductImageResolver.conditionDescription(vm.condition),
            style: AppTypography.caption.copyWith(
              color: AppColors.pineDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // BR-PR-03: Mandatory Defect Info (>= 5 chars)
          TextFormField(
            key: const Key('input_defect_info'),
            controller: _defectController,
            maxLines: 3,
            decoration: _editorialInputDecoration(
              labelText: 'Mô tả khuyết điểm & độ sờn rách (Bắt buộc) *',
              hintText:
                  'VD: Có vết xước nhẹ 2cm ở ve áo trái, khóa kéo đồng trơn tru không lỗi.',
              helperText:
                  'Bắt buộc tối thiểu 5 ký tự để bảo vệ quyền lợi người mua & người bán.',
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

  Widget _buildLocationAndShippingSection(SellerProductFormViewModel vm) {
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
            'Khu vực & Giao nhận',
            style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: _editorialInputDecoration(
              labelText: 'Khu vực bán / Quận, Thành phố',
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            onChanged: vm.setLocation,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shippingController,
            decoration: _editorialInputDecoration(
              labelText: 'Phương thức giao hàng',
              prefixIcon: const Icon(Icons.local_shipping_outlined),
            ),
            onChanged: vm.setShippingNote,
          ),
        ],
      ),
    );
  }

  void _showPreviewSheet(SellerProductFormViewModel vm) {
    final previewTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Sản phẩm Vintage chưa đặt tên';
    final previewPrice = vm.listingType == 'AUCTION'
        ? (double.tryParse(_startPriceController.text.trim()) ?? 0)
        : (double.tryParse(_priceController.text.trim()) ?? 0);
    final previewImage = vm.imageUrls.isNotEmpty
        ? vm.imageUrls.first
        : ProductImageResolver.fallbackAssetFor(
            title: previewTitle,
            categoryName: vm.categoryName,
            id: 1,
          );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius2xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Xem trước bài đăng của bạn',
                      style: AppTypography.headingSmall.copyWith(fontSize: 17),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 210,
                  height: 332,
                  child: RetroProductCard(
                    id: 999,
                    title: previewTitle,
                    price: previewPrice,
                    primaryImageUrl: previewImage,
                    condition: vm.condition,
                    categoryName: vm.categoryName.isNotEmpty
                        ? vm.categoryName
                        : 'Vintage',
                    distanceLabel: '0,5 km',
                    showConditionPercent: true,
                    sellerName: 'Tiệm của bạn',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.creamBadgeSoft,
                  borderRadius: DesignTokens.borderRadiusMd,
                  border: Border.all(color: AppColors.creamBadgeBorder),
                ),
                child: Row(
                  children: [
                    const StatusPillBadge(
                      status: 'PENDING_REVIEW',
                      isCompact: true,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Khi gửi, bài đăng sẽ chuyển vào hàng đợi duyệt của quản trị viên.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.creamBadgeText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaTerracotta,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _submitForm(vm, submitForReview: true);
                  },
                  child: const Text(
                    'Xác nhận gửi phê duyệt',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(SellerProductFormViewModel vm) {
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
                  key: const Key('btn_save_draft'),
                  onPressed: vm.isSubmitting
                      ? null
                      : () => _submitForm(vm, submitForReview: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryVintageBrown,
                    side: const BorderSide(color: AppColors.borderWarm),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Lưu bản nháp',
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
                  key: const Key('btn_submit_for_review'),
                  onPressed: vm.isSubmitting
                      ? null
                      : () => _submitForm(vm, submitForReview: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaTerracotta,
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
                      : const Text(
                          'Gửi phê duyệt ngay',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm(
    SellerProductFormViewModel vm, {
    required bool submitForReview,
  }) async {
    vm.title = _titleController.text.trim();
    vm.description = _descriptionController.text.trim();
    vm.defectInfo = _defectController.text.trim();
    vm.location = _locationController.text.trim();
    vm.shippingNote = _shippingController.text.trim();

    if (submitForReview) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    } else {
      if (vm.title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập tên sản phẩm trước khi lưu nháp.'),
          ),
        );
        return;
      }
    }

    final res = await vm.submit(submitForReview: submitForReview);
    if (!mounted) return;

    if (res != null) {
      if (submitForReview) {
        await _showPendingModerationDialog(res);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu bản nháp "${res.title}".')),
        );
        context.pushReplacement(AppRoutes.sellerListingsPath('DRAFT'));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.priceCrimson,
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

  Future<void> _showPendingModerationDialog(SellerProductItemModel item) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
          side: const BorderSide(color: AppColors.borderWarm),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.creamBadgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.creamBadgeBorder),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 30,
                color: AppColors.pineDeep,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Đã gửi bài đăng thành công',
              textAlign: TextAlign.center,
              style: AppTypography.headingSmall.copyWith(fontSize: 17.5),
            ),
            const SizedBox(height: 8),
            const StatusPillBadge(status: 'PENDING_REVIEW'),
            const SizedBox(height: 10),
            Text(
              'Đã gửi bài đăng. Bài đăng của bạn đang chờ duyệt.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '"${item.title}" (${VndFormatter.format(item.price)}) sẽ tự động hiển thị trên sàn ngay sau khi quản trị viên phê duyệt.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pineDeep,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pushReplacement(
                  AppRoutes.sellerListingsPath('PENDING_REVIEW'),
                );
              },
              child: const Text(
                'Xem danh sách chờ duyệt',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionOption {
  final String key;
  final String label;

  const _ConditionOption(this.key, this.label);
}
