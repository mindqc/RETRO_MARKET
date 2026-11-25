import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/home_view_model.dart';

/// M-HM-02: Curated Collections & Featured Stores
/// Visual direction: Vintage Magazine × Social Commerce.
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
      'icon': Icons.dry_cleaning,
      'color': AppColors.secondaryPineGreen,
    },
    {
      'title': 'Đồng hồ cơ Thụy Sỹ & Nhật Bản cổ',
      'subtitle': 'Seiko, Citizen, Omega cơ khí lên dây cót nguyên bản',
      'tag': 'COLLECTORS',
      'icon': Icons.watch,
      'color': AppColors.christmasBerryRed,
    },
    {
      'title': 'Denim & Workwear phong cách Mỹ',
      'subtitle': 'Quần bò Levi\'s 501, áo khoác Carhartt rách bụi bặm',
      'tag': 'VINTAGE HERITAGE',
      'icon': Icons.accessibility_new,
      'color': AppColors.primaryTerracotta,
    },
    {
      'title': 'Túi xách & Phụ kiện da thật vintage',
      'subtitle': 'Da bò thuộc thảo mộc, cặp táp da đanh bóng patina',
      'tag': 'HANDMADE & LEATHER',
      'icon': Icons.shopping_bag,
      'color': AppColors.accentVintageGold,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final homeVM = ref.watch(homeViewModelProvider);
    final sellers = homeVM.state.data?.featuredSellers ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Tiệm đồ si & Bộ sưu tập',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textCharcoal,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryTerracotta.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.primaryTerracotta,
                size: 19,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.secondaryPineGreen,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryPineGreen.withAlpha(35),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -45,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundCream.withAlpha(18),
                    width: 28,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -45,
              child: Icon(
                Icons.eco_rounded,
                size: 160,
                color: AppColors.backgroundCream.withAlpha(12),
              ),
            ),
            Positioned(
              top: 20,
              right: 24,
              child: Icon(
                Icons.star_rounded,
                size: 21,
                color: AppColors.accentVintageGold,
              ),
            ),
            Positioned(
              top: 52,
              right: 68,
              child: Icon(
                Icons.auto_awesome,
                size: 13,
                color: AppColors.backgroundCream.withAlpha(150),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentVintageGold.withAlpha(30),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.accentVintageGold.withAlpha(100),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          color: AppColors.accentVintageGold,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'CURATED WITH LOVE',
                          style: TextStyle(
                            color: AppColors.accentVintageGold,
                            fontSize: 9,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tìm kho báu\nvintage.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 30,
                      height: 1.04,
                      fontWeight: FontWeight.w700,
                      color: AppColors.backgroundCream,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Những món đồ có câu chuyện.\nNhững tiệm có gu riêng.',
                    style: TextStyle(
                      color: AppColors.backgroundCream.withAlpha(210),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text(
                        'THE RETRO DIRECTORY',
                        style: TextStyle(
                          color: AppColors.accentVintageGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.accentVintageGold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 20,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.christmasBerryRed,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.backgroundCream.withAlpha(65),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.backgroundCream,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REGION SELECTOR
  // ─────────────────────────────────────────────────────────────

  Widget _buildRegionSelector() {
    const regions = ['Tất cả', 'TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khám phá quanh bạn',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: regions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final region = regions[index];
              final selected = _selectedRegion == region;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedRegion = region;
                  });
                },
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryTerracotta
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryTerracotta
                          : AppColors.borderWarm,
                    ),
                  ),
                  child: Text(
                    region,
                    style: TextStyle(
                      color: selected
                          ? AppColors.backgroundCream
                          : AppColors.textCharcoal,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

  // ─────────────────────────────────────────────────────────────
  // COLLECTIONS
  // ─────────────────────────────────────────────────────────────

  Widget _buildCollectionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          eyebrow: 'HANDPICKED',
          title: 'Bộ sưu tập tuyển chọn',
          description: 'Những chủ đề dành cho người có gu.',
        ),
        const SizedBox(height: 16),
        _buildFeaturedCollection(context, _curatedCollections[0]),
        const SizedBox(height: 12),
        _buildCollectionPair(
          context,
          _curatedCollections[1],
          _curatedCollections[2],
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

  Widget _buildSectionHeading({
    required String eyebrow,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 1.6,
            color: AppColors.primaryTerracotta,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 21,
            color: AppColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => context.push(AppRoutes.search),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 172,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.backgroundCream.withAlpha(30)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  right: reverse ? null : -12,
                  left: reverse ? -12 : null,
                  top: -18,
                  child: Icon(
                    icon,
                    size: 170,
                    color: AppColors.backgroundCream.withAlpha(18),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppColors.backgroundCream.withAlpha(140),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      if (reverse) ...[
                        _collectionIllustration(icon),
                        const SizedBox(width: 15),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _collectionTag(col['tag'] as String),
                            const SizedBox(height: 9),
                            Text(
                              col['title'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontHeading,
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                                height: 1.15,
                                color: AppColors.backgroundCream,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              col['subtitle'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: AppColors.backgroundCream.withAlpha(205),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text(
                                  'KHÁM PHÁ',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentVintageGold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.accentVintageGold,
                                  size: 15,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!reverse) ...[
                        const SizedBox(width: 10),
                        _collectionIllustration(icon),
                      ],
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

  Widget _collectionIllustration(IconData icon) {
    return Container(
      width: 76,
      height: 94,
      decoration: BoxDecoration(
        color: AppColors.backgroundCream.withAlpha(22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.backgroundCream.withAlpha(65)),
      ),
      child: Icon(icon, size: 39, color: AppColors.backgroundCream),
    );
  }

  Widget _collectionTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream.withAlpha(24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.backgroundCream.withAlpha(60)),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: AppColors.accentVintageGold,
          fontWeight: FontWeight.w800,
          fontSize: 8,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCollectionPair(
    BuildContext context,
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildMiniCollection(context, first)),
        const SizedBox(width: 12),
        Expanded(child: _buildMiniCollection(context, second)),
      ],
    );
  }

  Widget _buildMiniCollection(BuildContext context, Map<String, dynamic> col) {
    final color = col['color'] as Color;
    final icon = col['icon'] as IconData;

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push(AppRoutes.search),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderWarm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 92,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Icon(
                        Icons.auto_awesome,
                        color: color.withAlpha(110),
                        size: 13,
                      ),
                    ),
                    Icon(icon, color: color, size: 42),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Text(
                col['tag'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
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
                    'XEM THÊM',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
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

  // ─────────────────────────────────────────────────────────────
  // SELLERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildSellerSection(BuildContext context, List<dynamic> sellers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          eyebrow: 'COMMUNITY PICKS',
          title: 'Những tiệm đáng ghé',
          description: 'Gặp những người đứng sau các món đồ.',
        ),
        const SizedBox(height: 16),
        if (sellers.isEmpty)
          _buildSellerEmptyState()
        else
          ...sellers.map((seller) => _buildSellerCard(context, seller)),
      ],
    );
  }

  Widget _buildSellerEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.secondaryPineGreen.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 30,
              color: AppColors.secondaryPineGreen,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Đang cập nhật danh sách các tiệm đồ si tuyển chọn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(BuildContext context, dynamic seller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Container(height: 6, color: AppColors.secondaryPineGreen),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: AppColors.borderWarm),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primaryTerracotta,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.shopName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontHeading,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.2,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.accentVintageGold,
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${seller.trustScore.toStringAsFixed(0)} điểm uy tín',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${seller.completedOrdersCount} đơn hoàn thành',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryPineGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (seller.bio != null && (seller.bio as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    seller.bio as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryPineGreen,
                    foregroundColor: AppColors.backgroundCream,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () =>
                      context.push(AppRoutes.sellerStorefrontPath(seller.id)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ghé tiệm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 7),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────────────────────

  Widget _buildBottomEditorial() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: AppColors.christmasBerryRed,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đồ si không chỉ là mua sắm. '
              'Đó là tìm thấy một điều gì đó mà không ai khác có.',
              style: TextStyle(
                fontFamily: AppTypography.fontHeading,
                fontSize: 13,
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
