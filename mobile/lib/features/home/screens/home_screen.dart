import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';
import '../models/home_feed_model.dart';
import '../viewmodels/home_view_model.dart';

/// M-HM-01: Home Discovery Feed Screen (Tab 1 Root)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider).loadHomeFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = ref.watch(homeViewModelProvider);
    final state = homeVM.state;
    final feed = state.data;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'izithrift • Trang chủ',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textCharcoal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textCharcoal),
            tooltip: 'Tìm kiếm sản phẩm',
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textCharcoal),
            tooltip: 'Thông báo',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textCharcoal),
            tooltip: 'Giỏ hàng',
            onPressed: () => context.push(AppRoutes.cart),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isError && feed == null) {
            return RetroErrorRetryView(
              errorMessage: state.errorMessage ?? 'Đã xảy ra sự cố nạp dữ liệu.',
              onRetry: homeVM.loadHomeFeed,
            );
          }
          return _buildContent(context, ref, feed ?? const HomeFeedModel(), homeVM);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic feed,
    HomeViewModel homeVM,
  ) {
    return RefreshIndicator(
      onRefresh: homeVM.refresh,
      color: AppColors.primaryTerracotta,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 1. Search Bar Callout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => context.push(AppRoutes.search),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Tìm đồ vintage, áo khoác 90s, denim...',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Warm Vintage Seasonal Banner
          _buildSeasonalBanner(context),
          const SizedBox(height: 24),

          // 3. Fast Categories Row
          if (feed.categories.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Danh mục tuyển chọn',
              icon: Icons.category_outlined,
              onSeeAll: () => context.go(AppRoutes.discover),
            ),
            const SizedBox(height: 12),
            _buildCategoriesStrip(context, ref, feed.categories),
            const SizedBox(height: 24),
          ],

          // 4. Live Auctions Horizontal Strip
          if (feed.liveAuctions.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Đấu giá sôi động',
              icon: Icons.gavel,
              actionLabel: 'Xem tất cả',
              onSeeAll: () => context.go(AppRoutes.auctions),
            ),
            const SizedBox(height: 12),
            _buildLiveAuctionsStrip(context, feed.liveAuctions),
            const SizedBox(height: 24),
          ],

          // 5. Featured Trusted Sellers
          if (feed.featuredSellers.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Tiệm đồ si uy tín',
              icon: Icons.storefront,
              actionLabel: 'Xem tất cả',
              onSeeAll: () => context.push('/home/featured'),
            ),
            const SizedBox(height: 12),
            _buildFeaturedSellersStrip(context, feed.featuredSellers),
            const SizedBox(height: 24),
          ],

          // 6. Latest Approved Products Grid
          if (feed.latestProducts.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Hàng mới lên kệ',
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: feed.latestProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final product = feed.latestProducts[index];
                  return RetroProductCard(
                    id: product.id,
                    title: product.title,
                    price: product.price,
                    primaryImageUrl: product.primaryImageUrl,
                    condition: product.condition,
                    sellerName: product.sellerDisplayName,
                    isOwner: product.isOwner,
                    isLiked: product.isFavorited,
                    onTap: () => context.push(AppRoutes.productDetailPath(product.id)),
                    onLikeToggle: () => homeVM.toggleFavorite(context, product.id),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeasonalBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondaryPineGreen, Color(0xFF1E3A2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          boxShadow: DesignTokens.cardElevation,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentVintageGold,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                    ),
                    child: const Text(
                      'BỘ SƯU TẬP MÙA ĐÔNG',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textCharcoal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đồ Si & Vintage Giáng Sinh Tuyển Chọn',
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.surfaceCard,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Khám phá hơn 500+ mẫu áo khoác dạ và len cổ điển từ thập niên 90.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 12,
                      color: AppColors.backgroundCream,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.ac_unit,
              color: AppColors.accentVintageGold,
              size: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryTerracotta),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.fontHeading,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textCharcoal,
                ),
              ),
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              child: Row(
                children: [
                  Text(
                    actionLabel ?? 'Xem thêm',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTerracotta,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primaryTerracotta,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesStrip(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> categories,
  ) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () {
              ref.read(catalogSearchViewModelProvider).setCategory(cat.id);
              context.push(AppRoutes.search);
            },
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: const Icon(
                    Icons.checkroom,
                    color: AppColors.primaryTerracotta,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 64,
                  child: Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveAuctionsStrip(BuildContext context, List<dynamic> auctions) {
    return SizedBox(
      height: 290,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: auctions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final auction = auctions[index];
          return SizedBox(
            width: 200,
            child: RetroAuctionCard(
              id: auction.id,
              title: auction.title,
              currentBid: auction.currentBid,
              bidCount: auction.bidCount,
              endsAt: auction.endsAt,
              primaryImageUrl: auction.primaryImageUrl,
              status: auction.status,
              extendedCount: auction.extendedCount,
              isOwner: auction.isOwner,
              onTap: () => context.push(AppRoutes.auctionRoomPath(auction.id)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSellersStrip(BuildContext context, List<dynamic> sellers) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: sellers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return InkWell(
            onTap: () => context.push(AppRoutes.sellerStorefrontPath(seller.id)),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: Container(
              width: 170,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(color: AppColors.borderWarm),
                boxShadow: DesignTokens.cardElevation,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceWarm,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryTerracotta,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seller.shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.accentVintageGold, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  seller.trustScore.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${seller.completedOrdersCount} đơn thành công',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryPineGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
