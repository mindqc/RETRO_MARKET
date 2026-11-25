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
  ConsumerState<SellerReviewsListScreen> createState() =>
      _SellerReviewsListScreenState();
}

class _SellerReviewsListScreenState
    extends ConsumerState<SellerReviewsListScreen> {
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textCharcoal,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đánh Giá Tiệm',
          style: AppTypography.headingMedium.copyWith(fontSize: 20),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (reviewVm.isLoading && summary == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pineDeep),
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
            color: AppColors.ctaTerracotta,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                if (summary != null) _buildSummaryHeader(summary),
                _buildStarFilterRow(reviewVm),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: RetroEmptyStateView(
                      icon: Icons.rate_review_outlined,
                      title: 'Chưa có đánh giá nào',
                      message: reviewVm.activeStarFilter != null
                          ? 'Không có đánh giá ${reviewVm.activeStarFilter} sao nào.'
                          : 'Tiệm chưa nhận được lượt đánh giá nào từ khách mua.',
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildReviewTile(context, reviews[index]),
                    ),
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
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big Score
          Column(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.priceCrimson,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return Icon(
                    starVal <= summary.averageRating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.starGold,
                  );
                }),
              ),
              const SizedBox(height: 5),
              Text(
                '${summary.totalReviews} đánh giá',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Star Distribution Bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = summary.starDistribution[star] ?? 0;
                final percentage =
                    summary.totalReviews > 0 ? count / summary.totalReviews : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCharcoal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.starGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: DesignTokens.borderRadiusFull,
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 7,
                            backgroundColor: AppColors.surfaceWarm,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.starGold,
                            ),
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
                            fontWeight: FontWeight.w600,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((f) {
          final val = f['value'] as int?;
          final isSelected = reviewVm.activeStarFilter == val;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.creamBadgeBg
                      : AppColors.textCharcoal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.pineDeep,
              backgroundColor: AppColors.surfaceCard,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? AppColors.pineDeep : AppColors.borderWarm,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.categoryCircleStart,
                backgroundImage: (item.userAvatarUrl != null &&
                        item.userAvatarUrl!.isNotEmpty)
                    ? NetworkImage(item.userAvatarUrl!)
                    : null,
                child: (item.userAvatarUrl == null ||
                        item.userAvatarUrl!.isEmpty)
                    ? Text(
                        item.userName.isNotEmpty
                            ? item.userName.substring(0, 1).toUpperCase()
                            : 'K',
                        style: AppTypography.labelStrong.copyWith(
                          color: AppColors.pineDeep,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelStrong.copyWith(
                              fontSize: 13.5,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
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
                                size: 11,
                                color: AppColors.verifiedLeaf,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Đã mua hàng',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.verifiedLeaf,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            final filled = index < item.rating;
                            return Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: AppColors.starGold,
                            );
                          }),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
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
          const SizedBox(height: 10),
          Text(
            item.comment,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textCharcoal,
              height: 1.45,
            ),
          ),
          if (item.productTitle != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: DesignTokens.borderRadiusSm,
              ),
              child: Text(
                'Món đồ: ${item.productTitle}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
