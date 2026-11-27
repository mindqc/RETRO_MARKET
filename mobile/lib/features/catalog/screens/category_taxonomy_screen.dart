import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fashion_category_icon.dart';
import '../../../core/widgets/izithrift_global_app_bar.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../models/taxonomy_model.dart';
import '../viewmodels/catalog_search_view_model.dart';

/// M-DS-01: Category & Brand Directory Screen
class CategoryTaxonomyScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const CategoryTaxonomyScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<CategoryTaxonomyScreen> createState() =>
      _CategoryTaxonomyScreenState();
}

class _CategoryTaxonomyScreenState extends ConsumerState<CategoryTaxonomyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _palette = [
    AppColors.pineDeep,
    AppColors.ctaTerracotta,
    AppColors.vintageBrown,
    AppColors.priceCrimson,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogSearchViewModelProvider).loadTaxonomy();
    });
  }

  @override
  void didUpdateWidget(covariant CategoryTaxonomyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      final target = widget.initialTabIndex.clamp(0, 1);
      if (_tabController.index != target) {
        _tabController.animateTo(target);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _categoryColor(int index) => _palette[index % _palette.length];

  @override
  Widget build(BuildContext context) {
    final searchVM = ref.watch(catalogSearchViewModelProvider);
    final taxonomy = searchVM.taxonomy;

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: IzithriftGlobalAppBar.subPage(
        showBrandMark: true,
        activeDestination: IzithriftUpperNavDestination.discover,
        showNotificationsAction: true,
        showCartAction: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(114),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: RetroSearchPill(
                  placeholder: 'Tìm món đồ vintage bạn đang săn...',
                  onTap: () => context.push(AppRoutes.search),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: DesignTokens.borderRadiusFull,
                      boxShadow: DesignTokens.cardElevation,
                    ),
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.pineDeep,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(height: 36, text: 'Danh mục sản phẩm'),
                      Tab(height: 36, text: 'Thương hiệu phổ biến'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const ColoredBox(
                color: AppColors.borderWarm,
                child: SizedBox(height: 1, width: double.infinity),
              ),
            ],
          ),
        ),
      ),
      body: RetroAmbientSnowflakes(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCategoriesTab(
              context,
              (taxonomy ?? const TaxonomyModel()).categories,
            ),
            _buildBrandsTab(
              context,
              (taxonomy ?? const TaxonomyModel()).brands,
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const RetroSectionHeader(
          title: 'Tìm theo gu của bạn',
          subtitle: 'Khám phá từng góc nhỏ của thế giới đồ si tuyển chọn',
          icon: Icons.auto_awesome_rounded,
          iconColor: AppColors.starGold,
        ),
        const SizedBox(height: 16),
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final hasChildren = cat.hasChildren as bool;
          final color = _categoryColor(index);
          final glyph = FashionCategoryGlyph.fromCategoryName(
            cat.name as String,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryCard(
              context,
              category: cat,
              color: color,
              glyph: glyph,
              hasChildren: hasChildren,
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildSeasonalFooter(),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required dynamic category,
    required Color color,
    required FashionCategoryGlyph glyph,
    required bool hasChildren,
  }) {
    final name = category.name as String;
    final count = category.approvedProductsCount;
    final children = category.children as List;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Material(
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: const BorderSide(color: AppColors.borderWarm),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasChildren
            ? Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                leading: _buildRadialCategoryIcon(glyph, color),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textCharcoal,
                  ),
                ),
                subtitle: Text(
                  '$count sản phẩm',
                  style: AppTypography.caption.copyWith(fontSize: 12),
                ),
                trailing: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.creamBadgeSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.creamBadgeBorder),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.creamBadgeText,
                    size: 19,
                  ),
                ),
                children: [
                  _buildSeeAllRow(context, category, color),
                  const SizedBox(height: 10),
                  if (children.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: children
                          .map((child) =>
                              _buildSubcategoryPill(context, child, color))
                          .toList(),
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
                    _buildRadialCategoryIcon(glyph, color),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$count sản phẩm',
                            style: AppTypography.caption.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildRadialCategoryIcon(FashionCategoryGlyph glyph, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            AppColors.categoryCircleStart,
            AppColors.categoryCircleEnd,
          ],
        ),
        border: Border.all(color: AppColors.creamBadgeBorder, width: 1.1),
      ),
      alignment: Alignment.center,
      child: FashionCategoryIcon(glyph: glyph, size: 24, color: color),
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
      borderRadius: DesignTokens.borderRadiusFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.creamBadgeSoft,
          borderRadius: DesignTokens.borderRadiusFull,
          border: Border.all(color: AppColors.creamBadgeBorder),
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
            Icon(Icons.arrow_forward_rounded, color: color, size: 17),
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
      borderRadius: DesignTokens.borderRadiusFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceSection,
          borderRadius: DesignTokens.borderRadiusFull,
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
                fontSize: 11,
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
    return const RetroPineSpotlightContainer(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.ac_unit_rounded,
            color: AppColors.creamBadgeBg,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Một món đồ cũ. Một câu chuyện mới. '
              'Chúc bạn tìm được kho báu vintage của riêng mình.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.starGold,
            size: 18,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
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
        return _buildBrandCard(context, brand, color);
      },
    );
  }

  Widget _buildBrandCard(
    BuildContext context,
    dynamic brand,
    Color color,
  ) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: InkWell(
        onTap: () {
          ref.read(catalogSearchViewModelProvider).setBrand(brand.id as int);
          context.push(AppRoutes.search);
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Ink(
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
                width: 38,
                height: 38,
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
                child: Icon(Icons.sell_outlined, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                brand.name as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headingSmall.copyWith(
                  fontSize: 15.5,
                  height: 1.15,
                ),
              ),
              if (brand.originCountry != null) ...[
                const SizedBox(height: 3),
                Text(
                  brand.originCountry as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ],
              const SizedBox(height: 6),
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
        ),
      ),
    );
  }
}
