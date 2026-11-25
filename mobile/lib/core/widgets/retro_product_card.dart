import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/product_image_resolver.dart';
import '../utils/vnd_formatter.dart';
import 'condition_badge.dart';
import 'retro_design_primitives.dart';
import 'retro_product_image.dart';
import 'verification_badge.dart';

/// Editorial product card for fixed-price secondhand listings (carousels, search & storefronts).
/// Uses [RetroProductImage] so every product displays authentic vintage photography with fallback.
class RetroProductCard extends StatelessWidget {
  final int id;
  final String title;
  final num price;
  final String? primaryImageUrl;
  final String condition;
  final String? categoryName;
  final String? distanceLabel;
  final bool showConditionPercent;
  final String? verificationStatus;
  final String? sellerName;
  final bool isOwner;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLikeToggle;

  const RetroProductCard({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    this.primaryImageUrl,
    required this.condition,
    this.categoryName,
    this.distanceLabel,
    this.showConditionPercent = false,
    this.verificationStatus,
    this.sellerName,
    this.isOwner = false,
    this.isLiked = false,
    this.onTap,
    this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final compactCategory = ProductImageResolver.shortCategoryLabel(
      categoryName,
      title: title,
    );
    final percentText = ProductImageResolver.conditionPercentLabel(condition);

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: AppColors.borderWarm,
              width: DesignTokens.borderThin,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product Photo Frame with Overlay Badges ───────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: AspectRatio(
                    aspectRatio: showConditionPercent ? 0.88 : 1.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RetroProductImage(
                          imageUrl: primaryImageUrl,
                          title: title,
                          categoryName: categoryName,
                          productId: id,
                          fit: BoxFit.cover,
                        ),
                        // Top-left subtle category pill or verification badge
                        if (categoryName != null || showConditionPercent)
                          Positioned(
                            top: 7,
                            left: 7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pineDeep.withValues(
                                  alpha: 0.86,
                                ),
                                borderRadius: DesignTokens.borderRadiusFull,
                              ),
                              child: Text(
                                compactCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          )
                        else if (!isOwner &&
                            verificationStatus != null &&
                            verificationStatus != 'NONE' &&
                            verificationStatus != 'UNVERIFIED')
                          Positioned(
                            top: 7,
                            left: 7,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                              ),
                              child: VerificationBadge(
                                status: verificationStatus!,
                                isCompact: true,
                                showLabel: false,
                              ),
                            ),
                          ),
                        // Top-right frosted circular heart button
                        if (onLikeToggle != null)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Material(
                              color: isLiked
                                  ? Colors.white.withValues(alpha: 0.94)
                                  : AppColors.darkFrostOverlay,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: isLiked
                                    ? 'Bỏ khỏi yêu thích'
                                    : 'Thêm vào yêu thích',
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 30,
                                  height: 30,
                                ),
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isLiked
                                      ? AppColors.priceCrimson
                                      : Colors.white,
                                ),
                                onPressed: onLikeToggle,
                              ),
                            ),
                          ),
                        // Bottom-left condition badge (percentage pill or full ConditionBadge)
                        Positioned(
                          bottom: isOwner ? 28 : 7,
                          left: 7,
                          child: showConditionPercent
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.creamBadgeBg,
                                    borderRadius: DesignTokens.borderRadiusFull,
                                    border: Border.all(
                                      color: AppColors.creamBadgeBorder,
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 10,
                                        color: AppColors.ctaTerracotta,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Mới $percentText',
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontBody,
                                          color: AppColors.creamBadgeText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ConditionBadge(
                                  condition: condition,
                                  isCompact: true,
                                ),
                        ),
                        if (isOwner)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spaceSm,
                                vertical: DesignTokens.spaceXs,
                              ),
                              color: AppColors.pineDeep.withValues(alpha: 0.92),
                              child: Text(
                                'Sản phẩm của bạn (BR-AC-02)',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Card Copy, Price & Compact Metadata ───────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCharcoal,
                          height: 1.24,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        VndFormatter.format(price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.priceMedium.copyWith(
                          fontSize: 15,
                          color: AppColors.priceCrimson,
                        ),
                      ),
                      const Spacer(),
                      if (distanceLabel != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: AppColors.ctaTerracotta,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              distanceLabel!,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.borderWarm,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                percentText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.verifiedLeaf,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (sellerName != null && sellerName!.isNotEmpty)
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.categoryCircleStart,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.creamBadgeBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                size: 9.5,
                                color: AppColors.pineDeep,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                sellerName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: AppColors.verifiedLeaf,
                            ),
                          ],
                        )
                      else
                        const RetroVerifiedShopChip(fontSize: 10.5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
