import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/condition_badge.dart';
import '../../../core/widgets/verification_badge.dart';
import '../models/product_detail_model.dart';
import '../models/product_image_model.dart';
import 'full_screen_zoom_viewer.dart';

/// Modal Bottom Sheet displaying secondhand condition breakdown and defect disclosures (M-PD-02).
class DefectVerificationModal extends StatelessWidget {
  final ProductDetailModel product;

  const DefectVerificationModal({super.key, required this.product});

  static Future<void> show(BuildContext context, ProductDetailModel product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DefectVerificationModal(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defectImages = product.images
        .where((img) => img.imageType == 'DEFECT_CLOSEUP')
        .toList();
    final allImages = product.images.isNotEmpty
        ? product.images
        : [
            ProductImageModel(
              id: 0,
              imageUrl: product.primaryImageUrl,
              imageType: 'GALLERY',
            ),
          ];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radius2xl),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderWarm,
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: AppColors.pineDeep,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Phiếu Kiểm Định Đồ Si',
                          style: AppTypography.headingMedium.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderWarm),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product.primaryImageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.surfaceWarm,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    ConditionBadge(
                                      condition: product.condition,
                                    ),
                                    const SizedBox(width: 8),
                                    VerificationBadge(
                                      status: product.verificationLevel,
                                      isCompact: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.creamBadgeSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.creamBadgeBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.report_problem_outlined,
                                  color: AppColors.ctaTerracotta,
                                  size: 19,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Mô tả khuyết điểm & hao mòn thực tế',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.creamBadgeText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.defectInfo != null &&
                                      product.defectInfo!.trim().isNotEmpty
                                  ? product.defectInfo!
                                  : 'Người bán xác nhận sản phẩm không có khuyết điểm đáng kể ngoài hao mòn tự nhiên theo thời gian.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textCharcoal,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Thang Chuẩn Tình Trạng Đồ Si (5 Mức)',
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildConditionTierItem(
                        code: 'NEW_WITH_TAGS',
                        name: 'Mới còn tag (New With Tags)',
                        description: 'Mới 100%, còn nguyên tem mác hãng, chưa qua giặt hoặc mặc thử.',
                        isSelected:
                            product.condition.toUpperCase() == 'NEW_WITH_TAGS',
                      ),
                      _buildConditionTierItem(
                        code: 'LIKE_NEW',
                        name: 'Như mới (Like New 95% - 99%)',
                        description: 'Đã bỏ tag hoặc mặc 1-2 lần chụp ảnh, form dáng và vải nguyên bản hoàn hảo.',
                        isSelected:
                            product.condition.toUpperCase() == 'LIKE_NEW',
                      ),
                      _buildConditionTierItem(
                        code: 'GOOD',
                        name: 'Tốt (Good)',
                        description: 'Đã sử dụng nhẹ, không có vết rách lớn, không mất cúc, màu sắc còn đẹp.',
                        isSelected: product.condition.toUpperCase() == 'GOOD',
                      ),
                      _buildConditionTierItem(
                        code: 'FAIR',
                        name: 'Trung bình (Fair)',
                        description: 'Có khuyết điểm rõ (sờn cổ áo, mất cúc phụ, hoặc vết ố vintage nhẹ đã mô tả).',
                        isSelected: product.condition.toUpperCase() == 'FAIR',
                      ),
                      _buildConditionTierItem(
                        code: 'VINTAGE_WORN',
                        name: 'Vintage sờn rách tự nhiên (Vintage Worn)',
                        description: 'Hiệu ứng bạc màu, rách gấu hoặc sờn thời gian mang giá trị sưu tầm đặc thù.',
                        isSelected:
                            product.condition.toUpperCase() == 'VINTAGE_WORN',
                      ),
                      const SizedBox(height: 18),
                      Text(
                        defectImages.isNotEmpty
                            ? 'Ảnh chụp cận cảnh vết lỗi (${defectImages.length})'
                            : 'Tất cả ảnh chi tiết sản phẩm (${allImages.length})',
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bấm vào ảnh để kích hoạt kính lúp soi cận cảnh (Pinch-to-zoom 400%).',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final currentImages = defectImages.isNotEmpty
                              ? defectImages
                              : allImages;
                          const spacing = 8.0;
                          final tileSize =
                              ((constraints.maxWidth - spacing * 2) / 3)
                                  .floorToDouble()
                                  .clamp(0.0, double.infinity);
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: List.generate(currentImages.length, (
                              idx,
                            ) {
                              final img = currentImages[idx];
                              return SizedBox(
                                width: tileSize,
                                height: tileSize,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => FullScreenZoomViewer(
                                          images: currentImages,
                                          initialIndex: idx,
                                          title: product.title,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          img.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                color: AppColors.surfaceWarm,
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 4,
                                        bottom: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.zoom_in_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                      if (img.imageType == 'DEFECT_CLOSEUP')
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.ctaTerracotta,
                                              borderRadius:
                                                  DesignTokens.borderRadiusFull,
                                            ),
                                            child: const Text(
                                              'Vết lỗi',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConditionTierItem({
    required String code,
    required String name,
    required String description,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.creamBadgeSoft : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.ctaTerracotta : AppColors.borderWarm,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            size: 18,
            color: isSelected ? AppColors.ctaTerracotta : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.ctaTerracotta
                            : AppColors.textCharcoal,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ctaTerracotta,
                          borderRadius: DesignTokens.borderRadiusFull,
                        ),
                        child: const Text(
                          'Sản phẩm này',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
