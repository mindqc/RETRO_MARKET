import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../models/product_filter_query.dart';
import '../models/product_summary_model.dart';
import '../models/taxonomy_model.dart';
import '../repositories/home_catalog_repository.dart';

/// ViewModel managing Catalog Taxonomy, Multi-Filter Search & Pagination (M-DS-01, M-DS-02, M-DS-03)
class CatalogSearchViewModel extends BaseViewModel<List<ProductSummaryModel>> {
  final HomeCatalogRepository repository;
  final Ref ref;

  TaxonomyModel? _taxonomy;
  ProductFilterQuery _currentQuery = const ProductFilterQuery();
  PaginationMeta? _paginationMeta;
  bool _isLoadingMore = false;
  String? _filterValidationError;

  static const String recentKeywordsKey = 'recent_search_keywords';
  static const int maxRecentKeywords = 10;
  List<String> _recentKeywords = [];

  CatalogSearchViewModel({
    required this.repository,
    required this.ref,
  });

  TaxonomyModel? get taxonomy => _taxonomy;
  ProductFilterQuery get currentQuery => _currentQuery;
  List<ProductSummaryModel> get products => state.data ?? [];
  PaginationMeta? get paginationMeta => _paginationMeta;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePages =>
      _paginationMeta != null && _paginationMeta!.currentPage < _paginationMeta!.lastPage;
  String? get filterValidationError => _filterValidationError;
  List<String> get recentKeywords => List.unmodifiable(_recentKeywords);

  /// Loads recent search history from SharedPreferences
  Future<void> loadRecentKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentKeywords = prefs.getStringList(recentKeywordsKey) ?? [];
      notifyListeners();
    } catch (_) {}
  }

  /// Adds a keyword to recent searches (max 10 items, deduplicated)
  Future<void> addRecentKeyword(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    _recentKeywords.removeWhere((k) => k.toLowerCase() == trimmed.toLowerCase());
    _recentKeywords.insert(0, trimmed);
    if (_recentKeywords.length > maxRecentKeywords) {
      _recentKeywords = _recentKeywords.sublist(0, maxRecentKeywords);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(recentKeywordsKey, _recentKeywords);
    } catch (_) {}
  }

  /// Removes single search keyword from history
  Future<void> removeRecentKeyword(String keyword) async {
    _recentKeywords.remove(keyword);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(recentKeywordsKey, _recentKeywords);
    } catch (_) {}
  }

  /// Clears all search history
  Future<void> clearAllRecentKeywords() async {
    _recentKeywords.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(recentKeywordsKey);
    } catch (_) {}
  }

  /// Loads taxonomy directory (categories & brands)
  Future<void> loadTaxonomy() async {
    try {
      _taxonomy = await repository.fetchTaxonomy();
      notifyListeners();
    } catch (_) {
      // Keep existing taxonomy on error
    }
  }

  /// Searches products with the provided filter query (M-DS-02, M-DS-03)
  /// Enforces client-side validation: minPrice <= maxPrice
  Future<bool> search([ProductFilterQuery? newQuery]) async {
    final queryToRun = (newQuery ?? _currentQuery).copyWith(page: 1);

    if (!queryToRun.isPriceRangeValid) {
      _filterValidationError = 'Giá tối thiểu không được lớn hơn giá tối đa';
      notifyListeners();
      return false;
    }

    _filterValidationError = null;
    _currentQuery = queryToRun;

    await runCatching(
      () async {
        final paginated = await repository.searchProducts(_currentQuery);
        _paginationMeta = paginated.meta;
        return paginated.items;
      },
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'Không tìm thấy sản phẩm phù hợp với bộ lọc.',
    );

    return true;
  }

  /// Loads next page for infinite scrolling
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentQuery.page + 1;
      final nextPageQuery = _currentQuery.copyWith(page: nextPage);
      final paginated = await repository.searchProducts(nextPageQuery);

      _currentQuery = nextPageQuery;
      _paginationMeta = paginated.meta;

      final currentList = List<ProductSummaryModel>.from(products);
      currentList.addAll(paginated.items);
      setSuccess(currentList);
    } catch (e) {
      // Keep existing list on pagination failure
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Update search keyword and search immediately
  Future<bool> setKeyword(String? keyword) {
    if (keyword != null && keyword.trim().isNotEmpty) {
      addRecentKeyword(keyword.trim());
    }
    return search(_currentQuery.copyWith(q: keyword));
  }

  /// Set category filter
  Future<bool> setCategory(int? categoryId) {
    return search(_currentQuery.copyWith(categoryId: categoryId));
  }

  /// Set brand filter
  Future<bool> setBrand(int? brandId) {
    return search(_currentQuery.copyWith(brandId: brandId));
  }

  /// Set sort option ('newest', 'price_asc', 'price_desc', 'popular')
  Future<bool> setSort(String sort) {
    return search(_currentQuery.copyWith(sort: sort));
  }

  /// Reset all filters while preserving search keyword
  Future<bool> resetFilters() {
    _filterValidationError = null;
    return search(_currentQuery.resetFilters());
  }

  /// Optimistic toggle favorite for a product in search results
  Future<bool> toggleFavorite(BuildContext context, int productId) async {
    final authVM = ref.read(authViewModelProvider);
    if (!authVM.isAuthenticated) {
      _showGuestLoginPrompt(context);
      return false;
    }

    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) return false;

    final original = products[index];
    final bool nextFavorited = !original.isFavorited;
    final int nextCount = nextFavorited
        ? original.favoriteCount + 1
        : (original.favoriteCount > 0 ? original.favoriteCount - 1 : 0);

    final updated = List<ProductSummaryModel>.from(products);
    updated[index] = original.copyWith(
      isFavorited: nextFavorited,
      favoriteCount: nextCount,
    );
    setSuccess(updated);

    try {
      final result = await repository.toggleFavorite(productId);
      if (result['favorite_count'] != null) {
        final serverCount = (result['favorite_count'] as num).toInt();
        final serverFavorited = result['is_favorited'] as bool? ?? nextFavorited;
        final synced = List<ProductSummaryModel>.from(products);
        final idx = synced.indexWhere((p) => p.id == productId);
        if (idx != -1) {
          synced[idx] = synced[idx].copyWith(
            isFavorited: serverFavorited,
            favoriteCount: serverCount,
          );
          setSuccess(synced);
        }
      }
      return true;
    } catch (err) {
      final reverted = List<ProductSummaryModel>.from(products);
      final idx = reverted.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        reverted[idx] = original;
        setSuccess(reverted);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật yêu thích: $err'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
      return false;
    }
  }

  void _showGuestLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text(
          'Vui lòng đăng nhập vào tài khoản izithrift để lưu sản phẩm vào danh sách yêu thích và theo dõi cập nhật.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Để sau', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTerracotta,
              foregroundColor: AppColors.surfaceCard,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(AppRoutes.login);
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }
}

/// Riverpod provider for CatalogSearchViewModel
final catalogSearchViewModelProvider =
    ChangeNotifierProvider<CatalogSearchViewModel>((ref) {
  final repository = ref.watch(homeCatalogRepositoryProvider);
  return CatalogSearchViewModel(repository: repository, ref: ref);
});
