import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/home_view_model.dart';

/// M-HM-02: Curated Collections & Featured Stores Screen
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
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tiệm đồ si & Bộ sưu tập',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textCharcoal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Region Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tất cả', 'TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng'].map((region) {
                final isSelected = _selectedRegion == region;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(region),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedRegion = region;
                      });
                    },
                    selectedColor: AppColors.primaryTerracotta.withAlpha(40),
                    checkmarkColor: AppColors.primaryTerracotta,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryTerracotta : AppColors.textCharcoal,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Curated Collections
          const Text(
            'Bộ sưu tập tuyển chọn',
            style: TextStyle(
              fontFamily: AppTypography.fontHeading,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          ..._curatedCollections.map((col) => _buildCollectionCard(context, col)),
          const SizedBox(height: 24),

          // 3. Featured Stores Section
          const Text(
            'Tiệm đồ si uy tín được yêu thích',
            style: TextStyle(
              fontFamily: AppTypography.fontHeading,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          if (sellers.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: const Center(
                child: Text(
                  'Đang cập nhật danh sách các tiệm đồ si tuyển chọn.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...sellers.map((seller) => _buildSellerCard(context, seller)),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(BuildContext context, Map<String, dynamic> col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (col['color'] as Color).withAlpha(35),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Icon(
              col['icon'] as IconData,
              color: col['color'] as Color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  col['tag'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: col['color'] as Color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  col['title'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  col['subtitle'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(BuildContext context, dynamic seller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceWarm,
            child: const Icon(
              Icons.storefront,
              color: AppColors.primaryTerracotta,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accentVintageGold, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${seller.trustScore.toStringAsFixed(0)} điểm uy tín',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                    Text(
                      '${seller.completedOrdersCount} đơn',
                      style: const TextStyle(fontSize: 12, color: AppColors.secondaryPineGreen),
                    ),
                  ],
                ),
                if (seller.bio != null && (seller.bio as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    seller.bio as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceWarm,
              foregroundColor: AppColors.primaryTerracotta,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                side: const BorderSide(color: AppColors.borderWarm),
              ),
            ),
            onPressed: () => context.push(AppRoutes.sellerStorefrontPath(seller.id)),
            child: const Text('Ghé tiệm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
