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
              // ── Product Photo Frame with Compact Overlay Badges ───────────
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: AspectRatio(
                    aspectRatio: 1.0,
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
                        if (categoryName != null || showConditionPercent)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 108),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
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
                                    fontSize: 9.5,
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
                            top: 6,
                            left: 6,
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
                        // Top-right circular favorite button
                        if (onLikeToggle != null)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Material(
                              color: isLiked
                                  ? Colors.white.withValues(alpha: 0.94)
                                  : AppColors.darkFrostOverlay,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: isLiked
                                    ? 'Bỏ khỏi yêu thích'
                                    : 'Thêm vào yêu thích',
                                iconSize: 15,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
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
                        // Bottom-left freshness pill ("Độ mới: 95%") or ConditionBadge
                        Positioned(
                          bottom: isOwner ? 26 : 6,
                          left: 6,
                          child: showConditionPercent
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.creamBadgeBg.withValues(
                                      alpha: 0.96,
                                    ),
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
                                        size: 9.5,
                                        color: AppColors.ctaTerracotta,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        freshnessText,
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontBody,
                                          color: AppColors.creamBadgeText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9.8,
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
                                vertical: 3,
                              ),
                              color: AppColors.pineDeep.withValues(alpha: 0.92),
                              child: Text(
                                'Sản phẩm của bạn (BR-AC-02)',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 9.5,
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

              // ── Compact Copy, Strong Price Hierarchy & Tight Metadata ─────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textCharcoal,
                              height: 1.22,
                            ),
                          ),
                          const SizedBox(height: 3.5),
                          Text(
                            VndFormatter.format(price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.priceMedium.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.priceCrimson,
                              height: 1.15,
                            ),
                          ),
                          if (distanceLabel != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 11.5,
                                  color: AppColors.ctaTerracotta,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  distanceLabel!,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10.2,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textCharcoal,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  width: 2.5,
                                  height: 2.5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.borderWarm,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    freshnessText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.verifiedLeaf,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      if (sellerName != null && sellerName!.isNotEmpty)
                        Row(
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: AppColors.categoryCircleStart,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.creamBadgeBorder,
                                  width: 0.7,
                                ),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                size: 9,
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
                                  fontSize: 10.2,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.verified_rounded,
                              size: 11.5,
                              color: AppColors.verifiedLeaf,
                            ),
                          ],
                        )
                      else
                        const RetroVerifiedShopChip(fontSize: 10),
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
