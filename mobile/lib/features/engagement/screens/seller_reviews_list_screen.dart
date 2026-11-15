import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../catalog/models/review_item_model.dart';
import '../models/seller_reviews_summary_model.dart';
import '../viewmodels/engagement_and_review_view_model.dart';

/// M-RV-02: Seller Verified Reviews List Screen (/sellers/:sellerId/reviews)
class SellerReviewsListScreen extends ConsumerStatefulWidget {
  final int sellerId;
  final String? shopName;

  const SellerReviewsListScreen({
    super.key,
    required this.sellerId,
    this.shopName,
  });

  @override
  ConsumerState<SellerReviewsListScreen> createState() => _SellerReviewsListScreenState();
}

class _SellerReviewsListScreenState extends ConsumerState<SellerReviewsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewViewModelProvider).loadSellerReviews(widget.sellerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewVm = ref.watch(reviewViewModelProvider);
    final summary = reviewVm.reviewsSummary;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textCharcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đánh Giá Tiệm',
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textCharcoal,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.borderWarm,
            height: 1.0,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (reviewVm.isLoading && summary == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTerracotta),
            );
          }

          if (reviewVm.isError && summary == null) {
            return RetroErrorRetryView(
              errorMessage: reviewVm.errorMessage ?? 'Không thể tải đánh giá',
              onRetry: () => reviewVm.loadSellerReviews(widget.sellerId),
            );
          }

          final reviews = reviewVm.filteredReviews;

          return RefreshIndicator(
            onRefresh: () => reviewVm.loadSellerReviews(widget.sellerId),
            color: AppColors.primaryTerracotta,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Top Aggregate Score & Breakdown Box
                if (summary != null) _buildSummaryHeader(summary),

                // Star Filter Row
                _buildStarFilterRow(reviewVm),

                // Review items
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.space2xl),
                    child: RetroEmptyStateView(
                      icon: Icons.rate_review_outlined,
                      title: 'Chưa có đánh giá nào',
                      message: reviewVm.activeStarFilter != null
                          ? 'Không có đánh giá ${reviewVm.activeStarFilter} sao nào.'
                          : 'Tiệm chưa nhận được lượt đánh giá nào từ khách mua.',
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.borderWarm,
                      indent: DesignTokens.spaceLg,
                    ),
                    itemBuilder: (context, index) {
                      final item = reviews[index];
                      return _buildReviewTile(context, item);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(SellerReviewsSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      margin: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Big Score
          Column(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTerracotta,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return Icon(
                    starVal <= summary.averageRating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.accentVintageGold,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.totalReviews} đánh giá',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(width: DesignTokens.spaceLg),

          // Right: Star Distribution Bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = summary.starDistribution[star] ?? 0;
                final percentage = summary.totalReviews > 0 ? count / summary.totalReviews : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textCharcoal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 12, color: AppColors.accentVintageGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceWarm,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentVintageGold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarFilterRow(ReviewViewModel reviewVm) {
    final filters = [
      {'label': 'Tất cả', 'value': null},
      {'label': '5 ⭐', 'value': 5},
      {'label': '4 ⭐', 'value': 4},
      {'label': '3 ⭐', 'value': 3},
      {'label': '2 ⭐', 'value': 2},
      {'label': '1 ⭐', 'value': 1},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((f) {
          final val = f['value'] as int?;
          final isSelected = reviewVm.activeStarFilter == val;
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.spaceSm),
            child: ChoiceChip(
              label: Text(
                f['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textCharcoal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryTerracotta,
              backgroundColor: AppColors.surfaceWarm,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryTerracotta : AppColors.borderWarm,
                ),
              ),
              onSelected: (_) => reviewVm.setStarFilter(val),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewTile(BuildContext context, ReviewItemModel item) {
    final dateStr = item.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(item.createdAt!)
        : '';

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      color: AppColors.backgroundCream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceWarm,
                backgroundImage: (item.userAvatarUrl != null && item.userAvatarUrl!.isNotEmpty)
                    ? NetworkImage(item.userAvatarUrl!)
                    : null,
                child: (item.userAvatarUrl == null || item.userAvatarUrl!.isEmpty)
                    ? Text(
                        item.userName.isNotEmpty ? item.userName.substring(0, 1).toUpperCase() : 'K',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTerracotta,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.userName,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceSm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 10, color: AppColors.secondaryPineGreen),
                              const SizedBox(width: 2),
                              Text(
                                'Đã mua hàng',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.secondaryPineGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            final filled = index < item.rating;
                            return Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 13,
                              color: AppColors.accentVintageGold,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Text(
            item.comment,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textCharcoal,
              height: 1.4,
            ),
          ),
          if (item.productTitle != null) ...[
            const SizedBox(height: DesignTokens.spaceSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Text(
                'Món đồ: ${item.productTitle}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
