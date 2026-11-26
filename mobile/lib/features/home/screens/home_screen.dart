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
import '../../auth/widgets/auth_login_bottom_sheet.dart';
import '../../catalog/models/product_filter_query.dart';
import '../../catalog/models/product_summary_model.dart';
import '../../catalog/viewmodels/catalog_search_view_model.dart';
import '../models/auction_summary_model.dart';
import '../models/featured_seller_model.dart';
import '../models/home_feed_model.dart';
import '../viewmodels/home_view_model.dart';

class _FashionCategoryItem {
  final String label;
  final String searchKeyword;
  final IconData icon;
  final Color iconColor;
  final Color tileTint;

  const _FashionCategoryItem({
    required this.label,
    required this.searchKeyword,
    required this.icon,
    required this.iconColor,
    required this.tileTint,
  });
}

const List<_FashionCategoryItem> _kSecondhandFashionCategories = [
  _FashionCategoryItem(
    label: 'American Tee',
    searchKeyword: 'American Tee',
    icon: Icons.checkroom_rounded,
    iconColor: Color(0xFFB34B2E),
    tileTint: Color(0xFFFAF0EB),
  ),
  _FashionCategoryItem(
    label: 'Boxy Tee',
    searchKeyword: 'Boxy Tee',
    icon: Icons.dry_cleaning_outlined,
    iconColor: Color(0xFF1A4B38),
    tileTint: Color(0xFFEDF5F1),
  ),
  _FashionCategoryItem(
    label: 'Flare Jeans',
    searchKeyword: 'Flare Jeans',
    icon: Icons.layers_outlined,
    iconColor: Color(0xFF2E4D7B),
    tileTint: Color(0xFFEEF3FA),
  ),
  _FashionCategoryItem(
    label: 'Denim Jacket',
    searchKeyword: 'Denim Jacket',
    icon: Icons.shield_outlined,
    iconColor: Color(0xFF395273),
    tileTint: Color(0xFFEFF2F7),
  ),
  _FashionCategoryItem(
    label: 'Vintage Shirt',
    searchKeyword: 'Vintage Shirt',
    icon: Icons.style_outlined,
    iconColor: Color(0xFF9C6621),
    tileTint: Color(0xFFFAF4E6),
  ),
  _FashionCategoryItem(
    label: 'Trousers',
    searchKeyword: 'Trousers',
    icon: Icons.straighten_rounded,
    iconColor: Color(0xFF6B4C35),
    tileTint: Color(0xFFF6F0EA),
  ),
  _FashionCategoryItem(
    label: 'Sneakers',
    searchKeyword: 'Sneakers',
    icon: Icons.hiking_rounded,
    iconColor: Color(0xFFA63434),
    tileTint: Color(0xFFFBEEEE),
  ),
  _FashionCategoryItem(
    label: 'Leather Bags',
    searchKeyword: 'Leather Bags',
    icon: Icons.work_outline_rounded,
    iconColor: Color(0xFF7B4A2D),
    tileTint: Color(0xFFF7EFE9),
  ),
  _FashionCategoryItem(
    label: 'Watches',
    searchKeyword: 'Watches',
    icon: Icons.watch_outlined,
    iconColor: Color(0xFF8C6B1F),
    tileTint: Color(0xFFFBF6E5),
  ),
  _FashionCategoryItem(
    label: 'Accessories',
    searchKeyword: 'Accessories',
    icon: Icons.diamond_outlined,
    iconColor: Color(0xFF28635A),
    tileTint: Color(0xFFECF6F4),
  ),
  _FashionCategoryItem(
    label: 'Sweaters',
    searchKeyword: 'Sweaters',
    icon: Icons.ac_unit_rounded,
    iconColor: Color(0xFF873A43),
    tileTint: Color(0xFFF9EEF0),
  ),
  _FashionCategoryItem(
    label: 'Outerwear',
    searchKeyword: 'Outerwear',
    icon: Icons.umbrella_outlined,
    iconColor: Color(0xFF3D5937),
    tileTint: Color(0xFFF0F5EE),
  ),
];

/// M-HM-01: Home Discovery Feed Screen (Tab 1 Root)
/// Redesigned layout:
/// 1. Search Bar + Dedicated Filter Trigger
/// 2. Contained Horizontal Secondhand Fashion Categories + Scroll Progress Bar
/// 3. Cozy Vintage Seasonal Hero Banner
/// 4. Featured Auctions ("Đấu giá nổi bật") — Horizontal Carousel
/// 5. New Arrivals ("Hàng mới lên kệ") — Horizontal Product Carousel
/// 6. Nearby Thrift Shops ("Tiệm đồ si ở gần bạn") — Actual Storefront Cards Carousel
/// 7. Discovery Feed ("Bạn có thể đang tìm kiếm") — Filterable, Paginated 2-Col Product Grid
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _feedBatchSize = 14;

  final ScrollController _categoryScrollController = ScrollController();
  double _categoryScrollProgress = 0.0;

  String _selectedSecondhandFilter = 'Tất cả';
  int _visibleFeedCount = _feedBatchSize;

  static const List<String> _secondhandFilters = [
    'Tất cả',
    'Áo & Tee',
    'Denim & Quần',
    'Giày & Túi',
    'Phụ kiện',
    'Dưới 300K',
  ];

  @override
  void initState() {
    super.initState();
    _categoryScrollController.addListener(_onCategoryScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider).loadHomeFeed();
    });
  }

  void _onCategoryScroll() {
    if (!_categoryScrollController.hasClients) return;
    final maxExtent = _categoryScrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final nextProgress =
        (_categoryScrollController.offset / maxExtent).clamp(0.0, 1.0);
    if ((nextProgress - _categoryScrollProgress).abs() >= 0.015) {
      setState(() => _categoryScrollProgress = nextProgress);
    }
  }

  @override
  void dispose() {
    _categoryScrollController.removeListener(_onCategoryScroll);
    _categoryScrollController.dispose();
    super.dispose();
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

  /// Builds the carousel auction list prioritizing real backend auctions first.
  List<AuctionSummaryModel> _resolveCarouselAuctions(
    HomeFeedModel feed,
    RetroDemoMarketplaceStore demoStore,
  ) {
    final result = <AuctionSummaryModel>[...feed.liveAuctions];
    if (result.length < 4) {
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
    if (result.length < 8) {
      final existingIds = result.map((p) => p.id).toSet();
      for (final demo in demoStore.demoCatalogProducts) {
        if (!existingIds.contains(demo.id)) {
          result.add(demo);
        }
        if (result.length >= 10) break;
      }
    }
    return result.take(10).toList();
  }

  /// Builds the full product discovery feed (backend items + 44 diverse demo items).
  List<ProductSummaryModel> _resolveDiscoveryProducts(
    HomeFeedModel feed,
    RetroDemoMarketplaceStore demoStore,
  ) {
    final merged = <ProductSummaryModel>[];
    final seenIds = <int>{};
    for (final item in feed.latestProducts) {
      if (seenIds.add(item.id)) merged.add(item);
    }
    for (final item in demoStore.demoCatalogProducts) {
      if (seenIds.add(item.id)) merged.add(item);
    }
    return merged;
  }

  /// Merges live backend featured sellers with curated local nearby thrift shops.
  List<DemoNearbyShopInfo> _resolveNearbyShops(
    List<FeaturedSellerModel> backendSellers,
  ) {
    final result = <DemoNearbyShopInfo>[];
    final seenIds = <int>{};

    const coverAssets = [
      ProductImageResolver.assetDenimJeans,
      ProductImageResolver.assetVarsityJacket,
      ProductImageResolver.assetLeatherBag,
      ProductImageResolver.assetRetroSneakers,
      ProductImageResolver.assetMechanicalWatch,
      ProductImageResolver.assetFlannelShirt,
      ProductImageResolver.assetKnitCardigan,
      ProductImageResolver.assetFilmCamera,
    ];
    const districts = [
      'Quận 1, TP.HCM',
      'Quận 3, TP.HCM',
      'Bình Thạnh, TP.HCM',
      'Phú Nhuận, TP.HCM',
      'Thủ Đức, TP.HCM',
    ];

    for (var i = 0; i < backendSellers.length; i++) {
      final s = backendSellers[i];
      final targetId = s.userId > 0 ? s.userId : s.id;
      if (!seenIds.add(targetId)) continue;

      final matchingDemos = RetroDemoMarketplaceStore.demoNearbyShops.where(
        (d) => d.sellerId == targetId || d.shopSlug == s.shopSlug,
      );
      final matchingDemo =
          matchingDemos.isNotEmpty ? matchingDemos.first : null;
      if (matchingDemo != null) {
        result.add(matchingDemo);
      } else {
        result.add(
          DemoNearbyShopInfo(
            sellerId: targetId,
            shopName: s.shopName,
            shopSlug: s.shopSlug,
            district: districts[i % districts.length],
            distanceLabel: ProductImageResolver.nearbyDistanceLabel(
              sellerId: targetId,
            ),
            specialtyTag: 'Đồ si tuyển chọn',
            coverAsset: coverAssets[i % coverAssets.length],
            bio: s.bio ?? 'Tiệm đồ si tuyển chọn uy tín trên izithrift.',
            trustScore: s.trustScore,
            ratingAvg: s.ratingAvg > 0 ? s.ratingAvg : 4.8,
            completedOrdersCount:
                s.completedOrdersCount > 0 ? s.completedOrdersCount : 64,
            followersCount: 180 + (i * 45),
            activeItemsCount: 18 + (i * 5),
          ),
        );
      }
    }

    for (final demoShop in RetroDemoMarketplaceStore.demoNearbyShops) {
      if (seenIds.add(demoShop.sellerId)) {
        result.add(demoShop);
      }
    }
    return result;
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
    final nearbyShops = _resolveNearbyShops(feed.featuredSellers);
    final discoveryProducts = _resolveDiscoveryProducts(feed, demoStore);

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

          // ── 2. Visually Contained Fashion Categories + Scroll Indicator ──
          _buildCategoriesContainer(context, ref, feed.categories),
          const SizedBox(height: DesignTokens.spaceMd + 2),

          // ── 3. Seasonal Curated Hero Banner (Cozy Vintage Christmas) ─────
          _buildHeroBanner(context),
          const SizedBox(height: DesignTokens.spaceLg + 4),

          // ── 4. Featured Auctions ("Đấu giá nổi bật") — Horizontal Carousel
          if (carouselAuctions.isNotEmpty) ...[
            _buildAuctionCarouselModule(context, ref, carouselAuctions),
            const SizedBox(height: DesignTokens.spaceLg + 4),
          ],

          // ── 5. New Arrivals ("Hàng mới lên kệ") — Horizontal Carousel ────
          if (newArrivals.isNotEmpty) ...[
            _buildNewArrivalsCarouselSection(context, newArrivals, homeVM),
            const SizedBox(height: DesignTokens.spaceXl),
          ],

          // ── 6. Nearby Thrift Shops ("Tiệm đồ si ở gần bạn") — Store Cards
          _buildNearbyThriftShopsSection(context, nearbyShops),
          const SizedBox(height: DesignTokens.spaceXl),

          // ── 7. Discovery Feed ("Bạn có thể đang tìm kiếm") — Paginated Grid
          _buildSecondhandDiscoveryFeedSection(
            context,
            discoveryProducts,
            homeVM,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Visually Contained Compact Categories Card + Horizontal Scroll Indicator
  // ---------------------------------------------------------------------------
  Widget _buildCategoriesContainer(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> backendCategories,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderWarm),
          boxShadow: DesignTokens.cardElevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with "Khác" quick taxonomy shortcut (always visible)
            Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 14,
                  color: AppColors.pineDeep,
                ),
                const SizedBox(width: 5),
                Text(
                  'Danh mục đồ si',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppColors.pineDeep,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.creamBadgeSoft,
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(color: AppColors.creamBadgeBorder),
                  ),
                  child: Text(
                    '${_kSecondhandFashionCategories.length} phong cách',
                    style: AppTypography.caption.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.creamBadgeText,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => context.push(AppRoutes.discover),
                  borderRadius: DesignTokens.borderRadiusFull,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Khác',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ctaTerracotta,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 13,
                          color: AppColors.ctaTerracotta,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontally scrollable 12 diverse secondhand fashion categories
            SizedBox(
              height: 76,
              child: ListView.separated(
                controller: _categoryScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _kSecondhandFashionCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _kSecondhandFashionCategories[index];
                  return SizedBox(
                    width: 68,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          final searchVM =
                              ref.read(catalogSearchViewModelProvider);
                          int? matchedCategoryId;
                          for (final bc in backendCategories) {
                            final bcName = (bc.name as String).toLowerCase();
                            if (bcName == cat.label.toLowerCase()) {
                              matchedCategoryId = bc.id as int?;
                              break;
                            }
                          }
                          if (matchedCategoryId != null) {
                            searchVM.search(
                              ProductFilterQuery(categoryId: matchedCategoryId),
                            );
                          } else {
                            searchVM.addRecentKeyword(cat.searchKeyword);
                            searchVM.search(
                              ProductFilterQuery(q: cat.searchKeyword),
                            );
                          }
                          context.push(AppRoutes.search);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cat.tileTint,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: cat.iconColor.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Icon(
                                cat.icon,
                                color: cat.iconColor,
                                size: 21,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              cat.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textCharcoal,
                                height: 1.12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Subtle horizontal scroll progress indicator
            Center(
              child: SizedBox(
                width: 68,
                height: 4,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const thumbWidth = 24.0;
                    final travel =
                        (constraints.maxWidth - thumbWidth).clamp(0.0, 68.0);
                    return Stack(
                      children: [
                        Container(
                          width: constraints.maxWidth,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderWarm.withValues(alpha: 0.75),
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                        ),
                        Positioned(
                          left: travel * _categoryScrollProgress,
                          child: Container(
                            width: thumbWidth,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.pineDeep,
                              borderRadius: DesignTokens.borderRadiusFull,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Cozy Editorial Winter Hero Banner (Deep Pine Green + Gold + Terracotta)
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
  // 4. Featured Auctions ("Đấu giá nổi bật") — Distinctive Live Header + Carousel
  // ---------------------------------------------------------------------------
  Widget _buildAuctionCarouselModule(
    BuildContext context,
    WidgetRef ref,
    List<AuctionSummaryModel> auctions,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.45).clamp(158.0, 184.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.priceCrimsonSoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.priceCrimsonBorder),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  size: 17,
                  color: AppColors.priceCrimson,
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
                            'Đấu giá nổi bật',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headingMedium.copyWith(
                              fontSize: 18.5,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.priceCrimson,
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 6, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Săn món vintage hiếm theo thời gian thực',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSectionActionPill(
                label: 'Xem tất cả',
                color: AppColors.priceCrimson,
                onTap: () {
                  final allowed = requireAuthOrPrompt(
                    context,
                    ref,
                    featureTitle: 'Đăng nhập để tham gia Đấu giá',
                    description:
                        'Theo dõi phiên trực tiếp, đặt giá thời gian thực và săn các món đồ vintage hiếm.',
                    intendedTarget: const PendingNavigationTarget(
                      route: AppRoutes.auctions,
                      useGo: true,
                    ),
                    icon: Icons.gavel_rounded,
                  );
                  if (allowed) {
                    context.go(AppRoutes.auctions);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        SizedBox(
          height: 222,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: auctions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 11),
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
                  onTap: () {
                    final targetPath = AppRoutes.auctionRoomPath(auction.id);
                    final allowed = requireAuthOrPrompt(
                      context,
                      ref,
                      featureTitle: 'Đăng nhập để vào phòng đấu giá',
                      description:
                          'Đặt giá trực tiếp, nhận thông báo vượt giá và giữ quyền mua ngay khi phiên kết thúc.',
                      intendedTarget: PendingNavigationTarget(
                        route: targetPath,
                      ),
                      icon: Icons.gavel_rounded,
                    );
                    if (allowed) {
                      context.push(targetPath);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. New Arrivals ("Hàng mới lên kệ") — Gold Ribbon Editorial Header + Carousel
  // ---------------------------------------------------------------------------
  Widget _buildNewArrivalsCarouselSection(
    BuildContext context,
    List<ProductSummaryModel> products,
    HomeViewModel homeVM,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.43).clamp(154.0, 178.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4.5,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.starGold, AppColors.ctaTerracotta],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MỚI TUYỂN CHỌN HÔM NAY',
                      style: AppTypography.caption.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ctaTerracotta,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      'Hàng mới lên kệ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMedium.copyWith(
                        fontSize: 18.5,
                        color: AppColors.pineDeep,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSectionActionPill(
                label: 'Xem tất cả',
                color: AppColors.pineDeep,
                onTap: () => context.push(AppRoutes.search),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        SizedBox(
          height: 256,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 11),
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
                  showConditionPercent: true,
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
  // 6. Nearby Thrift Shops ("Tiệm đồ si ở gần bạn") — Actual Storefront Cards
  // ---------------------------------------------------------------------------
  Widget _buildNearbyThriftShopsSection(
    BuildContext context,
    List<DemoNearbyShopInfo> shops,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.pineDeep,
                  shape: BoxShape.circle,
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 17,
                  color: AppColors.creamBadgeBg,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiệm đồ si ở gần bạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMedium.copyWith(
                        fontSize: 18.5,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Ghé thăm ${shops.length} tiệm secondhand uy tín quanh khu vực của bạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSectionActionPill(
                label: 'Xem tất cả',
                color: AppColors.ctaTerracotta,
                onTap: () => context.push(AppRoutes.featuredSellers),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),

        // Horizontally scrollable thrift shop cards (Store cards, NOT product cards)
        SizedBox(
          height: 216,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildNearbyShopCard(context, shops[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyShopCard(
    BuildContext context,
    DemoNearbyShopInfo shop,
    int index,
  ) {
    final monogram = shop.shopName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final avatarBg = index.isEven ? AppColors.pineDeep : const Color(0xFF5A3928);

    return SizedBox(
      width: 220,
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.sellerStorefrontPath(shop.sellerId),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderWarm),
              boxShadow: DesignTokens.cardElevation,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Cover Photo + Distance Pill + Verified Badge
                SizedBox(
                  height: 82,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        shop.coverAsset,
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.14),
                              Colors.black.withValues(alpha: 0.52),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 11,
                                color: AppColors.ctaTerracotta,
                              ),
                              const SizedBox(width: 2.5),
                              Text(
                                shop.distanceLabel,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textCharcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.5,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pineDeep.withValues(alpha: 0.9),
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 10.5,
                                color: AppColors.starGold,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Uy tín',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Store monogram anchored bottom-left of cover
                      Positioned(
                        left: 10,
                        bottom: 7,
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: avatarBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.8,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                monogram,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.creamBadgeBg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: DesignTokens.borderRadiusFull,
                              ),
                              child: Text(
                                '${shop.activeItemsCount} món đang bán',
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Store Details Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              shop.shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textCharcoal,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              shop.district,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.5,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.creamBadgeSoft,
                                borderRadius: DesignTokens.borderRadiusFull,
                                border: Border.all(
                                  color: AppColors.creamBadgeBorder,
                                ),
                              ),
                              child: Text(
                                shop.specialtyTag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.creamBadgeText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: AppColors.starGold,
                                    ),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      shop.ratingAvg.toStringAsFixed(1),
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textCharcoal,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '• ${shop.completedOrdersCount} đơn',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ghé tiệm →',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pineDeep,
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. "Bạn có thể đang tìm kiếm" — Filterable, Progressively Paginated Grid
  // ---------------------------------------------------------------------------
  List<ProductSummaryModel> _filterSecondhandItems(
    List<ProductSummaryModel> products,
  ) {
    if (_selectedSecondhandFilter == 'Tất cả') return products;
    return products.where((item) {
      final cat = (item.categoryName ?? '').toLowerCase();
      final title = item.title.toLowerCase();
      switch (_selectedSecondhandFilter) {
        case 'Áo & Tee':
          return cat.contains('tee') ||
              cat.contains('shirt') ||
              cat.contains('sweater') ||
              cat.contains('outerwear') ||
              cat.contains('áo') ||
              title.contains('tee') ||
              title.contains('áo') ||
              title.contains('sweater') ||
              title.contains('cardigan');
        case 'Denim & Quần':
          return cat.contains('jeans') ||
              cat.contains('denim') ||
              cat.contains('trousers') ||
              cat.contains('quần') ||
              title.contains('jeans') ||
              title.contains('denim') ||
              title.contains('quần');
        case 'Giày & Túi':
          return cat.contains('sneakers') ||
              cat.contains('bags') ||
              cat.contains('túi') ||
              cat.contains('giày') ||
              title.contains('sneakers') ||
              title.contains('giày') ||
              title.contains('túi') ||
              title.contains('boots');
        case 'Phụ kiện':
          return cat.contains('watches') ||
              cat.contains('accessories') ||
              cat.contains('phụ kiện') ||
              cat.contains('đồ cổ') ||
              title.contains('đồng hồ') ||
              title.contains('máy ảnh') ||
              title.contains('kính') ||
              title.contains('thắt lưng') ||
              title.contains('mũ');
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
    final visibleItems = displayItems.take(_visibleFeedCount).toList();
    final remainingCount = displayItems.length - visibleItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Distinctive Discovery Feed Editorial Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pineDeep.withValues(alpha: 0.1),
                      borderRadius: DesignTokens.borderRadiusFull,
                      border: Border.all(
                        color: AppColors.pineDeep.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          size: 12,
                          color: AppColors.pineDeep,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'GỢI Ý DÀNH CHO BẠN',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pineDeep,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildSectionActionPill(
                    label: 'Tìm thêm',
                    color: AppColors.pineDeep,
                    onTap: () => context.push(AppRoutes.search),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'Bạn có thể đang tìm kiếm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMedium.copyWith(
                        fontSize: 20,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${displayItems.length} món',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSm + 2),

        // Filter Chips Strip
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
                  setState(() {
                    _selectedSecondhandFilter = label;
                    _visibleFeedCount = _feedBatchSize;
                  });
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

        // 2-Column Compact Product Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: visibleItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 10,
              mainAxisSpacing: 11,
            ),
            itemBuilder: (context, index) {
              final product = visibleItems[index];
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

        // Progressive Pagination Footer
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: Column(
            children: [
              Text(
                'Đang hiển thị ${visibleItems.length} / ${displayItems.length} sản phẩm',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (remainingCount > 0) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pineDeep,
                      backgroundColor: AppColors.surfaceCard,
                      side: const BorderSide(
                        color: AppColors.pineDeep,
                        width: 1.25,
                      ),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _visibleFeedCount = (_visibleFeedCount + _feedBatchSize)
                            .clamp(0, displayItems.length);
                      });
                    },
                    icon: const Icon(Icons.expand_more_rounded, size: 19),
                    label: Text(
                      'Xem thêm sản phẩm (còn $remainingCount món)',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionActionPill({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.borderRadiusFull,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: color),
          ],
        ),
      ),
    );
  }
}
