import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';
import 'condition_badge.dart';
import 'verification_badge.dart';
import 'state_feedback_views.dart';

/// RetroProductCard displays a fixed-price secondhand product card
/// Enforces BR-AC-02 awareness (highlights if the item belongs to the viewing seller).
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.borderWarm, width: DesignTokens.borderThin),
          boxShadow: DesignTokens.cardElevation,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with badges and like button
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(),
                  // Top left condition badge
                  Positioned(
                    top: DesignTokens.spaceSm,
                    left: DesignTokens.spaceSm,
                    child: ConditionBadge(condition: condition, isCompact: true),
                  ),
                  // Top right like button
                  if (onLikeToggle != null)
                    Positioned(
                      top: DesignTokens.spaceXs,
                      right: DesignTokens.spaceXs,
                      child: IconButton(
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? AppColors.christmasBerryRed : AppColors.textMuted,
                        ),
                        onPressed: onLikeToggle,
                      ),
                    ),
                  // Bottom left verification badge or owner banner
                  if (isOwner)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.surfaceDark.withValues(alpha: 0.8),
                        child: Text(
                          'Sản phẩm của bạn (BR-AC-02)',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                  else if (verificationStatus != null && verificationStatus != 'NONE')
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

            // Product Details
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    VndFormatter.format(price),
                    style: AppTypography.priceMedium,
                  ),
                  if (sellerName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sellerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (primaryImageUrl == null || primaryImageUrl!.isEmpty) {
      return Container(
        color: AppColors.surfaceWarm,
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 36),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: primaryImageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => const RetroShimmerBox(width: double.infinity, height: double.infinity),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surfaceWarm,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 36),
        ),
      ),
    );
  }
}
