import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/taxonomy_model.dart';
import '../viewmodels/catalog_search_view_model.dart';

/// M-DS-01: Category & Brand Directory Screen
/// Visual direction: Vintage Editorial × Modern Discovery.
class CategoryTaxonomyScreen extends ConsumerStatefulWidget {
  const CategoryTaxonomyScreen({super.key});

  @override
  ConsumerState<CategoryTaxonomyScreen> createState() =>
      _CategoryTaxonomyScreenState();
}

class _CategoryTaxonomyScreenState extends ConsumerState<CategoryTaxonomyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _palette = [
    AppColors.primaryTerracotta,
    AppColors.secondaryPineGreen,
    AppColors.accentVintageGold,
    AppColors.christmasBerryRed,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogSearchViewModelProvider).loadTaxonomy();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _categoryColor(int index) => _palette[index % _palette.length];

  IconData _categoryIcon(String name, {bool hasChildren = false}) {
    final value = name.toLowerCase();

    if (value.contains('áo') ||
        value.contains('quần') ||
        value.contains('váy') ||
        value.contains('đồ')) {
      if (value.contains('áo khoác') ||
          value.contains('coat') ||
          value.contains('dạ')) {
        return Icons.checkroom_rounded;
      }
      return Icons.dry_cleaning_rounded;
    }

    if (value.contains('giày') || value.contains('dép')) {
      return Icons.directions_walk_rounded;
    }

    if (value.contains('túi') || value.contains('ví')) {
      return Icons.shopping_bag_rounded;
    }

    if (value.contains('đồng hồ')) return Icons.watch_rounded;
    if (value.contains('trang sức')) return Icons.diamond_rounded;
    if (value.contains('kính')) return Icons.visibility_rounded;
    if (value.contains('đồ gia dụng')) return Icons.chair_rounded;
    if (value.contains('sưu tầm') || value.contains('cổ')) {
      return Icons.auto_awesome_rounded;
    }
    if (value.contains('phụ kiện')) return Icons.style_rounded;

    return hasChildren ? Icons.grid_view_rounded : Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final searchVM = ref.watch(catalogSearchViewModelProvider);
    final taxonomy = searchVM.taxonomy;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'izithrift • Khám phá',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 19,
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
                color: AppColors.secondaryPineGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 19,
                color: AppColors.backgroundCream,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: _buildSearchBanner(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textCharcoal.withAlpha(12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primaryTerracotta,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Danh mục sản phẩm'),
                      Tab(text: 'Thương hiệu retro'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(
            context,
            (taxonomy ?? const TaxonomyModel()).categories,
          ),
          _buildBrandsTab(context, (taxonomy ?? const TaxonomyModel()).brands),
        ],
      ),
    );
  }

  Widget _buildSearchBanner(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push(AppRoutes.search),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderWarm),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryTerracotta.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryTerracotta,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tìm món đồ bạn đang săn...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.textMuted,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab(BuildContext context, List<dynamic> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có danh mục nào.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _buildEditorialHeading(
          eyebrow: 'THE DEPARTMENTS',
          title: 'Tìm theo gu của bạn.',
          description: 'Khám phá từng góc nhỏ của thế giới đồ si.',
        ),
        const SizedBox(height: 22),
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final hasChildren = cat.hasChildren as bool;
          final color = _categoryColor(index);
          final icon = _categoryIcon(
            cat.name as String,
            hasChildren: hasChildren,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryCard(
              context,
              category: cat,
              color: color,
              icon: icon,
              hasChildren: hasChildren,
              index: index,
            ),
          );
        }),
        const SizedBox(height: 10),
        _buildSeasonalFooter(),
      ],
    );
  }

  Widget _buildEditorialHeading({
    required String eyebrow,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 24, height: 2, color: AppColors.primaryTerracotta),
            const SizedBox(width: 8),
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.primaryTerracotta,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 27,
            height: 1.12,
            color: AppColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required dynamic category,
    required Color color,
    required IconData icon,
    required bool hasChildren,
    required int index,
  }) {
    final name = category.name as String;
    final count = category.approvedProductsCount;
    final children = category.children as List;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderWarm),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasChildren
            ? Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: color.withAlpha(15),
                  highlightColor: color.withAlpha(8),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  leading: _buildCategoryIcon(icon, color),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$count sản phẩm',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  trailing: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  children: [
                    _buildSeeAllRow(context, category, color),
                    const SizedBox(height: 8),
                    if (children.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: children.map((child) {
                          return _buildSubcategoryPill(context, child, color);
                        }).toList(),
                      ),
                  ],
                ),
              )
            : InkWell(
                onTap: () {
                  ref
                      .read(catalogSearchViewModelProvider)
                      .setCategory(category.id as int);
                  context.push(AppRoutes.search);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _buildCategoryIcon(icon, color),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count sản phẩm',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: color, size: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon, Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 26, color: color),
          Positioned(
            right: 5,
            top: 5,
            child: Icon(
              Icons.auto_awesome,
              size: 9,
              color: color.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeAllRow(BuildContext context, dynamic category, Color color) {
    return InkWell(
      onTap: () {
        ref
            .read(catalogSearchViewModelProvider)
            .setCategory(category.id as int);
        context.push(AppRoutes.search);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: color.withAlpha(16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Xem tất cả ${category.name}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryPill(
    BuildContext context,
    dynamic child,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        ref.read(catalogSearchViewModelProvider).setCategory(child.id as int);
        context.push(AppRoutes.search);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.borderWarm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              child.name as String,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textCharcoal,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${child.approvedProductsCount}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryPineGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.ac_unit_rounded,
            color: AppColors.accentVintageGold,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Một món đồ cũ. Một câu chuyện mới. '
              'Chúc bạn tìm được kho báu của riêng mình.',
              style: TextStyle(
                color: AppColors.backgroundCream,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.star_rounded,
            color: AppColors.accentVintageGold,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsTab(BuildContext context, List<dynamic> brands) {
    if (brands.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có thương hiệu nào.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: brands.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.18,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final brand = brands[index];
        final color = _categoryColor(index);

        return _buildBrandCard(context, brand, color, index);
      },
    );
  }

  Widget _buildBrandCard(
    BuildContext context,
    dynamic brand,
    Color color,
    int index,
  ) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          ref.read(catalogSearchViewModelProvider).setBrand(brand.id as int);
          context.push(AppRoutes.search);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderWarm),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -10,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 60,
                  color: color.withAlpha(12),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withAlpha(22),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.sell_outlined, color: color, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    brand.name as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.15,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  if (brand.originCountry != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      brand.originCountry as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${brand.approvedProductsCount} sản phẩm',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: color),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
