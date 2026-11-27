import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/review_item_model.dart';

/// Editorial shop reviews block displayed on [ProductDetailScreen].
/// Shows average rating, total review count, verified buyer comments,
/// or a tidy empty state when the shop has no reviews yet.
class ProductShopReviewsSection extends StatelessWidget {
  final double averageRating;
  final int reviewCount;
  final List<ReviewItemModel> reviews;
  final bool isLoading;
  final VoidCallback? onSeeAllTap;

  const ProductShopReviewsSection({
    super.key,
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
    this.isLoading = false,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayRating = averageRating > 0 ? averageRating : 5.0;
    final displayCount = reviewCount > 0 ? reviewCount : reviews.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + rating summary + "Xem tất cả"
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 19,
                color: AppColors.starGold,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Đánh giá shop',
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pineDeep,
                  ),
                ),
              ),
              if (onSeeAllTap != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ctaTerracotta,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onSeeAllTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem shop',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating summary strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.creamBadgeSoft,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: AppColors.creamBadgeBorder),
            ),
            child: Row(
              children: [
                Text(
                  displayRating.toStringAsFixed(1),
                  style: AppTypography.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pineDeep,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ 5.0',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                _buildStarsRow(displayRating.round(), size: 15),
                const Spacer(),
                Text(
                  '$displayCount đánh giá',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.textCharcoal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (isLoading && reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.ctaTerracotta,
                  ),
                ),
              ),
            )
          else if (reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSection,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 26,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chưa có đánh giá nào cho shop này',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Nhận xét từ người mua trước sẽ hiển thị tại đây.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < reviews.take(4).length; i++) ...[
                  _buildReviewItem(reviews[i]),
                  if (i < reviews.take(4).length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: AppColors.borderSubtle),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ReviewItemModel review) {
    final initials = _reviewerInitials(review.reviewerName);
    final dateText = _formatDate(review.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.pineDeep.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderWarm),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: AppTypography.fontHeading,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pineDeep,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          review.reviewerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                      ),
                      if (review.isVerifiedPurchase) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.verifiedLeafBg,
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: const Text(
                            'Đã mua',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.verifiedLeaf,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _buildStarsRow(review.rating, size: 12.5),
                      if (dateText != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• $dateText',
                          style: AppTypography.caption.copyWith(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (review.comment.trim().isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            review.comment.trim(),
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.textCharcoal,
              height: 1.48,
            ),
          ),
        ],
        if (review.productTitle != null &&
            review.productTitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            'Sản phẩm: ${review.productTitle!.trim()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStarsRow(int filledCount, {double size = 14}) {
    final clamped = filledCount.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (idx) => Icon(
          idx < clamped ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppColors.starGold,
        ),
      ),
    );
  }

  String _reviewerInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'K';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }
}
