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

  const DefectVerificationModal({
    super.key,
    required this.product,
  });

  /// Static helper to display this modal
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
    final defectImages = product.images.where((img) => img.imageType == 'DEFECT_CLOSEUP').toList();
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
              top: Radius.circular(DesignTokens.radiusLg),
            ),
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: DesignTokens.spaceSm, bottom: DesignTokens.spaceXs),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderWarm,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceLg,
                  vertical: DesignTokens.spaceSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified_outlined, color: AppColors.secondaryPineGreen, size: 24),
                        SizedBox(width: DesignTokens.spaceSm),
                        Text(
                          'Phiếu Kiểm Định Đồ Si',
                          style: TextStyle(
                            fontFamily: AppTypography.fontHeading,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderWarm),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  children: [
                    // Product basic snippet
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          child: Image.network(
                            product.primaryImageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 64,
                              height: 64,
                              color: AppColors.surfaceWarm,
                              child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ConditionBadge(condition: product.condition),
                                  const SizedBox(width: DesignTokens.spaceSm),
                                  VerificationBadge(status: product.verificationLevel, isCompact: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: DesignTokens.spaceLg),

                    // Section 1: Detailed Defect Disclosure (BR-PR-03)
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spaceMd),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        border: Border.all(color: const Color(0xFFFFE799)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.report_problem_outlined, color: Color(0xFFB47800), size: 20),
                              SizedBox(width: DesignTokens.spaceSm),
                              Text(
                                'Mô tả khuyết điểm & hao mòn thực tế',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8A5B00),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.spaceSm),
                          Text(
                            product.defectInfo != null && product.defectInfo!.trim().isNotEmpty
                                ? product.defectInfo!
                                : 'Người bán xác nhận sản phẩm không có khuyết điểm đáng kể ngoài hao mòn tự nhiên theo thời gian.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoal, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spaceLg),

                    // Section 2: Standard 5-Tier Secondhand Condition Reference
                    const Text(
                      'Thang Chuẩn Tình Trạng Đồ Si (5 Mức)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    _buildConditionTierItem(
                      code: 'NEW_WITH_TAGS',
                      name: 'Mới còn tag (New With Tags)',
                      description: 'Mới 100%, còn nguyên tem mác hãng, chưa qua giặt hoặc mặc thử.',
                      isSelected: product.condition.toUpperCase() == 'NEW_WITH_TAGS',
                    ),
                    _buildConditionTierItem(
                      code: 'LIKE_NEW',
                      name: 'Như mới (Like New 95% - 99%)',
                      description: 'Đã bỏ tag hoặc mặc 1-2 lần chụp ảnh, form dáng và vải nguyên bản hoàn hảo.',
                      isSelected: product.condition.toUpperCase() == 'LIKE_NEW',
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
                      isSelected: product.condition.toUpperCase() == 'VINTAGE_WORN',
                    ),

                    const SizedBox(height: DesignTokens.spaceLg),

                    // Section 3: Evidence & Closeup Photos
                    Text(
                      defectImages.isNotEmpty
                          ? 'Ảnh chụp cận cảnh vết lỗi (${defectImages.length})'
                          : 'Tất cả ảnh chi tiết sản phẩm (${allImages.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      'Bấm vào ảnh để kích hoạt kính lúp soi cận cảnh (Pinch-to-zoom 400%).',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: defectImages.isNotEmpty ? defectImages.length : allImages.length,
                      itemBuilder: (context, idx) {
                        final currentImages = defectImages.isNotEmpty ? defectImages : allImages;
                        final img = currentImages[idx];
                        return GestureDetector(
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
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                child: Image.network(
                                  img.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppColors.surfaceWarm,
                                    child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                ),
                              ),
                              if (img.imageType == 'DEFECT_CLOSEUP')
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB47800),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Vết lỗi',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: DesignTokens.spaceXl),
                  ],
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
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
      padding: const EdgeInsets.all(DesignTokens.spaceSm),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF4EFE6) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
          color: isSelected ? AppColors.primaryTerracotta : AppColors.borderWarm,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? AppColors.primaryTerracotta : AppColors.textMuted,
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? AppColors.primaryTerracottaDark : AppColors.textCharcoal,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTerracotta,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Sản phẩm này',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
