import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/product_image_resolver.dart';
import '../../../core/widgets/izithrift_global_app_bar.dart';
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/seasonal_animations.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../catalog/models/product_filter_query.dart';
import '../../catalog/models/product_summary_model.dart';
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
  'Đồ cổ': Icons.photo_camera_outlined,
  'Sách': Icons.menu_book_outlined,
  'Nội thất': Icons.chair_outlined,
  'Đồ chơi': Icons.album_outlined,
  'Thể thao': Icons.sports_outlined,
  'Nhạc cụ': Icons.piano_outlined,
  'Mỹ phẩm': Icons.card_giftcard_outlined,
};

/// M-HM-01: Home Discovery Feed Screen (Tab 1 Root)
/// Hierarchy:
/// 1. Header / Greeting / Search + Quick Sell ("Đăng bán đồ") entry
/// 2. Categories strip
/// 3. Featured Auctions (Horizontally scrollable carousel, ~1.5–2 cards visible)
/// 4. New Arrivals ("Hàng mới lên kệ" — Horizontally scrollable product carousel)
/// 5. Nearby Popular Secondhand Stores ("Tiệm đồ si được yêu thích gần bạn" — 2-column vertical marketplace grid)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedSecondhandFilter = 'Tất cả';

  static const List<String> _secondhandFilters = [
    'Tất cả',
    'Áo khoác',
    'Túi & Giày',
    'Đồ cổ',
    'Dưới 300K',
  ];

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
    final demoStore = ref.watch(retroDemoStoreProvider);
    final state = homeVM.state;
    final feed = state.data;

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: const IzithriftGlobalAppBar(),
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
              demoStore,
            );
          },
        ),
      ),
    );
  }

  /// Builds the carousel auction list so users always experience swipeable discovery
  /// while prioritizing real backend auctions first.
  List<AuctionSummaryModel> _resolveCarouselAuctions(
    HomeFeedModel feed,
    RetroDemoMarketplaceStore demoStore,
  ) {
    final result = <AuctionSummaryModel>[...feed.liveAuctions];
    if (result.length < 3) {
      final existingIds = result.map((a) => a.id).toSet();
      for (final demo in demoStore.demoHomeAuctionSummaries) {
        if (!existingIds.contains(demo.id)) {
          result.add(demo);
        }
      }
    }
    return result;
  }

  /// Builds New Arrivals horizontal carousel items (backend first, enriched if sparse).
  List<ProductSummaryModel> _resolveNewArrivals(
    HomeFeedModel feed,
    RetroDemoMarketplaceStore demoStore,
  ) {
    final result = <ProductSummaryModel>[...feed.latestProducts];
    if (result.length < 4) {
      final existingIds = result.map((p) => p.id).toSet();
      for (final demo in demoStore.demoCatalogProducts) {
        if (!existingIds.contains(demo.id)) {
          result.add(demo);
        }
      }
    }
    return result;
  }

  /// Builds the 2-column vertical Nearby Popular Secondhand Stores product discovery feed.
  List<ProductSummaryModel> _resolveNearbyMarketplaceItems(
    HomeFeedModel feed,
    RetroDemoMarketplaceStore demoStore,
  ) {
    final merged = <ProductSummaryModel>[];
    final seenIds = <int>{};
    // Include backend products & curated local vintage finds with rich photography
    for (final item in feed.latestProducts) {
      if (seenIds.add(item.id)) merged.add(item);
    }
    for (final item in demoStore.demoCatalogProducts) {
      if (seenIds.add(item.id)) merged.add(item);
    }
    return merged;
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HomeFeedModel feed,
    HomeViewModel homeVM,
    RetroDemoMarketplaceStore demoStore,
  ) {
    final carouselAuctions = _resolveCarouselAuctions(feed, demoStore);
    final newArrivals = _resolveNewArrivals(feed, demoStore);
    final nearbyProducts = _resolveNearbyMarketplaceItems(feed, demoStore);

    return RefreshIndicator(
      onRefresh: homeVM.refresh,
      color: AppColors.ctaTerracotta,
      backgroundColor: AppColors.surfaceCard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: DesignTokens.space2xl),
        children: [
          // ── 1. Search Bar + Adjacent Dedicated Filter Button ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceLg,
              DesignTokens.spaceMd,
              DesignTokens.spaceLg,
              DesignTokens.spaceMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: RetroSearchPill(
                    placeholder: 'Tìm kiếm sản phẩm, thương hiệu...',
                    showTrailingFilter: false,
                    onTap: () => context.push(AppRoutes.search),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.surfaceCard,
                  borderRadius: DesignTokens.borderRadiusFull,
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.search),
                    borderRadius: DesignTokens.borderRadiusFull,
                    child: Ink(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderWarm,
                          width: 1,
                        ),
                        boxShadow: DesignTokens.cardElevation,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.pineDeep,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Quick Category Circles Strip (6 Compact Circular Buttons) ─
          _buildCategoriesStrip(context, ref, feed.categories),
          const SizedBox(height: DesignTokens.spaceMd + 2),

          // ── 3. Seasonal Curated Hero Banner (Cozy Vintage Christmas) ─────
          _buildHeroBanner(context),
          const SizedBox(height: DesignTokens.spaceLg + 2),

          // ── 4. Featured Auctions ("Đấu giá nổi bật") — Horizontal Carousel
          if (carouselAuctions.isNotEmpty) ...[
            _buildAuctionCarouselModule(context, carouselAuctions),
            const SizedBox(height: DesignTokens.spaceLg + 2),
          ],

          // ── 5. New Arrivals ("Hàng mới lên kệ") — Horizontal Carousel ────
          if (newArrivals.isNotEmpty) ...[
            _buildNewArrivalsCarouselSection(context, newArrivals, homeVM),
            const SizedBox(height: DesignTokens.spaceXl),
          ],

          // ── 6. Nearby Popular Secondhand Stores (2-Column Grid) ──────────
          _buildNearbyPopularStoresSection(
            context,
            feed.featuredSellers,
            nearbyProducts.take(4).toList(),
            homeVM,
          ),
          const SizedBox(height: DesignTokens.spaceXl),

          // ── 7. Pass đồ 2hand — Approved Secondhand Product Discovery Feed ─
          _buildSecondhandDiscoveryFeedSection(
            context,
            nearbyProducts,
            homeVM,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Cozy Editorial Winter Hero Banner (Deep Pine Green + Gold + Terracotta)
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
            maxFlakes: 9,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF103728),
                    AppColors.pineDeep,
                    Color(0xFF1F6349),
                  ],
                  stops: [0.0, 0.55, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  Positioned(
                    right: -22,
                    bottom: -26,
                    child: Container(
                      width: 155,
                      height: 155,
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
                  Positioned(
                    top: 10,
                    right: 108,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.starGold.withValues(alpha: 0.72),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    bottom: 14,
                    child: Container(
                      width: 104,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.starGold.withValues(alpha: 0.42),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              ProductImageResolver.assetVarsityJacket,
                              fit: BoxFit.cover,
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.50),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pineDeep.withValues(
                                    alpha: 0.88,
                                  ),
                                  borderRadius: DesignTokens.borderRadiusFull,
                                ),
                                child: const Text(
                                  'Retro 90s',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontBody,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.starGold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 128, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
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
                                size: 11,
                                color: AppColors.pineDeep,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'BỘ SƯU TẬP MÙA ĐÔNG',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pineDeep,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sống chất hơn\nvới đồ si tuyển chọn!',
                          style: TextStyle(
                            fontFamily: AppTypography.fontHeading,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Material(
                          color: AppColors.ctaTerracotta,
                          borderRadius: DesignTokens.borderRadiusFull,
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.discover),
                            borderRadius: DesignTokens.borderRadiusFull,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7.5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Khám phá ngay',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontBody,
                                      fontSize: 12,
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
  // 2. Quick 6-Circle Category Row (Direct Below Search Bar, Reference Layout)
  // ---------------------------------------------------------------------------
  Widget _buildCategoriesStrip(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> categories,
  ) {
    final List<({int? id, String label, IconData icon, bool isMore})> items = [];

    if (categories.isNotEmpty) {
      for (final cat in categories.take(5)) {
        final name = (cat.name as String).trim();
        final shortLabel = name == 'Túi xách' ? 'Túi' : name;
        items.add((
          id: cat.id as int?,
          label: shortLabel,
          icon: _kCategoryIcons[name] ?? Icons.checkroom_rounded,
          isMore: false,
        ));
      }
    } else {
      items.addAll(const [
        (id: null, label: 'Áo', icon: Icons.checkroom_rounded, isMore: false),
        (id: null, label: 'Quần', icon: Icons.layers_outlined, isMore: false),
        (id: null, label: 'Giày', icon: Icons.hiking_rounded, isMore: false),
        (id: null, label: 'Túi', icon: Icons.shopping_bag_outlined, isMore: false),
        (id: null, label: 'Phụ kiện', icon: Icons.watch_outlined, isMore: false),
      ]);
    }

    // 6th shortcut ("Khác") preserves full access to CategoryTaxonomyScreen (/discover)
    items.add(const (
      id: null,
      label: 'Khác',
      icon: Icons.grid_view_rounded,
      isMore: true,
    ));

    return SizedBox(
      height: 70,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: AppColors.surfaceCard,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                if (item.isMore) {
                  context.push(AppRoutes.discover);
                } else {
                  final searchVM = ref.read(catalogSearchViewModelProvider);
                  if (item.id != null) {
                    searchVM.search(ProductFilterQuery(categoryId: item.id));
                  } else {
                    searchVM.addRecentKeyword(item.label);
                    searchVM.search(ProductFilterQuery(q: item.label));
                  }
                  context.push(AppRoutes.search);
                }
              },
              customBorder: const CircleBorder(),
              child: Ink(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceCard,
                  border: Border.all(
                    color: item.isMore
                        ? AppColors.pineDeep.withValues(alpha: 0.25)
                        : AppColors.borderWarm,
                    width: 1,
                  ),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: item.isMore
                          ? AppColors.ctaTerracotta
                          : AppColors.pineDeep,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textCharcoal,
                          height: 1.1,
                        ),
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

  // ---------------------------------------------------------------------------
  // 3. Featured Auctions ("Đấu giá nổi bật") — Horizontal Swipe Carousel
  // ---------------------------------------------------------------------------
  Widget _buildAuctionCarouselModule(
    BuildContext context,
    List<AuctionSummaryModel> auctions,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.43).clamp(152.0, 178.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: RetroSectionHeader(
            title: 'Đấu giá nổi bật',
            icon: Icons.gavel_rounded,
            iconColor: AppColors.ctaTerracotta,
            actionLabel: 'Xem tất cả',
            onAction: () => context.go(AppRoutes.auctions),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        SizedBox(
          height: 214,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: auctions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              final auction = auctions[index];
              return SizedBox(
                width: cardWidth,
                child: RetroAuctionCard(
                  id: auction.id,
                  title: auction.title,
                  currentBid: auction.currentBid,
                  startingPrice: auction.startingPrice,
                  bidCount: auction.bidCount,
                  watchCount: auction.watchCount,
                  startsAt: auction.startsAt,
                  endsAt: auction.endsAt,
                  primaryImageUrl: auction.primaryImageUrl,
                  categoryName: auction.categoryName,
                  status: auction.status,
                  extendedCount: auction.extendedCount,
                  isOwner: auction.isOwner,
                  compactCarousel: true,
                  onTap: () => context.push(
                    AppRoutes.auctionRoomPath(auction.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. New Arrivals ("Hàng mới lên kệ") — Horizontal Product Carousel
  // ---------------------------------------------------------------------------
  Widget _buildNewArrivalsCarouselSection(
    BuildContext context,
    List<ProductSummaryModel> products,
    HomeViewModel homeVM,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.43).clamp(154.0, 180.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: RetroSectionHeader(
            title: 'Hàng mới lên kệ',
            icon: Icons.star_rounded,
            iconColor: AppColors.starGold,
            actionLabel: 'Xem tất cả',
            onAction: () => context.push(AppRoutes.search),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        SizedBox(
          height: 262,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: cardWidth,
                child: RetroProductCard(
                  id: product.id,
                  title: product.title,
                  price: product.price,
                  primaryImageUrl: product.primaryImageUrl,
                  condition: product.condition,
                  categoryName: product.categoryName,
                  sellerName: product.sellerDisplayName,
                  isOwner: product.isOwner,
                  isLiked: product.isFavorited,
                  onTap: () => context.push(
                    AppRoutes.productDetailPath(product.id),
                  ),
                  onLikeToggle: () =>
                      homeVM.toggleFavorite(context, product.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Nearby Popular Secondhand Stores ("Tiệm đồ si được yêu thích gần bạn")
  //    Compact Nearby Shops Strip + 2-Column Vertical Marketplace Product Grid
  // ---------------------------------------------------------------------------
  Widget _buildNearbyPopularStoresSection(
    BuildContext context,
    List<FeaturedSellerModel> sellers,
    List<ProductSummaryModel> products,
    HomeViewModel homeVM,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: RetroSectionHeader(
            title: 'Tiệm đồ si được yêu thích gần bạn',
            subtitle: 'Đồ secondhand tuyển chọn từ các chủ tiệm gần khu vực của bạn',
            icon: Icons.location_on_rounded,
            iconColor: AppColors.ctaTerracotta,
            actionLabel: 'Xem tất cả',
            onAction: () => context.push(AppRoutes.featuredSellers),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSm + 2),

        // Compact horizontal nearby trusted-shop quick pills
        if (sellers.isNotEmpty) ...[
          _buildCompactNearbyShopChips(context, sellers),
          const SizedBox(height: DesignTokens.spaceMd),
        ],

        // 2-Column Vertical Marketplace Discovery Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.54,
              crossAxisSpacing: 11,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              final distance = ProductImageResolver.nearbyDistanceLabel(
                productId: product.id,
                sellerId: product.sellerId,
              );
              return RetroProductCard(
                id: product.id,
                title: product.title,
                price: product.price,
                primaryImageUrl: product.primaryImageUrl,
                condition: product.condition,
                categoryName: product.categoryName,
                distanceLabel: distance,
                showConditionPercent: true,
                sellerName: product.sellerDisplayName,
                isOwner: product.isOwner,
                isLiked: product.isFavorited,
                onTap: () => context.push(
                  AppRoutes.productDetailPath(product.id),
                ),
                onLikeToggle: () => homeVM.toggleFavorite(context, product.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNearbyShopChips(
    BuildContext context,
    List<FeaturedSellerModel> sellers,
  ) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
        scrollDirection: Axis.horizontal,
        itemCount: sellers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final seller = sellers[index];
          final targetSellerId = seller.userId > 0 ? seller.userId : seller.id;
          final distance = ProductImageResolver.nearbyDistanceLabel(
            sellerId: targetSellerId,
          );
          return Material(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusFull,
            child: InkWell(
              onTap: () =>
                  context.push(AppRoutes.sellerStorefrontPath(targetSellerId)),
              borderRadius: DesignTokens.borderRadiusFull,
              child: Ink(
                padding: const EdgeInsets.fromLTRB(7, 6, 13, 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: DesignTokens.borderRadiusFull,
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index.isOdd
                            ? const Color(0xFF3E2B1E)
                            : AppColors.categoryCircleEnd,
                        border: Border.all(
                          color: AppColors.creamBadgeBorder,
                          width: 1.2,
                        ),
                      ),
                      child: seller.avatarUrl != null &&
                              seller.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: seller.avatarUrl!,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Icon(
                                  Icons.storefront_rounded,
                                  size: 18,
                                  color: index.isOdd
                                      ? AppColors.creamBadgeBg
                                      : AppColors.pineDeep,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.storefront_rounded,
                              size: 18,
                              color: index.isOdd
                                  ? AppColors.creamBadgeBg
                                  : AppColors.pineDeep,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              seller.shopName,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: AppColors.verifiedLeaf,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: AppColors.starGold,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${seller.ratingAvg.toStringAsFixed(1)} • $distance',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // ---------------------------------------------------------------------------
  // 7. "Pass đồ 2hand" — Approved Public Secondhand Product Discovery Feed
  // ---------------------------------------------------------------------------
  List<ProductSummaryModel> _filterSecondhandItems(
    List<ProductSummaryModel> products,
  ) {
    if (_selectedSecondhandFilter == 'Tất cả') return products;
    return products.where((item) {
      final cat = (item.categoryName ?? '').toLowerCase();
      final title = item.title.toLowerCase();
      switch (_selectedSecondhandFilter) {
        case 'Áo khoác':
          return cat.contains('áo') ||
              title.contains('áo') ||
              title.contains('jacket') ||
              title.contains('denim');
        case 'Túi & Giày':
          return cat.contains('túi') ||
              cat.contains('giày') ||
              title.contains('túi') ||
              title.contains('giày') ||
              title.contains('boots');
        case 'Đồ cổ':
          return cat.contains('đồ cổ') ||
              cat.contains('điện tử') ||
              cat.contains('phụ kiện') ||
              title.contains('máy ảnh') ||
              title.contains('đồng hồ') ||
              title.contains('film');
        case 'Dưới 300K':
          return item.price <= 300000;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildSecondhandDiscoveryFeedSection(
    BuildContext context,
    List<ProductSummaryModel> allProducts,
    HomeViewModel homeVM,
  ) {
    final filtered = _filterSecondhandItems(allProducts);
    final displayItems = filtered.isEmpty ? allProducts : filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: RetroSectionHeader(
            title: 'Pass đồ 2hand',
            subtitle: 'Khám phá món đồ đã qua kiểm duyệt từ cộng đồng izithrift',
            icon: Icons.recycling_rounded,
            iconColor: AppColors.pineDeep,
            actionLabel: 'Tìm thêm',
            onAction: () => context.push(AppRoutes.search),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSm + 2),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceLg,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: _secondhandFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final label = _secondhandFilters[index];
              final isSelected = _selectedSecondhandFilter == label;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedSecondhandFilter = label);
                },
                selectedColor: AppColors.pineDeep,
                backgroundColor: AppColors.surfaceCard,
                showCheckmark: false,
                labelStyle: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textCharcoal,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.pineDeep : AppColors.borderWarm,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              );
            },
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: displayItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.54,
              crossAxisSpacing: 11,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final product = displayItems[index];
              final distance = ProductImageResolver.nearbyDistanceLabel(
                productId: product.id,
                sellerId: product.sellerId,
              );
              return RetroProductCard(
                id: product.id,
                title: product.title,
                price: product.price,
                primaryImageUrl: product.primaryImageUrl,
                condition: product.condition,
                categoryName: product.categoryName,
                distanceLabel: distance,
                showConditionPercent: true,
                sellerName: product.sellerDisplayName,
                isOwner: product.isOwner,
                isLiked: product.isFavorited,
                onTap: () => context.push(
                  AppRoutes.productDetailPath(product.id),
                ),
                onLikeToggle: () => homeVM.toggleFavorite(context, product.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
