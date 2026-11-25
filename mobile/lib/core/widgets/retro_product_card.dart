import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';
import 'condition_badge.dart';
import 'retro_design_primitives.dart';
import 'verification_badge.dart';
import 'state_feedback_views.dart';

/// Editorial product card for fixed-price secondhand listings.
/// Styled after the approved Home Page reference:
/// - Crisp white 16px rounded card with soft warm shadow & hairline border
/// - Frosted circular heart button on top-right of product photo
/// - Bottom-left overlapping warm-cream condition pill
/// - Bold title, compact seller row, crimson tabular price, and verified indicator
class RetroProductCard extends StatelessWidget {
  final int id;
  final String title;
  final num price;
  final String? primaryImageUrl;
  final String condition;
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
    this.verificationStatus,
    this.sellerName,
    this.isOwner = false,
    this.isLiked = false,
    this.onTap,
    this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
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
                    aspectRatio: 1.02,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildProductImage(),
                        // Top-right frosted dark circular heart button
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
                                iconSize: 17,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 32,
                                  height: 32,
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
                        // Bottom-left warm cream condition pill (reference layout)
                        Positioned(
                          bottom: isOwner ? 28 : 7,
                          left: 7,
                          child: ConditionBadge(
                            condition: condition,
                            isCompact: true,
                          ),
                        ),
                        // Top-left verification mini badge if verified
                        if (!isOwner &&
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

              // ── Card Copy & Crimson Price ────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCharcoal,
                          height: 1.28,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (sellerName != null && sellerName!.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
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
                                size: 10,
                                color: AppColors.pineDeep,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                sellerName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      Text(
                        VndFormatter.format(price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.priceMedium.copyWith(
                          fontSize: 15,
                          color: AppColors.priceCrimson,
                        ),
                      ),
                      const SizedBox(height: 3),
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

  Widget _buildProductImage() {
    if (primaryImageUrl == null || primaryImageUrl!.isEmpty) {
      return Container(
        color: AppColors.surfaceWarm,
        child: const Center(
          child: Icon(
            Icons.checkroom_outlined,
            color: AppColors.textMuted,
            size: 34,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: primaryImageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => const RetroShimmerBox(
        width: double.infinity,
        height: double.infinity,
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surfaceWarm,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMuted,
            size: 32,
          ),
        ),
      ),
    );
  }
}
