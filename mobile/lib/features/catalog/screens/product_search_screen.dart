import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../viewmodels/catalog_search_view_model.dart';
import '../widgets/product_filter_bottom_sheet.dart';

/// M-DS-02: Product Search & Filter Results Screen
class ProductSearchScreen extends ConsumerStatefulWidget {
  final String? initialKeyword;

  const ProductSearchScreen({super.key, this.initialKeyword});

  @override
  ConsumerState<ProductSearchScreen> createState() =>
      _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.initialKeyword ?? '',
    );
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchVM = ref.read(catalogSearchViewModelProvider);
      searchVM.loadRecentKeywords();
      searchVM.loadTaxonomy();
      if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
        searchVM.setKeyword(widget.initialKeyword);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(catalogSearchViewModelProvider).loadNextPage();
    }
  }

  void _openFilterBottomSheet(CatalogSearchViewModel searchVM) {
    ProductFilterBottomSheet.show(
      context,
      initialQuery: searchVM.currentQuery,
      taxonomy: searchVM.taxonomy,
      onApply: (newQuery) {
        searchVM.search(newQuery);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchVM = ref.watch(catalogSearchViewModelProvider);
    final currentQuery = searchVM.currentQuery;
    final products = searchVM.products;
    final state = searchVM.state;

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusFull,
              boxShadow: DesignTokens.cardElevation,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => searchVM.setKeyword(value),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trên izithrift...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textCharcoal,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          searchVM.setKeyword(null);
                        },
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          size: 19,
                          color: AppColors.textCharcoal,
                        ),
                        onPressed: () => _openFilterBottomSheet(searchVM),
                      ),
                filled: true,
                fillColor: AppColors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: DesignTokens.borderRadiusFull,
                  borderSide: const BorderSide(color: AppColors.borderWarm),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: DesignTokens.borderRadiusFull,
                  borderSide: const BorderSide(color: AppColors.borderWarm),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: DesignTokens.borderRadiusFull,
                  borderSide: const BorderSide(
                    color: AppColors.pineBanner,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Pill Filter & Quick Chips Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _openFilterBottomSheet(searchVM),
                  borderRadius: DesignTokens.borderRadiusFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentQuery.hasActiveFilters
                          ? AppColors.pineDeep
                          : AppColors.surfaceCard,
                      borderRadius: DesignTokens.borderRadiusFull,
                      border: Border.all(
                        color: currentQuery.hasActiveFilters
                            ? AppColors.pineDeep
                            : AppColors.borderWarm,
                      ),
                      boxShadow: DesignTokens.cardElevation,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 15,
                          color: currentQuery.hasActiveFilters
                              ? AppColors.creamBadgeBg
                              : AppColors.textCharcoal,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          currentQuery.hasActiveFilters
                              ? 'Bộ lọc (${currentQuery.activeFilterCount})'
                              : 'Bộ lọc',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: currentQuery.hasActiveFilters
                                ? Colors.white
                                : AppColors.textCharcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickFilterChip(
                          label: 'Mua ngay',
                          isActive: currentQuery.listingType == 'FIXED_PRICE',
                          onTap: () {
                            final next =
                                currentQuery.listingType == 'FIXED_PRICE'
                                    ? null
                                    : 'FIXED_PRICE';
                            searchVM.search(
                              currentQuery.copyWith(
                                listingType: next,
                                clearListingType: next == null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip(
                          label: 'Đấu giá',
                          isActive: currentQuery.listingType == 'AUCTION',
                          onTap: () {
                            final next = currentQuery.listingType == 'AUCTION'
                                ? null
                                : 'AUCTION';
                            searchVM.search(
                              currentQuery.copyWith(
                                listingType: next,
                                clearListingType: next == null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip(
                          label: 'Độ mới 95%+',
                          isActive: currentQuery.condition == 'LIKE_NEW',
                          onTap: () {
                            final next = currentQuery.condition == 'LIKE_NEW'
                                ? null
                                : 'LIKE_NEW';
                            searchVM.search(
                              currentQuery.copyWith(
                                condition: next,
                                clearCondition: next == null,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (searchVM.recentKeywords.isNotEmpty &&
              (_searchController.text.trim().isEmpty || products.isEmpty))
            _buildRecentSearchesSection(searchVM),

          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && products.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.ctaTerracotta,
                    ),
                  );
                }
                if (state.isError && products.isEmpty) {
                  return RetroErrorRetryView(
                    errorMessage:
                        state.errorMessage ?? 'Đã xảy ra sự cố tìm kiếm.',
                    onRetry: () => searchVM.search(),
                  );
                }
                if (state.isEmpty || products.isEmpty) {
                  return RetroEmptyStateView(
                    title: 'Không tìm thấy sản phẩm',
                    message: state.errorMessage ??
                        'Hãy thử tìm kiếm với từ khóa khác hoặc điều chỉnh bộ lọc.',
                    icon: Icons.search_off_rounded,
                    actionLabel: currentQuery.hasActiveFilters
                        ? 'Xóa bộ lọc'
                        : null,
                    onAction: currentQuery.hasActiveFilters
                        ? () => searchVM.resetFilters()
                        : null,
                  );
                }
                return _buildProductGrid(context, searchVM, products);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.borderRadiusFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.creamBadgeBg : AppColors.surfaceCard,
          borderRadius: DesignTokens.borderRadiusFull,
          border: Border.all(
            color: isActive ? AppColors.creamBadgeBorder : AppColors.borderWarm,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? AppColors.creamBadgeText : AppColors.textCharcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(
    BuildContext context,
    CatalogSearchViewModel searchVM,
    List<dynamic> productList,
  ) {
    return LayoutBuilder(
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

        return RefreshIndicator(
          onRefresh: () => searchVM.search(),
          color: AppColors.ctaTerracotta,
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: productList.length + (searchVM.isLoadingMore ? 1 : 0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: cardAspectRatio,
              crossAxisSpacing: DesignTokens.spaceMd,
              mainAxisSpacing: DesignTokens.spaceMd,
            ),
            itemBuilder: (context, index) {
              if (index == productList.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      color: AppColors.ctaTerracotta,
                    ),
                  ),
                );
              }

              final product = productList[index];
              return RetroProductCard(
                id: product.id,
                title: product.title,
                price: product.price,
                primaryImageUrl: product.primaryImageUrl,
                condition: product.condition,
                sellerName: product.sellerDisplayName,
                isOwner: product.isOwner,
                isLiked: product.isFavorited,
                onTap: () =>
                    context.push(AppRoutes.productDetailPath(product.id)),
                onLikeToggle: () =>
                    searchVM.toggleFavorite(context, product.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentSearchesSection(CatalogSearchViewModel searchVM) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSection,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 17,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tìm kiếm gần đây',
                    style: AppTypography.labelMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => searchVM.clearAllRecentKeywords(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Xóa tất cả',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.ctaTerracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: searchVM.recentKeywords.map((kw) {
              return InputChip(
                label: Text(
                  kw,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textCharcoal,
                  ),
                ),
                backgroundColor: AppColors.surfaceCard,
                side: const BorderSide(color: AppColors.borderWarm),
                shape: const StadiumBorder(),
                deleteIcon: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                onDeleted: () => searchVM.removeRecentKeyword(kw),
                onPressed: () {
                  _searchController.text = kw;
                  searchVM.setKeyword(kw);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
