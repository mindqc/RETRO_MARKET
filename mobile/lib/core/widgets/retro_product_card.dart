import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';
import 'condition_badge.dart';
import 'verification_badge.dart';
import 'state_feedback_views.dart';

/// Editorial product card for fixed-price secondhand listings.
///
/// Keeps the existing listing, ownership, verification and favorite behavior.
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
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildProductImage(),
                    Positioned(
                      top: DesignTokens.spaceSm,
                      left: DesignTokens.spaceSm,
                      child: ConditionBadge(
                        condition: condition,
                        isCompact: true,
                      ),
                    ),
                    if (onLikeToggle != null)
                      Positioned(
                        top: DesignTokens.spaceXs,
                        right: DesignTokens.spaceXs,
                        child: Material(
                          color: AppColors.surfaceCard.withValues(alpha: 0.94),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: isLiked
                                ? 'Bỏ khỏi yêu thích'
                                : 'Thêm vào yêu thích',
                            iconSize: 19,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 38,
                              height: 38,
                            ),
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked
                                  ? AppColors.christmasBerryRed
                                  : AppColors.textMuted,
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
                            vertical: DesignTokens.spaceXs,
                          ),
                          color: AppColors.primaryForestGreen.withValues(
                            alpha: 0.92,
                          ),
                          child: Text(
                            'Sản phẩm của bạn (BR-AC-02)',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else if (verificationStatus != null &&
                        verificationStatus != 'NONE')
                      Positioned(
                        bottom: DesignTokens.spaceSm,
                        left: DesignTokens.spaceSm,
                        child: VerificationBadge(
                          status: verificationStatus!,
                          isCompact: true,
                          showLabel: false,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spaceMd,
                  DesignTokens.spaceSm,
                  DesignTokens.spaceMd,
                  DesignTokens.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Text(
                      VndFormatter.format(price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.priceMedium,
                    ),
                    if (sellerName != null) ...[
                      const SizedBox(height: DesignTokens.spaceXs),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: DesignTokens.spaceXs),
                          Expanded(
                            child: Text(
                              sellerName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
            Icons.inventory_2_outlined,
            color: AppColors.textMuted,
            size: 36,
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
            size: 36,
          ),
        ),
      ),
    );
  }
}
