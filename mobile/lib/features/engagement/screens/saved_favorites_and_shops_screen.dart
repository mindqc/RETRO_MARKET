import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../home/models/featured_seller_model.dart';
import '../viewmodels/engagement_and_review_view_model.dart';

/// M-PF-05: Saved Favorites & Followed Shops Screen (/profile/favorites)
class SavedFavoritesAndShopsScreen extends ConsumerStatefulWidget {
  const SavedFavoritesAndShopsScreen({super.key});

  @override
  ConsumerState<SavedFavoritesAndShopsScreen> createState() =>
      _SavedFavoritesAndShopsScreenState();
}

class _SavedFavoritesAndShopsScreenState
    extends ConsumerState<SavedFavoritesAndShopsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(engagementViewModelProvider).loadEngagementData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engVm = ref.watch(engagementViewModelProvider);

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
          'Đồ Lưu & Tiệm Quen',
          style: AppTypography.headingMedium.copyWith(fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.priceCrimson,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.priceCrimson,
              indicatorWeight: 2.5,
              labelStyle: AppTypography.labelStrong.copyWith(fontSize: 13.5),
              unselectedLabelStyle: AppTypography.bodySmall.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: 'Đồ Yêu Thích (${engVm.favoriteProducts.length})'),
                Tab(text: 'Tiệm Theo Dõi (${engVm.followedShops.length})'),
              ],
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (engVm.isLoading &&
              engVm.favoriteProducts.isEmpty &&
              engVm.followedShops.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pineDeep),
            );
          }

          if (engVm.isError && engVm.favoriteProducts.isEmpty) {
            return RetroErrorRetryView(
              errorMessage: engVm.errorMessage ?? 'Không thể tải danh sách lưu',
              onRetry: () => engVm.loadEngagementData(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesTab(context, engVm),
              _buildFollowedShopsTab(context, engVm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context, EngagementViewModel engVm) {
    final products = engVm.favoriteProducts;

    if (products.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => engVm.loadEngagementData(),
        color: AppColors.ctaTerracotta,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            const RetroEmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'Chưa có món đồ nào',
              message:
                  'Khám phá bảng tin và bấm vào biểu tượng trái tim để lưu lại những món đồ vintage ưng ý!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => engVm.loadEngagementData(),
      color: AppColors.ctaTerracotta,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];
          return RetroProductCard(
            id: item.id,
            title: item.title,
            price: item.price,
            primaryImageUrl: item.primaryImageUrl,
            condition: item.condition,
            sellerName: item.sellerName,
            isLiked: true,
            onTap: () => context.push('/products/${item.id}'),
            onLikeToggle: () => engVm.toggleFavoriteProduct(item.id),
          );
        },
      ),
    );
  }

  Widget _buildFollowedShopsTab(
    BuildContext context,
    EngagementViewModel engVm,
  ) {
    final shops = engVm.followedShops;

    if (shops.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => engVm.loadEngagementData(),
        color: AppColors.ctaTerracotta,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            const RetroEmptyStateView(
              icon: Icons.storefront_outlined,
              title: 'Chưa theo dõi tiệm nào',
              message:
                  'Theo dõi những tiệm đồ vintage bạn yêu thích để nhận thông báo khi có đợt khui kiện mới!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => engVm.loadEngagementData(),
      color: AppColors.ctaTerracotta,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: shops.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildShopCard(context, shops[index], engVm),
      ),
    );
  }

  Widget _buildShopCard(
    BuildContext context,
    FeaturedSellerModel shop,
    EngagementViewModel engVm,
  ) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: DesignTokens.borderRadiusLg,
      child: InkWell(
        borderRadius: DesignTokens.borderRadiusLg,
        onTap: () => context.push('/sellers/${shop.userId}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.creamBadgeBorder, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.categoryCircleStart,
                  backgroundImage:
                      (shop.avatarUrl != null && shop.avatarUrl!.isNotEmpty)
                          ? NetworkImage(shop.avatarUrl!)
                          : null,
                  child: (shop.avatarUrl == null || shop.avatarUrl!.isEmpty)
                      ? Text(
                          shop.shopName.isNotEmpty
                              ? shop.shopName.substring(0, 1).toUpperCase()
                              : 'S',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.pineDeep,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelStrong.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.starGold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${shop.rating.toStringAsFixed(1)} / 5.0',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '•  ${shop.activeListingsCount} đồ đang bán',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const RetroVerifiedShopChip(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => engVm.toggleFollowSeller(shop),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.borderWarm),
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Bỏ theo dõi',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
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
