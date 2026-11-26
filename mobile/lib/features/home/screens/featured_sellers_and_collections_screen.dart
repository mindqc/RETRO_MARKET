import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../viewmodels/home_view_model.dart';

/// M-HM-02: Curated Collections & Featured Stores
class FeaturedSellersAndCollectionsScreen extends ConsumerStatefulWidget {
  const FeaturedSellersAndCollectionsScreen({super.key});

  @override
  ConsumerState<FeaturedSellersAndCollectionsScreen> createState() =>
      _FeaturedSellersAndCollectionsScreenState();
}

class _FeaturedSellersAndCollectionsScreenState
    extends ConsumerState<FeaturedSellersAndCollectionsScreen> {
  String _selectedRegion = 'Tất cả';

  final List<Map<String, dynamic>> _curatedCollections = const [
    {
      'title': 'Áo dạ & Măng tô thập niên 90s',
      'subtitle': 'Hơn 120 mẫu áo dạ tuyển chọn từ bãi Nhật và Hàn',
      'tag': 'MÙA ĐÔNG 2026',
      'icon': Icons.dry_cleaning_rounded,
      'color': AppColors.pineDeep,
    },
    {
      'title': 'Đồng hồ cơ Thụy Sỹ & Nhật Bản cổ',
      'subtitle': 'Seiko, Citizen, Omega cơ khí lên dây cót nguyên bản',
      'tag': 'COLLECTORS',
      'icon': Icons.watch_rounded,
      'color': AppColors.priceCrimson,
    },
    {
      'title': 'Denim & Workwear phong cách Mỹ',
      'subtitle': 'Quần bò Levi\'s 501, áo khoác Carhartt rách bụi bặm',
      'tag': 'VINTAGE HERITAGE',
      'icon': Icons.checkroom_rounded,
      'color': AppColors.ctaTerracotta,
    },
    {
      'title': 'Túi xách & Phụ kiện da thật vintage',
      'subtitle': 'Da bò thuộc thảo mộc, cặp táp da đanh bóng patina',
      'tag': 'HANDMADE & LEATHER',
      'icon': Icons.shopping_bag_rounded,
      'color': AppColors.vintageBrown,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final homeVM = ref.watch(homeViewModelProvider);
    final sellers = homeVM.state.data?.featuredSellers ?? [];

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tiệm đồ si & Bộ sưu tập'),
        actions: [
          RetroHeaderIconButton(
            icon: Icons.favorite_border_rounded,
            tooltip: 'Đã lưu',
            onPressed: () => context.push(AppRoutes.favorites),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RetroAmbientSnowflakes(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildHeroBanner(),
            const SizedBox(height: 22),
            _buildRegionSelector(),
            const SizedBox(height: 24),
            _buildCollectionSection(context),
            const SizedBox(height: 28),
            _buildSellerSection(context, sellers),
            const SizedBox(height: 20),
            _buildBottomEditorial(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return RetroPineSpotlightContainer(
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -24,
            child: Icon(
              Icons.eco_rounded,
              size: 130,
              color: AppColors.creamBadgeBg.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.creamBadgeBg,
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.pineDeep,
                      size: 12,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'CURATED WITH LOVE',
                      style: TextStyle(
                        color: AppColors.creamBadgeText,
                        fontSize: 9.5,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tìm kho báu\nvintage.',
                style: TextStyle(
                  fontFamily: AppTypography.fontHeading,
                  fontSize: 28,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Những món đồ có câu chuyện. Những tiệm đồ si tuyển chọn có gu riêng.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Text(
                    'THE RETRO DIRECTORY',
                    style: TextStyle(
                      color: AppColors.creamBadgeBg,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.3,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.creamBadgeBg,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    const regions = ['Tất cả', 'TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RetroSectionHeader(
          title: 'Khám phá quanh bạn',
          icon: Icons.location_on_outlined,
          iconColor: AppColors.ctaTerracotta,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: regions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final region = regions[index];
              final selected = _selectedRegion == region;

              return InkWell(
                onTap: () => setState(() => _selectedRegion = region),
                borderRadius: DesignTokens.borderRadiusFull,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.ctaTerracotta
                        : AppColors.surfaceCard,
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(
                      color: selected
                          ? AppColors.ctaTerracotta
                          : AppColors.borderWarm,
                    ),
                    boxShadow: selected ? null : DesignTokens.cardElevation,
                  ),
                  child: Text(
                    region,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textCharcoal,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RetroSectionHeader(
          title: 'Bộ sưu tập tuyển chọn',
          subtitle: 'Những chủ đề dành cho người có gu vintage',
          icon: Icons.auto_awesome_rounded,
          iconColor: AppColors.starGold,
        ),
        const SizedBox(height: 14),
        _buildFeaturedCollection(context, _curatedCollections[0]),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMiniCollection(context, _curatedCollections[1])),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniCollection(context, _curatedCollections[2])),
          ],
        ),
        const SizedBox(height: 12),
        _buildFeaturedCollection(
          context,
          _curatedCollections[3],
          reverse: true,
        ),
      ],
    );
  }

  Widget _buildFeaturedCollection(
    BuildContext context,
    Map<String, dynamic> col, {
    bool reverse = false,
  }) {
    final color = col['color'] as Color;
    final icon = col['icon'] as IconData;

    return Material(
      color: color,
      borderRadius: DesignTokens.borderRadiusBanner,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.search),
        child: Container(
          height: 164,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              if (reverse) ...[
                _collectionEmblem(icon),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.creamBadgeBg,
                        borderRadius: DesignTokens.borderRadiusFull,
                      ),
                      child: Text(
                        col['tag'] as String,
                        style: const TextStyle(
                          color: AppColors.creamBadgeText,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      col['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontHeading,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1.18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      col['subtitle'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
              if (!reverse) ...[
                const SizedBox(width: 12),
                _collectionEmblem(icon),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _collectionEmblem(IconData icon) {
    return Container(
      width: 72,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: 36, color: AppColors.creamBadgeBg),
    );
  }

  Widget _buildMiniCollection(BuildContext context, Map<String, dynamic> col) {
    final color = col['color'] as Color;
    final icon = col['icon'] as IconData;

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: InkWell(
        onTap: () => context.push(AppRoutes.search),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Ink(
          height: 214,
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
              Container(
                height: 84,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.categoryCircleStart,
                      AppColors.categoryCircleEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.creamBadgeBorder),
                ),
                child: Icon(icon, color: color, size: 38),
              ),
              const SizedBox(height: 10),
              Text(
                col['tag'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  col['title'] as String,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.textCharcoal,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Khám phá',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 13),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellerSection(BuildContext context, List<dynamic> sellers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RetroSectionHeader(
          title: 'Những tiệm đáng ghé',
          subtitle: 'Gặp những người đứng sau các món đồ vintage',
          icon: Icons.storefront_rounded,
          iconColor: AppColors.starGold,
        ),
        const SizedBox(height: 14),
        if (sellers.isEmpty)
          RetroSectionContainer(
            backgroundColor: AppColors.surfaceCard,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.categoryCircleStart,
                        AppColors.categoryCircleEnd,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 28,
                    color: AppColors.pineDeep,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đang cập nhật danh sách các tiệm đồ si tuyển chọn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          )
        else
          ...sellers.map((seller) => _buildSellerCard(context, seller)),
      ],
    );
  }

  Widget _buildSellerCard(BuildContext context, dynamic seller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  ),
                  border: Border.all(color: AppColors.creamBadgeBorder),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.pineDeep,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.shopName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingSmall.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.starGold,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${seller.trustScore.toStringAsFixed(0)} điểm uy tín  •  ${seller.completedOrdersCount} đơn hoàn thành',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const RetroVerifiedShopChip(fontSize: 11),
                  ],
                ),
              ),
            ],
          ),
          if (seller.bio != null && (seller.bio as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.surfaceSection,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Text(
                seller.bio as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pineBanner,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final targetSellerId =
                    seller.userId > 0 ? seller.userId : seller.id;
                context.push(AppRoutes.sellerStorefrontPath(targetSellerId));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ghé tiệm'),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomEditorial() {
    return RetroSectionContainer(
      padding: const EdgeInsets.all(16),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: AppColors.priceCrimson,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đồ si không chỉ là mua sắm. '
              'Đó là tìm thấy một điều gì đó mà không ai khác có.',
              style: TextStyle(
                fontFamily: AppTypography.fontHeading,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: AppColors.textCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
