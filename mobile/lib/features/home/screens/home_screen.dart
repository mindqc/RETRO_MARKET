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
import '../../../core/widgets/seasonal_animations.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';
import '../models/home_feed_model.dart';
import '../viewmodels/home_view_model.dart';

// ---------------------------------------------------------------------------
// Category icon mapping – vintage marketplace editorial style
// ---------------------------------------------------------------------------
const Map<String, IconData> _kCategoryIcons = {
  'Áo': Icons.checkroom,
  'Áo khoác': Icons.dry_cleaning,
  'Quần': Icons.layers_outlined,
  'Váy': Icons.local_florist_outlined,
  'Giày': Icons.shopping_bag_outlined,
  'Túi xách': Icons.work_outline,
  'Phụ kiện': Icons.diamond_outlined,
  'Điện tử': Icons.devices_outlined,
  'Sách': Icons.menu_book_outlined,
  'Nội thất': Icons.chair_outlined,
  'Đồ chơi': Icons.toys_outlined,
  'Thể thao': Icons.sports_outlined,
  'Nhạc cụ': Icons.piano_outlined,
  'Mỹ phẩm': Icons.spa_outlined,
};

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
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: AppColors.warmIvory,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Bottom border to separate from content
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSubtle),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Snowflake festive badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.secondaryPineGreen,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
              ),
              child: const Icon(
                Icons.ac_unit,
                color: AppColors.accentVintageGold,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            // Brand wordmark matching existing test assertions
            const Text(
              'izithrift • Trang chủ',
              style: TextStyle(
                fontFamily: AppTypography.fontHeading,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                color: AppColors.textCharcoal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textCharcoal,
              size: 22,
            ),
            tooltip: 'Tìm kiếm sản phẩm',
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textCharcoal,
              size: 22,
            ),
            tooltip: 'Thông báo',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.textCharcoal,
              size: 22,
            ),
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
              errorMessage:
                  state.errorMessage ?? 'Đã xảy ra sự cố nạp dữ liệu.',
              onRetry: homeVM.loadHomeFeed,
            );
          }
          return _buildContent(
            context,
            ref,
            feed ?? const HomeFeedModel(),
            homeVM,
          );
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
        padding: EdgeInsets.zero,
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceLg,
              DesignTokens.spaceMd,
              DesignTokens.spaceLg,
              DesignTokens.spaceMd,
            ),
            child: InkWell(
              onTap: () => context.push(AppRoutes.search),
              borderRadius: DesignTokens.borderRadiusFull,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: DesignTokens.borderRadiusFull,
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tìm đồ vintage, áo khoác 90s, denim...',
                        style: TextStyle(
                          fontFamily: AppTypography.fontBody,
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.tune_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hero Christmas Banner ───────────────────────────────────────
          _buildHeroBanner(context),
          const SizedBox(height: DesignTokens.spaceXl),

          // ── Category Strip ─────────────────────────────────────────────
          if (feed.categories.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Danh mục tuyển chọn',
              icon: Icons.category_outlined,
              onSeeAll: () => context.go(AppRoutes.discover),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            _buildCategoriesStrip(context, ref, feed.categories),
            const SizedBox(height: DesignTokens.spaceXl),
          ],

          // ── Live Auctions ──────────────────────────────────────────────
          if (feed.liveAuctions.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Đấu giá sôi động',
              icon: Icons.gavel,
              actionLabel: 'Xem tất cả',
              onSeeAll: () => context.go(AppRoutes.auctions),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            _buildLiveAuctionsStrip(context, feed.liveAuctions),
            const SizedBox(height: DesignTokens.spaceXl),
          ],

          // ── Featured Trusted Sellers ───────────────────────────────────
          if (feed.featuredSellers.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Tiệm đồ si uy tín',
              icon: Icons.storefront_outlined,
              actionLabel: 'Xem tất cả',
              onSeeAll: () => context.push('/home/featured'),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            _buildFeaturedSellersStrip(context, feed.featuredSellers),
            const SizedBox(height: DesignTokens.spaceXl),
          ],

          // ── Latest Products ────────────────────────────────────────────
          if (feed.latestProducts.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Hàng mới lên kệ',
              icon: Icons.auto_awesome_outlined,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceLg,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1100
                      ? 4
                      : constraints.maxWidth >= 680
                      ? 3
                      : 2;
                  final cardAspectRatio = crossAxisCount == 4
                      ? 0.68
                      : crossAxisCount == 3
                      ? 0.70
                      : 0.62;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: feed.latestProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: cardAspectRatio,
                      crossAxisSpacing: DesignTokens.spaceMd,
                      mainAxisSpacing: DesignTokens.spaceMd,
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
                        onTap: () => context.push(
                          AppRoutes.productDetailPath(product.id),
                        ),
                        onLikeToggle: () =>
                            homeVM.toggleFavorite(context, product.id),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: DesignTokens.spaceXl),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Christmas Banner – high visual impact editorial layout with snowfall
  // ---------------------------------------------------------------------------
  Widget _buildHeroBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        child: SnowfallOverlay(
          maxFlakes: 10,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A2B), AppColors.secondaryPineGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // Decorative background snowflake icons
                const Positioned(
                  top: -16,
                  right: -16,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(
                      Icons.ac_unit,
                      size: 100,
                      color: AppColors.accentVintageGold,
                    ),
                  ),
                ),
                const Positioned(
                  bottom: -24,
                  left: 24,
                  child: Opacity(
                    opacity: 0.06,
                    child: Icon(
                      Icons.ac_unit,
                      size: 80,
                      color: AppColors.accentVintageGold,
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Eyebrow label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentVintageGold,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusXs,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 10,
                              color: AppColors.textCharcoal,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'BỘ SƯU TẬP MÙA ĐÔNG',
                              style: TextStyle(
                                fontFamily: AppTypography.fontBody,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textCharcoal,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Editorial headline
                      const Text(
                        'Đồ Si & Vintage\nGiáng Sinh ✦',
                        style: TextStyle(
                          fontFamily: AppTypography.fontHeading,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      const Text(
                        'Hơn 500 mẫu áo khoác dạ, len và denim\ncổ điển từ thập niên 70–90.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 13,
                          color: Color(0xFFBDD5C4),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // CTA row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.discover),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTerracotta,
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusSm,
                                ),
                              ),
                              child: const Text(
                                'Khám phá ngay',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.auctions),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withAlpha(100),
                                ),
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusSm,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.gavel,
                                    size: 13,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Sàn đấu giá',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontBody,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section header with terracotta icon + "See all" link
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryForestGreenLight,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppColors.primaryForestGreen,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              Text(title, style: AppTypography.headingSmall),
            ],
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    actionLabel ?? 'Xem thêm',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryForestGreen,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primaryForestGreen,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category horizontal strip with smart icon mapping
  // ---------------------------------------------------------------------------
  Widget _buildCategoriesStrip(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> categories,
  ) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: DesignTokens.spaceMd),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final icon = _kCategoryIcons[cat.name] ?? Icons.inventory_2_outlined;
          return InkWell(
            onTap: () {
              ref.read(catalogSearchViewModelProvider).setCategory(cat.id);
              context.push(AppRoutes.search);
            },
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderWarm,
                        width: DesignTokens.borderThin,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primaryForestGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textCharcoal,
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

  // ---------------------------------------------------------------------------
  // Featured sellers horizontal strip — elevated shop card design
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedSellersStrip(
    BuildContext context,
    List<dynamic> sellers,
  ) {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
        scrollDirection: Axis.horizontal,
        itemCount: sellers.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: DesignTokens.spaceMd),
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return InkWell(
            onTap: () =>
                context.push(AppRoutes.sellerStorefrontPath(seller.id)),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(
                  color: AppColors.borderWarm,
                  width: DesignTokens.borderThin,
                ),
                boxShadow: DesignTokens.cardElevation,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Shop avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderWarm),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.primaryForestGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seller.shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontBody,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.accentVintageGold,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  seller.trustScore.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontBody,
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
                  const SizedBox(height: DesignTokens.spaceSm),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 12,
                        color: AppColors.statusSuccess,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${seller.completedOrdersCount} đơn thành công',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11,
                            color: AppColors.secondaryPineGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
