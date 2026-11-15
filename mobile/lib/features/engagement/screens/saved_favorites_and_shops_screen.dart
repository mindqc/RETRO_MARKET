import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../home/models/featured_seller_model.dart';
import '../viewmodels/engagement_and_review_view_model.dart';

/// M-PF-05: Saved Favorites & Followed Shops Screen (/profile/favorites)
class SavedFavoritesAndShopsScreen extends ConsumerStatefulWidget {
  const SavedFavoritesAndShopsScreen({super.key});

  @override
  ConsumerState<SavedFavoritesAndShopsScreen> createState() => _SavedFavoritesAndShopsScreenState();
}

class _SavedFavoritesAndShopsScreenState extends ConsumerState<SavedFavoritesAndShopsScreen>
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textCharcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đồ Lưu & Tiệm Quen',
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textCharcoal,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryTerracotta,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryTerracotta,
          indicatorWeight: 3,
          labelStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Đồ Yêu Thích (${engVm.favoriteProducts.length})'),
            Tab(text: 'Tiệm Theo Dõi (${engVm.followedShops.length})'),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
          if (engVm.isLoading && engVm.favoriteProducts.isEmpty && engVm.followedShops.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTerracotta),
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
              // Tab 1: Favorite Products
              _buildFavoritesTab(context, engVm),

              // Tab 2: Followed Shops
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
        color: AppColors.primaryTerracotta,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const RetroEmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'Chưa có món đồ nào',
              message: 'Khám phá bảng tin và bấm vào biểu tượng trái tim để lưu lại những món đồ vintage ưng ý!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => engVm.loadEngagementData(),
      color: AppColors.primaryTerracotta,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: DesignTokens.spaceMd,
          mainAxisSpacing: DesignTokens.spaceMd,
          childAspectRatio: 0.65,
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

  Widget _buildFollowedShopsTab(BuildContext context, EngagementViewModel engVm) {
    final shops = engVm.followedShops;

    if (shops.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => engVm.loadEngagementData(),
        color: AppColors.primaryTerracotta,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const RetroEmptyStateView(
              icon: Icons.storefront_outlined,
              title: 'Chưa theo dõi tiệm nào',
              message: 'Theo dõi những tiệm đồ vintage bạn yêu thích để nhận thông báo khi có đợt khui kiện mới!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => engVm.loadEngagementData(),
      color: AppColors.primaryTerracotta,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        itemCount: shops.length,
        separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.spaceSm),
        itemBuilder: (context, index) {
          final shop = shops[index];
          return _buildShopCard(context, shop, engVm);
        },
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, FeaturedSellerModel shop, EngagementViewModel engVm) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceWarm,
            backgroundImage: (shop.avatarUrl != null && shop.avatarUrl!.isNotEmpty)
                ? NetworkImage(shop.avatarUrl!)
                : null,
            child: (shop.avatarUrl == null || shop.avatarUrl!.isEmpty)
                ? Text(
                    shop.shopName.isNotEmpty ? shop.shopName.substring(0, 1).toUpperCase() : 'S',
                    style: AppTypography.headingSmall.copyWith(color: AppColors.primaryTerracotta),
                  )
                : null,
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.accentVintageGold),
                    const SizedBox(width: 4),
                    Text(
                      '${shop.rating.toStringAsFixed(1)} / 5.0',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${shop.activeListingsCount} đồ đang bán',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          OutlinedButton(
            onPressed: () => engVm.toggleFollowSeller(shop),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderWarm),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Bỏ theo dõi',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
