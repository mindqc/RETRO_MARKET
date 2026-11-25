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
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../../catalog/models/category_model.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';
import '../../seller/models/seller_product_item_model.dart';
import '../../seller/viewmodels/seller_product_form_view_model.dart';

/// Dedicated "Tạo phiên đấu giá" screen for sellers.
/// Enforces:
/// - BR-PR-01: Quantity strictly locked to 1
/// - BR-PR-03: Mandatory condition & defect disclosure (>= 5 chars)
/// - Full schedule configuration (start date, start time, duration / end time)
/// - Strict Moderation Workflow: Create auction -> PENDING_REVIEW -> Approved -> Scheduled -> Live
class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() =>
      _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _defectController;
  late TextEditingController _startPriceController;
  late TextEditingController _bidIncrementController;
  late TextEditingController _reservePriceController;

  DateTime _startDateTime = DateTime.now().add(const Duration(minutes: 30));
  Duration _duration = const Duration(hours: 24);

  static const List<Duration> _durationOptions = [
    Duration(minutes: 15),
    Duration(hours: 1),
    Duration(hours: 6),
    Duration(hours: 24),
    Duration(days: 3),
  ];

  static const List<double> _incrementPresets = [
    10000,
    20000,
    50000,
    100000,
  ];

  static const List<_AuctionConditionOption> _conditions = [
    _AuctionConditionOption('NEW_WITH_TAGS', 'Mới còn tag (100%)'),
    _AuctionConditionOption('LIKE_NEW', 'Như mới (95%)'),
    _AuctionConditionOption('GOOD', 'Tốt (85%)'),
    _AuctionConditionOption('FAIR', 'Khá (70%)'),
    _AuctionConditionOption('VINTAGE_WORN', 'Dấu ấn vintage (60%)'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _defectController = TextEditingController();
    _startPriceController = TextEditingController();
    _bidIncrementController = TextEditingController(text: '20000');
    _reservePriceController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(sellerProductFormViewModelProvider);
      vm.initForCreate(initialListingType: 'AUCTION');
      vm.auctionStartsAt = _startDateTime;
      vm.auctionEndsAt = _startDateTime.add(_duration);
      vm.minBidIncrement = 20000;
      ref.read(catalogSearchViewModelProvider).loadTaxonomy();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _defectController.dispose();
    _startPriceController.dispose();
    _bidIncrementController.dispose();
    _reservePriceController.dispose();
    super.dispose();
  }

  DateTime get _endDateTime => _startDateTime.add(_duration);

  void _syncScheduleToVm(SellerProductFormViewModel vm) {
    vm.auctionStartsAt = _startDateTime;
    vm.auctionEndsAt = _endDateTime;
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$hh:$min • $dd/$mm/${local.year}';
  }

  String _durationLabel(Duration d) {
    if (d == const Duration(minutes: 15)) return '15 phút (Demo)';
    if (d == const Duration(hours: 1)) return '1 giờ';
    if (d == const Duration(hours: 6)) return '6 giờ';
    if (d == const Duration(hours: 24)) return '24 giờ';
    if (d == const Duration(days: 3)) return '3 ngày';
    return '${d.inMinutes} phút';
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

  Future<void> _pickStartDate(SellerProductFormViewModel vm) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDateTime.isBefore(now) ? now : _startDateTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked == null) return;
    setState(() {
      _startDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _startDateTime.hour,
        _startDateTime.minute,
      );
      _syncScheduleToVm(vm);
    });
  }

  Future<void> _pickStartTime(SellerProductFormViewModel vm) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime),
    );
    if (picked == null) return;
    setState(() {
      _startDateTime = DateTime(
        _startDateTime.year,
        _startDateTime.month,
        _startDateTime.day,
        picked.hour,
        picked.minute,
      );
      _syncScheduleToVm(vm);
    });
  }

  Future<void> _pickImages(SellerProductFormViewModel vm) async {
    try {
      final selected = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (!mounted || selected.isEmpty) return;
      vm.addImageFiles(selected);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
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

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Tạo phiên đấu giá',
          style: AppTypography.headingMedium.copyWith(fontSize: 19),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showAuctionPreviewSheet(vm),
            style: TextButton.styleFrom(foregroundColor: AppColors.pineDeep),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text(
              'Xem trước',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(vm),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkflowStepperBanner(),
                const SizedBox(height: 14),
                _buildPhotosCard(vm),
                const SizedBox(height: 14),
                _buildProductInfoCard(vm),
                const SizedBox(height: 14),
                _buildPricingAndScheduleCard(vm),
                const SizedBox(height: 14),
                _buildConditionAndDefectCard(vm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowStepperBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pineDeep,
        borderRadius: DesignTokens.borderRadiusBanner,
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                size: 18,
                color: AppColors.starGold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Quy trình kiểm duyệt phiên đấu giá',
                  style: AppTypography.labelStrong.copyWith(
                    color: Colors.white,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.creamBadgeBg,
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: const Text(
                  'SL cố định: 1',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.creamBadgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo phiên → Đang chờ duyệt → Được duyệt → Sắp mở (giữ chỗ) → Đang đấu giá trực tiếp',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosCard(SellerProductFormViewModel vm) {
    final total = vm.imageUrls.length + vm.imageFiles.length;
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
                'Hình ảnh món đồ đấu giá',
                style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.creamBadgeSoft,
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: Text(
                  '$total/10',
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
            'Chụp cận cảnh chi tiết cổ điển, tem nhãn & khuyết điểm. Nhấn vào ảnh để chọn Ảnh bìa.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: total + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == total) {
                  return InkWell(
                    onTap: () => _pickImages(vm),
                    borderRadius: DesignTokens.borderRadiusMd,
                    child: Container(
                      width: 92,
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
                            size: 25,
                          ),
                          SizedBox(height: 4),
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

                if (index < vm.imageUrls.length) {
                  final url = vm.imageUrls[index];
                  final isPrimary = index == 0;
                  return GestureDetector(
                    onTap: () => vm.setPrimaryImageUrl(index),
                    child: Stack(
                      children: [
                        Container(
                          width: 92,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: DesignTokens.borderRadiusMd,
                            border: Border.all(
                              color: isPrimary
                                  ? AppColors.ctaTerracotta
                                  : AppColors.borderWarm,
                              width: isPrimary ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMd - 1,
                            ),
                            child: RetroProductImage(
                              imageUrl: url,
                              title: vm.title,
                              productId: index + 1,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => vm.removeImageUrl(index),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
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
                                  ? AppColors.ctaTerracotta
                                  : Colors.black54,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(
                                  DesignTokens.radiusMd - 1,
                                ),
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
                      ],
                    ),
                  );
                }

                final fileIdx = index - vm.imageUrls.length;
                final isPrimary = vm.imageUrls.isEmpty && fileIdx == 0;
                return GestureDetector(
                  onTap: () => vm.setPrimaryImageFile(fileIdx),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: DesignTokens.borderRadiusMd,
                        child: FutureBuilder<Uint8List>(
                          future: vm.imageFiles[fileIdx].readAsBytes(),
                          builder: (context, snap) => snap.hasData
                              ? Image.memory(
                                  snap.data!,
                                  width: 92,
                                  height: 96,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 92,
                                  height: 96,
                                  color: AppColors.surfaceWarm,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => vm.removeImageFile(fileIdx),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
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
                            color: AppColors.ctaTerracotta,
                            child: const Text(
                              'Ảnh bìa',
                              textAlign: TextAlign.center,
                              style: TextStyle(
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
              },
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openDemoPhotoPicker(vm),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pineDeep,
              backgroundColor: AppColors.creamBadgeSoft,
              side: const BorderSide(color: AppColors.creamBadgeBorder),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 16),
            label: const Text(
              'Chọn ảnh mẫu Vintage',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _openDemoPhotoPicker(SellerProductFormViewModel vm) {
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
              Text(
                'Chọn ảnh sản phẩm đấu giá mẫu',
                style: AppTypography.headingSmall.copyWith(fontSize: 16.5),
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
                    final item = ProductImageResolver.curatedDemoPhotos[idx];
                    return InkWell(
                      onTap: () {
                        vm.addImageUrl(item.assetPath);
                        Navigator.pop(ctx);
                      },
                      borderRadius: DesignTokens.borderRadiusMd,
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: DesignTokens.borderRadiusMd,
                              child: Image.asset(
                                item.assetPath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(fontSize: 9.5),
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

  Widget _buildProductInfoCard(SellerProductFormViewModel vm) {
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
            'Thông tin món đồ độc bản',
            style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _titleController,
            decoration: _inputDecoration(
              labelText: 'Tên phiên đấu giá / Sản phẩm *',
              hintText: 'VD: Máy ảnh Film Canon AE-1 Program 1981 kèm lens 50mm',
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
            maxLines: 3,
            decoration: _inputDecoration(
              labelText: 'Mô tả & câu chuyện vintage',
              hintText: 'Nguồn gốc, năm sản xuất, tình trạng hoạt động...',
              alignLabelWithHint: true,
            ),
            onChanged: (v) => vm.description = v.trim(),
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final taxonomyVm = ref.watch(catalogSearchViewModelProvider);
              final apiCats = taxonomyVm.taxonomy == null
                  ? <CategoryModel>[]
                  : _flattenCategories(taxonomyVm.taxonomy!.categories);
              final categories = apiCats.isNotEmpty
                  ? apiCats
                  : RetroDemoMarketplaceStore.fallbackCategories;
              final hasSelected = categories.any((c) => c.id == vm.categoryId);

              return DropdownButtonFormField<int>(
                value: hasSelected ? vm.categoryId : null,
                isExpanded: true,
                decoration: _inputDecoration(
                  labelText: 'Danh mục *',
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                hint: const Text('Chọn danh mục sản phẩm'),
                items: categories
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final found = categories.firstWhere((c) => c.id == id);
                  vm.setCategory(found.id, found.name);
                },
                validator: (v) =>
                    v == null ? 'Vui lòng chọn danh mục sản phẩm' : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingAndScheduleCard(SellerProductFormViewModel vm) {
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
            'Thiết lập giá & Lịch mở phiên',
            style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startPriceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    labelText: 'Giá khởi điểm (VNĐ) *',
                    hintText: 'VD: 500000',
                  ),
                  validator: (v) {
                    final p = double.tryParse(v ?? '');
                    if (p == null || p <= 0) return 'Giá KĐ > 0';
                    return null;
                  },
                  onChanged: (v) {
                    final p = double.tryParse(v) ?? 0;
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
                  decoration: _inputDecoration(
                    labelText: 'Bước giá tối thiểu *',
                    hintText: '20000',
                  ),
                  validator: (v) {
                    final inc = double.tryParse(v ?? '');
                    if (inc == null || inc < 1000) return '>= 1.000đ';
                    return null;
                  },
                  onChanged: (v) =>
                      vm.minBidIncrement = double.tryParse(v) ?? 20000,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: _incrementPresets.map((preset) {
              final selected =
                  (double.tryParse(_bidIncrementController.text) ?? 0) ==
                      preset;
              return ChoiceChip(
                label: Text('+${VndFormatter.format(preset)}'),
                selected: selected,
                selectedColor: AppColors.creamBadgeBg,
                backgroundColor: AppColors.surfaceWarm,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.creamBadgeText
                      : AppColors.textCharcoal,
                ),
                onSelected: (_) {
                  setState(() {
                    _bidIncrementController.text = preset.toInt().toString();
                    vm.minBidIncrement = preset;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _reservePriceController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              labelText: 'Giá sàn bảo lưu (Tùy chọn)',
              hintText: 'Bỏ trống nếu không đặt giá sàn',
              helperText:
                  'Mức giá tối thiểu để phiên đấu giá được chốt bán thành công.',
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v.trim());
              vm.reservePrice = (parsed != null && parsed > 0) ? parsed : null;
            },
          ),
          const SizedBox(height: 16),

          // Start date & start time pickers
          Text(
            'Thời điểm mở phiên (Sắp diễn ra)',
            style: AppTypography.labelStrong.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickStartDate(vm),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textCharcoal,
                    backgroundColor: AppColors.surfaceWarm,
                    side: const BorderSide(color: AppColors.borderWarm),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignTokens.borderRadiusMd,
                    ),
                  ),
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.pineDeep,
                  ),
                  label: Text(
                    '${_startDateTime.day.toString().padLeft(2, '0')}/${_startDateTime.month.toString().padLeft(2, '0')}/${_startDateTime.year}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickStartTime(vm),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textCharcoal,
                    backgroundColor: AppColors.surfaceWarm,
                    side: const BorderSide(color: AppColors.borderWarm),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignTokens.borderRadiusMd,
                    ),
                  ),
                  icon: const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.pineDeep,
                  ),
                  label: Text(
                    '${_startDateTime.hour.toString().padLeft(2, '0')}:${_startDateTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              ActionChip(
                label: const Text('Sau 15 phút'),
                backgroundColor: AppColors.creamBadgeSoft,
                side: const BorderSide(color: AppColors.creamBadgeBorder),
                labelStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.creamBadgeText,
                ),
                onPressed: () {
                  setState(() {
                    _startDateTime = DateTime.now().add(
                      const Duration(minutes: 15),
                    );
                    _syncScheduleToVm(vm);
                  });
                },
              ),
              ActionChip(
                label: const Text('Tối nay 20:00'),
                backgroundColor: AppColors.creamBadgeSoft,
                side: const BorderSide(color: AppColors.creamBadgeBorder),
                labelStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.creamBadgeText,
                ),
                onPressed: () {
                  final now = DateTime.now();
                  var target = DateTime(now.year, now.month, now.day, 20, 0);
                  if (target.isBefore(now)) {
                    target = target.add(const Duration(days: 1));
                  }
                  setState(() {
                    _startDateTime = target;
                    _syncScheduleToVm(vm);
                  });
                },
              ),
              ActionChip(
                label: const Text('Ngày mai 10:00'),
                backgroundColor: AppColors.creamBadgeSoft,
                side: const BorderSide(color: AppColors.creamBadgeBorder),
                labelStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.creamBadgeText,
                ),
                onPressed: () {
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  setState(() {
                    _startDateTime = DateTime(
                      tomorrow.year,
                      tomorrow.month,
                      tomorrow.day,
                      10,
                      0,
                    );
                    _syncScheduleToVm(vm);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Thời lượng phiên đấu giá',
            style: AppTypography.labelStrong.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durationOptions.map((opt) {
              final selected = _duration == opt;
              return ChoiceChip(
                label: Text(_durationLabel(opt)),
                selected: selected,
                selectedColor: AppColors.pineDeep,
                backgroundColor: AppColors.surfaceWarm,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.creamBadgeBg
                      : AppColors.textCharcoal,
                ),
                onSelected: (_) {
                  setState(() {
                    _duration = opt;
                    _syncScheduleToVm(vm);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.creamBadgeSoft,
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(color: AppColors.creamBadgeBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bắt đầu: ${_formatDateTime(_startDateTime)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.creamBadgeText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kết thúc dự kiến: ${_formatDateTime(_endDateTime)} (+2 phút Anti-Sniping)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionAndDefectCard(SellerProductFormViewModel vm) {
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
            'Tình trạng & Minh bạch khuyết điểm',
            style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _conditions.map((cond) {
              final selected = vm.condition == cond.key;
              return ChoiceChip(
                label: Text(cond.label),
                selected: selected,
                selectedColor: AppColors.creamBadgeBg,
                backgroundColor: AppColors.surfaceWarm,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.creamBadgeText
                      : AppColors.textCharcoal,
                ),
                onSelected: (_) => vm.setCondition(cond.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _defectController,
            maxLines: 3,
            decoration: _inputDecoration(
              labelText: 'Mô tả khuyết điểm / dấu vết thời gian (Bắt buộc) *',
              hintText:
                  'VD: Có vết trầy nhẹ mặt đáy máy, đo sáng và tốc độ màn trập chuẩn xác.',
              helperText: 'Bắt buộc tối thiểu 5 ký tự (BR-PR-03).',
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

  void _showAuctionPreviewSheet(SellerProductFormViewModel vm) {
    final previewTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Phiên đấu giá đồ cổ chưa đặt tên';
    final startPrice = double.tryParse(_startPriceController.text.trim()) ?? 0;
    final previewImg = vm.imageUrls.isNotEmpty
        ? vm.imageUrls.first
        : ProductImageResolver.fallbackAssetFor(
            title: previewTitle,
            categoryName: vm.categoryName,
            id: 9,
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
                      'Xem trước thẻ phiên đấu giá',
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
                  width: 245,
                  height: 300,
                  child: RetroAuctionCard(
                    id: 9999,
                    title: previewTitle,
                    currentBid: startPrice,
                    startingPrice: startPrice,
                    bidCount: 0,
                    watchCount: 1,
                    startsAt: _startDateTime,
                    endsAt: _endDateTime,
                    primaryImageUrl: previewImg,
                    categoryName: vm.categoryName,
                    status: 'SCHEDULED',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pineDeep,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleSubmit(vm);
                  },
                  child: const Text(
                    'Xác nhận gửi duyệt phiên đấu giá',
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

  Widget _buildBottomBar(SellerProductFormViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: DesignTokens.bottomNavElevation,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: vm.isSubmitting ? null : () => _handleSubmit(vm),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pineDeep,
              foregroundColor: AppColors.creamBadgeBg,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            icon: vm.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.creamBadgeBg,
                    ),
                  )
                : const Icon(Icons.gavel_rounded, size: 19),
            label: const Text(
              'Gửi duyệt phiên đấu giá',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(SellerProductFormViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    vm.listingType = 'AUCTION';
    vm.quantity = 1;
    vm.title = _titleController.text.trim();
    vm.description = _descriptionController.text.trim();
    vm.defectInfo = _defectController.text.trim();
    final startPrice = double.tryParse(_startPriceController.text.trim()) ?? 0;
    vm.startingPrice = startPrice;
    vm.price = startPrice;
    vm.minBidIncrement =
        double.tryParse(_bidIncrementController.text.trim()) ?? 20000;
    final reserve = double.tryParse(_reservePriceController.text.trim());
    vm.reservePrice = (reserve != null && reserve > 0) ? reserve : null;
    _syncScheduleToVm(vm);

    final res = await vm.submit(submitForReview: true);
    if (!mounted) return;

    if (res != null) {
      await _showAuctionPendingDialog(res);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.priceCrimson,
          content: Text(
            vm.state.maybeWhen(
              error: (err, _) => err,
              orElse: () => 'Không thể gửi phiên đấu giá. Vui lòng kiểm tra lại.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showAuctionPendingDialog(SellerProductItemModel item) async {
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
                color: AppColors.pineDeep,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.starGold, width: 1.5),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 28,
                color: AppColors.creamBadgeBg,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Đã gửi phiên đấu giá thành công',
              textAlign: TextAlign.center,
              style: AppTypography.headingSmall.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            const StatusPillBadge(status: 'PENDING_REVIEW'),
            const SizedBox(height: 10),
            Text(
              'Đã gửi bài đăng. Bài đăng của bạn đang chờ duyệt.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sau khi được quản trị viên duyệt, phiên "${item.title}" sẽ xuất hiện ở mục Sắp mở để người mua đăng ký giữ chỗ trước khi mở đấu giá lúc ${_formatDateTime(_startDateTime)}.',
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
                'Xem bài đăng chờ duyệt',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuctionConditionOption {
  final String key;
  final String label;

  const _AuctionConditionOption(this.key, this.label);
}
