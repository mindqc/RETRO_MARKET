import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/seasonal_animations.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';
import '../models/auction_summary_model.dart';
import '../models/featured_seller_model.dart';
import '../models/home_feed_model.dart';
import '../viewmodels/home_view_model.dart';

// ---------------------------------------------------------------------------
// Category icon mapping – warm vintage marketplace iconography
// ---------------------------------------------------------------------------
const Map<String, IconData> _kCategoryIcons = {
  'Áo': Icons.checkroom_rounded,
  'Áo khoác': Icons.dry_cleaning_rounded,
  'Quần': Icons.layers_outlined,
  'Váy': Icons.local_florist_outlined,
  'Giày': Icons.hiking_rounded,
  'Túi xách': Icons.shopping_bag_outlined,
  'Phụ kiện': Icons.watch_outlined,
  'Điện tử': Icons.camera_alt_outlined,
  'Sách': Icons.menu_book_outlined,
  'Nội thất': Icons.chair_outlined,
  'Đồ chơi': Icons.album_outlined,
  'Thể thao': Icons.sports_outlined,
  'Nhạc cụ': Icons.piano_outlined,
  'Mỹ phẩm': Icons.card_giftcard_outlined,
};

/// M-HM-01: Home Discovery Feed Screen (Tab 1 Root)
/// Master implementation of the approved Cozy Vintage Editorial design language.
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: DesignTokens.spaceLg,
        title: const RetroBrandWordmark(titleText: 'izithrift • Trang chủ'),
        actions: [
          RetroHeaderIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Thông báo',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          RetroHeaderIconButton(
            icon: Icons.shopping_bag_outlined,
            tooltip: 'Giỏ hàng',
            onPressed: () => context.push(AppRoutes.cart),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
        ],
      ),
      body: RetroAmbientSnowflakes(
        child: Builder(
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
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HomeFeedModel feed,
    HomeViewModel homeVM,
  ) {
    return RefreshIndicator(
      onRefresh: homeVM.refresh,
      color: AppColors.ctaTerracotta,
      backgroundColor: AppColors.surfaceCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: DesignTokens.space2xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Floating Pill Search Bar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceLg,
                DesignTokens.spaceXs,
                DesignTokens.spaceLg,
                DesignTokens.spaceMd,
              ),
              child: RetroSearchPill(
                placeholder: 'Tìm đồ vintage, áo khoác 90s, denim...',
                onTap: () => context.push(AppRoutes.search),
                onFilterTap: () => context.push(AppRoutes.search),
              ),
            ),

            // ── Cozy Editorial Winter Hero Banner ───────────────────────────
            _buildHeroBanner(context),
            const SizedBox(height: DesignTokens.spaceLg),

            // ── Circular Radial-Cream Quick Categories ──────────────────────
            if (feed.categories.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceLg,
                ),
                child: RetroSectionHeader(
                  title: 'Danh mục tuyển chọn',
                  icon: Icons.grid_view_rounded,
                  iconColor: AppColors.ctaTerracotta,
                  actionLabel: 'Xem tất cả',
                  onAction: () => context.go(AppRoutes.discover),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              _buildCategoriesStrip(context, ref, feed.categories),
              const SizedBox(height: DesignTokens.spaceXl),
            ],

            // ── Latest Vintage Products (Soft-Cream Section Container) ──────
            if (feed.latestProducts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceMd,
                ),
                child: RetroSectionContainer(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RetroSectionHeader(
                        title: 'Hàng mới lên kệ',
                        subtitle: 'Những món đồ vintage tuyển chọn mới nhất',
                        icon: Icons.bolt_rounded,
                        iconColor: AppColors.starGold,
                        actionLabel: 'Xem tất cả',
                        onAction: () => context.push(AppRoutes.search),
                      ),
                      const SizedBox(height: DesignTokens.spaceMd),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 1100
                              ? 4
                              : constraints.maxWidth >= 680
                              ? 3
                              : 2;
                          final cardAspectRatio = crossAxisCount == 4
                              ? 0.66
                              : crossAxisCount == 3
                              ? 0.68
                              : 0.60;

                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: feed.latestProducts.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: cardAspectRatio,
                                  crossAxisSpacing: DesignTokens.spaceSm + 2,
                                  mainAxisSpacing: DesignTokens.spaceSm + 2,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceXl),
            ],

            // ── Deep Pine Auction Spotlight Module ──────────────────────────
            if (feed.liveAuctions.isNotEmpty) ...[
              _buildAuctionSpotlightModule(context, feed.liveAuctions),
              const SizedBox(height: DesignTokens.spaceXl),
            ],

            // ── Trusted Vintage Shops ───────────────────────────────────────
            if (feed.featuredSellers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceLg,
                ),
                child: RetroSectionHeader(
                  title: 'Tiệm đồ si uy tín',
                  subtitle: 'Những shop được cộng đồng tin tưởng',
                  icon: Icons.star_rounded,
                  iconColor: AppColors.starGold,
                  actionLabel: 'Xem tất cả',
                  onAction: () => context.push('/home/featured'),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              _buildFeaturedSellersStrip(context, feed.featuredSellers),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cozy Editorial Winter Hero Banner
  // ---------------------------------------------------------------------------
  Widget _buildHeroBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: DesignTokens.borderRadiusBanner,
          boxShadow: DesignTokens.bannerElevation,
        ),
        child: ClipRRect(
          borderRadius: DesignTokens.borderRadiusBanner,
          child: SnowfallOverlay(
            maxFlakes: 10,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2B2118),
                    Color(0xFF3E2A1D),
                    AppColors.pineDeep,
                  ],
                  stops: [0.0, 0.56, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  // Warm golden hearth glow behind right graphic
                  Positioned(
                    right: -24,
                    bottom: -26,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.starGold.withValues(alpha: 0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Decorative festive snowflake outlines
                  Positioned(
                    top: 10,
                    right: 88,
                    child: Icon(
                      Icons.ac_unit_rounded,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  // Right-side framed cozy vintage clothing rack emblem
                  Positioned(
                    right: 16,
                    top: 26,
                    bottom: 30,
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: AppColors.creamBadgeBg.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.creamBadgeBg.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.checkroom_rounded,
                            size: 40,
                            color: AppColors.creamBadgeBg.withValues(
                              alpha: 0.92,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pineDeep.withValues(alpha: 0.7),
                              borderRadius: DesignTokens.borderRadiusFull,
                            ),
                            child: const Text(
                              'Retro Market',
                              style: TextStyle(
                                fontFamily: AppTypography.fontHeading,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.creamBadgeBg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Editorial left column content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 122, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Warm Cream-Gold Eyebrow Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.creamBadgeBg,
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.park_rounded,
                                size: 12,
                                color: AppColors.pineBanner,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'BỘ SƯU TẬP MÙA ĐÔNG',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.creamBadgeText,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 11),
                        const Text(
                          'Săn Đồ Vintage\nĐón Mùa Đông',
                          style: TextStyle(
                            fontFamily: AppTypography.fontHeading,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Những món đồ secondhand độc đáo từ thập niên 70–90 đang chờ bạn khám phá!',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.84),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Material(
                              color: AppColors.ctaTerracotta,
                              borderRadius: DesignTokens.borderRadiusFull,
                              child: InkWell(
                                onTap: () => context.go(AppRoutes.discover),
                                borderRadius: DesignTokens.borderRadiusFull,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Khám phá ngay',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontBody,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: DesignTokens.borderRadiusFull,
                              child: InkWell(
                                onTap: () => context.go(AppRoutes.auctions),
                                borderRadius: DesignTokens.borderRadiusFull,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: DesignTokens.borderRadiusFull,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.28,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.gavel_rounded,
                                        size: 13,
                                        color: AppColors.creamBadgeBg,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Sàn đấu giá',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontBody,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.creamBadgeBg,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Subtle carousel pagination dots (reference detail)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.creamBadgeBg,
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                        ),
                        const SizedBox(width: 5),
                        ...List.generate(
                          3,
                          (_) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.42),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Circular Radial-Cream Category Strip
  // ---------------------------------------------------------------------------
  Widget _buildCategoriesStrip(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> categories,
  ) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
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
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          AppColors.categoryCircleStart,
                          AppColors.categoryCircleEnd,
                        ],
                        center: Alignment(-0.2, -0.2),
                        radius: 0.85,
                      ),
                      border: Border.all(
                        color: AppColors.creamBadgeBorder,
                        width: 1.2,
                      ),
                      boxShadow: DesignTokens.cardElevation,
                    ),
                    child: Icon(icon, color: AppColors.pineDeep, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textCharcoal,
                      height: 1.2,
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

  // ---------------------------------------------------------------------------
  // Deep Pine Green Auction Spotlight Module (Reference Layout)
  // ---------------------------------------------------------------------------
  Widget _buildAuctionSpotlightModule(
    BuildContext context,
    List<AuctionSummaryModel> auctions,
  ) {
    final featured = auctions.first;
    final additional = auctions.length > 1 ? auctions.sublist(1) : const [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      child: RetroPineSpotlightContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Gavel + Title + Segmented Countdown + "Xem tất cả >"
            Row(
              children: [
                const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.starGold,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Đấu giá sôi động',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingMedium.copyWith(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                ),
                RetroSegmentedCountdown(endsAt: featured.endsAt),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => context.go(AppRoutes.auctions),
                  borderRadius: DesignTokens.borderRadiusFull,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.creamBadgeBg,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: AppColors.creamBadgeBg,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Elevated White Horizontal Spotlight Card (Reference Feature)
            _buildSpotlightAuctionCard(context, featured),

            // Additional Live Auctions Horizontal Strip
            if (additional.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 274,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: additional.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final auction = additional[index];
                    return SizedBox(
                      width: 196,
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
                        onTap: () =>
                            context.push(AppRoutes.auctionRoomPath(auction.id)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightAuctionCard(
    BuildContext context,
    AuctionSummaryModel auction,
  ) {
    final isScheduled = auction.status.toUpperCase() == 'SCHEDULED';
    final badgeText = isScheduled ? 'Sắp bắt đầu' : 'Đang diễn ra';

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.auctionRoomPath(auction.id)),
        child: SizedBox(
          height: 128,
          child: Row(
            children: [
              // Left image + crimson corner pill
              SizedBox(
                width: 132,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (auction.primaryImageUrl != null &&
                        auction.primaryImageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: auction.primaryImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const RetroShimmerBox(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceWarm,
                          child: const Icon(
                            Icons.gavel_rounded,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.surfaceWarm,
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: AppColors.textMuted,
                          size: 32,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.priceCrimson,
                          borderRadius: DesignTokens.borderRadiusFull,
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontBody,
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right details column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auction.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textCharcoal,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.gavel_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isScheduled ? 'Giá khởi điểm' : 'Giá hiện tại',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        VndFormatter.format(auction.currentBid),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.priceMedium.copyWith(
                          fontSize: 16,
                          color: AppColors.priceCrimson,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${auction.bidCount} lượt đặt giá',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.creamBadgeSoft,
                              borderRadius: DesignTokens.borderRadiusFull,
                              border: Border.all(
                                color: AppColors.creamBadgeBorder,
                              ),
                            ),
                            child: Text(
                              isScheduled ? 'Nhắc tôi' : 'Đặt giá',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontBody,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.creamBadgeText,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  // ---------------------------------------------------------------------------
  // Trusted Vintage Shops Horizontal Strip (Reference Style)
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedSellersStrip(
    BuildContext context,
    List<FeaturedSellerModel> sellers,
  ) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
        scrollDirection: Axis.horizontal,
        itemCount: sellers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final seller = sellers[index];
          final isDarkCrest = index.isOdd;

          return Material(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: InkWell(
              onTap: () =>
                  context.push(AppRoutes.sellerStorefrontPath(seller.id)),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              child: Ink(
                width: 222,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Row(
                  children: [
                    // Vintage Circular Emblem Crest
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkCrest
                            ? const Color(0xFF3E2B1E)
                            : AppColors.categoryCircleEnd,
                        border: Border.all(
                          color: isDarkCrest
                              ? AppColors.starGold
                              : AppColors.creamBadgeBorder,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child:
                          seller.avatarUrl != null &&
                              seller.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: seller.avatarUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Icon(
                                  Icons.storefront_rounded,
                                  color: isDarkCrest
                                      ? AppColors.creamBadgeBg
                                      : AppColors.pineDeep,
                                  size: 26,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.storefront_rounded,
                              color: isDarkCrest
                                  ? AppColors.creamBadgeBg
                                  : AppColors.pineDeep,
                              size: 26,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            seller.shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.starGold,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '${seller.ratingAvg.toStringAsFixed(1)} (${seller.completedOrdersCount} đơn)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const RetroVerifiedShopChip(fontSize: 11),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
