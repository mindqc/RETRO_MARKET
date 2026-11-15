import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/taxonomy_model.dart';
import '../viewmodels/catalog_search_view_model.dart';

/// M-DS-01: Category & Brand Directory Screen (Tab 2 Root: Khám phá)
class CategoryTaxonomyScreen extends ConsumerStatefulWidget {
  const CategoryTaxonomyScreen({super.key});

  @override
  ConsumerState<CategoryTaxonomyScreen> createState() => _CategoryTaxonomyScreenState();
}

class _CategoryTaxonomyScreenState extends ConsumerState<CategoryTaxonomyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final searchVM = ref.watch(catalogSearchViewModelProvider);
    final taxonomy = searchVM.taxonomy;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'izithrift • Khám phá',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textCharcoal,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search input callout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () => context.push(AppRoutes.search),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          'Tìm kiếm danh mục, thương hiệu...',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryTerracotta,
                labelColor: AppColors.primaryTerracotta,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Danh mục sản phẩm'),
                  Tab(text: 'Thương hiệu retro'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(context, (taxonomy ?? const TaxonomyModel()).categories),
          _buildBrandsTab(context, (taxonomy ?? const TaxonomyModel()).brands),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(BuildContext context, List<dynamic> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('Chưa có danh mục nào.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final hasChildren = cat.hasChildren as bool;

        if (hasChildren) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppColors.surfaceCard,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              side: const BorderSide(color: AppColors.borderWarm),
            ),
            child: ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: const Icon(Icons.category_outlined, color: AppColors.primaryTerracotta),
              ),
              title: Text(
                cat.name as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textCharcoal,
                ),
              ),
              subtitle: Text(
                '${cat.approvedProductsCount} sản phẩm',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              children: [
                ListTile(
                  title: Text('Xem tất cả ${cat.name}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    ref.read(catalogSearchViewModelProvider).setCategory(cat.id as int);
                    context.push(AppRoutes.search);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderWarm),
                ...((cat.children as List).map((child) => ListTile(
                      contentPadding: const EdgeInsets.only(left: 32, right: 16),
                      title: Text(child.name as String),
                      trailing: Text(
                        '${child.approvedProductsCount}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      onTap: () {
                        ref.read(catalogSearchViewModelProvider).setCategory(child.id as int);
                        context.push(AppRoutes.search);
                      },
                    ))),
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            side: const BorderSide(color: AppColors.borderWarm),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: const Icon(Icons.folder_outlined, color: AppColors.primaryTerracotta),
            ),
            title: Text(
              cat.name as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              '${cat.approvedProductsCount} sản phẩm',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
            onTap: () {
              ref.read(catalogSearchViewModelProvider).setCategory(cat.id as int);
              context.push(AppRoutes.search);
            },
          ),
        );
      },
    );
  }

  Widget _buildBrandsTab(BuildContext context, List<dynamic> brands) {
    if (brands.isEmpty) {
      return const Center(
        child: Text('Chưa có thương hiệu nào.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: brands.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final brand = brands[index];
        return InkWell(
          onTap: () {
            ref.read(catalogSearchViewModelProvider).setBrand(brand.id as int);
            context.push(AppRoutes.search);
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Container(
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
                Text(
                  brand.name as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                if (brand.originCountry != null)
                  Text(
                    brand.originCountry as String,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                const Spacer(),
                Text(
                  '${brand.approvedProductsCount} sản phẩm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryPineGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
