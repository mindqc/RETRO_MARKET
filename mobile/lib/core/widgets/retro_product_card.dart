import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/product_image_resolver.dart';
import '../utils/vnd_formatter.dart';
import 'retro_product_image.dart';
import 'verification_badge.dart';

/// Compact, information-rich editorial product card for fixed-price secondhand
/// listings across Home carousels, discovery grids, search, and storefronts.
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
    final freshnessText = ProductImageResolver.conditionFreshnessLabel(condition);
    final hasDistance = distanceLabel != null && distanceLabel!.trim().isNotEmpty;
    final hasSeller = sellerName != null && sellerName!.trim().isNotEmpty;

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
              // ── Compact Product Photo Frame (no corner condition badge) ───
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: AspectRatio(
                    aspectRatio: 1.14,
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
                        // Top-left category tag or verification emblem
                        if (categoryName != null &&
                            categoryName!.trim().isNotEmpty)
                          Positioned(
                            top: 5,
                            left: 5,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 104),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pineDeep.withValues(
                                    alpha: 0.88,
                                  ),
                                  borderRadius: DesignTokens.borderRadiusFull,
                                ),
                                child: Text(
                                  compactCategory,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontBody,
                                    fontSize: 9.2,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (!isOwner &&
                            verificationStatus != null &&
                            verificationStatus != 'NONE' &&
                            verificationStatus != 'UNVERIFIED')
                          Positioned(
                            top: 5,
                            left: 5,
                            child: Container(
                              padding: const EdgeInsets.all(3.5),
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
                        // Top-right circular favorite button
                        if (onLikeToggle != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: isLiked
                                  ? Colors.white.withValues(alpha: 0.94)
                                  : AppColors.darkFrostOverlay,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: isLiked
                                    ? 'Bỏ khỏi yêu thích'
                                    : 'Thêm vào yêu thích',
                                iconSize: 14.5,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 26,
                                  height: 26,
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
                        if (isOwner)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spaceSm,
                                vertical: 2.5,
                              ),
                              color: AppColors.pineDeep.withValues(alpha: 0.92),
                              child: Text(
                                'Sản phẩm của bạn (BR-AC-02)',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 9.2,
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

              // ── Compact Copy, Strong Price Hierarchy & Single Meta Row ────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCharcoal,
                          height: 1.16,
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        VndFormatter.format(price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.priceMedium.copyWith(
                          fontSize: 13.8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.priceCrimson,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 3.5),
                      // Single compact row: Distance + Freshness ("Độ mới: ...") + "Uy tín" badge
                      Row(
                        children: [
                          if (hasDistance) ...[
                            const Icon(
                              Icons.location_on_rounded,
                              size: 10,
                              color: AppColors.ctaTerracotta,
                            ),
                            const SizedBox(width: 1.5),
                            Text(
                              distanceLabel!.trim(),
                              style: AppTypography.caption.copyWith(
                                fontSize: 9.4,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textCharcoal,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 2.2,
                              height: 2.2,
                              decoration: const BoxDecoration(
                                color: AppColors.borderWarm,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                          ],
                          Expanded(
                            child: Text(
                              freshnessText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                fontSize: 9.4,
                                fontWeight: FontWeight.w700,
                                color: AppColors.verifiedLeaf,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.verifiedLeafBg,
                              borderRadius: DesignTokens.borderRadiusFull,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 9.5,
                                  color: AppColors.verifiedLeaf,
                                ),
                                const SizedBox(width: 1.5),
                                Text(
                                  'Uy tín',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 8.6,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.verifiedLeaf,
                                    height: 1.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (hasSeller) ...[
                        const SizedBox(height: 2.5),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              size: 10.5,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                sellerName!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 9.8,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  height: 1.12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
