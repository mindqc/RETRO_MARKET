import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../catalog/models/product_summary_model.dart';
import '../../catalog/repositories/home_catalog_repository.dart';
import '../models/home_feed_model.dart';

/// ViewModel for Home Discovery Feed (M-HM-01, M-HM-02)
class HomeViewModel extends BaseViewModel<HomeFeedModel> {
  final HomeCatalogRepository repository;
  final Ref ref;

  HomeViewModel({
    required this.repository,
    required this.ref,
  });

  /// Builds a coherent demo feed if the backend server is offline during a presentation.
  HomeFeedModel _buildDemoFallbackFeed() {
    final demoStore = ref.read(retroDemoStoreProvider);
    return HomeFeedModel(
      categories: RetroDemoMarketplaceStore.fallbackCategories,
      liveAuctions: demoStore.demoHomeAuctionSummaries,
      featuredSellers: RetroDemoMarketplaceStore.fallbackFeaturedSellers,
      latestProducts: demoStore.demoCatalogProducts,
    );
  }

  /// Fetches aggregated home feed from GET /api/v1/home
  Future<void> loadHomeFeed() async {
    setLoading();
    try {
      final feed = await repository.fetchHomeFeed();
      final isFeedEmpty = feed.categories.isEmpty &&
          feed.liveAuctions.isEmpty &&
          feed.featuredSellers.isEmpty &&
          feed.latestProducts.isEmpty;
      if (isFeedEmpty) {
        setSuccess(_buildDemoFallbackFeed());
      } else {
        setSuccess(feed);
      }
    } catch (_) {
      // Graceful demo-compatible fallback when backend API is unreachable
      setSuccess(_buildDemoFallbackFeed());
    }
  }

  /// Pull-to-refresh without clearing the screen
  Future<void> refresh() async {
    try {
      final feed = await repository.fetchHomeFeed();
      final isFeedEmpty = feed.categories.isEmpty &&
          feed.liveAuctions.isEmpty &&
          feed.featuredSellers.isEmpty &&
          feed.latestProducts.isEmpty;
      setSuccess(isFeedEmpty ? _buildDemoFallbackFeed() : feed);
    } catch (e) {
      if (state.data != null) {
        setSuccess(state.data!);
      } else {
        setSuccess(_buildDemoFallbackFeed());
      }
    }
  }

  /// Optimistic toggle favorite for a product on the home feed (DEC-01)
  /// If user is Guest, prompts a modal/dialog to redirect to Login.
  Future<bool> toggleFavorite(BuildContext context, int productId) async {
    final authVM = ref.read(authViewModelProvider);
    if (!authVM.isAuthenticated) {
      _showGuestLoginPrompt(context);
      return false;
    }

    // Handle demo catalog products cleanly via RetroDemoMarketplaceStore
    final demoStore = ref.read(retroDemoStoreProvider);
    final isDemoItem = demoStore.demoCatalogProducts.any((p) => p.id == productId);
    if (isDemoItem) {
      demoStore.toggleLocalFavorite(productId);
      final currentFeed = state.data;
      if (currentFeed != null) {
        final idx = currentFeed.latestProducts.indexWhere((p) => p.id == productId);
        if (idx != -1) {
          final updated = List<ProductSummaryModel>.from(currentFeed.latestProducts);
          final orig = updated[idx];
          updated[idx] = orig.copyWith(isFavorited: demoStore.isProductFavorited(productId));
          setSuccess(currentFeed.copyWith(latestProducts: updated));
        }
      }
      return true;
    }

    final currentFeed = state.data;
    if (currentFeed == null) return false;

    final index = currentFeed.latestProducts.indexWhere((p) => p.id == productId);
    if (index == -1) return false;

    final original = currentFeed.latestProducts[index];
    final bool nextFavorited = !original.isFavorited;
    final int nextCount = nextFavorited
        ? original.favoriteCount + 1
        : (original.favoriteCount > 0 ? original.favoriteCount - 1 : 0);

    // Optimistically update
    final updatedList = List<ProductSummaryModel>.from(currentFeed.latestProducts);
    updatedList[index] = original.copyWith(
      isFavorited: nextFavorited,
      favoriteCount: nextCount,
    );

    final optimisticFeed = currentFeed.copyWith(
      latestProducts: updatedList,
    );
    setSuccess(optimisticFeed);

    try {
      final result = await repository.toggleFavorite(productId);
      if (result['favorite_count'] != null) {
        final serverCount = (result['favorite_count'] as num).toInt();
        final serverFavorited = result['is_favorited'] as bool? ?? nextFavorited;
        final syncedList = List<ProductSummaryModel>.from(
          state.data?.latestProducts ?? const [],
        );
        final idx = syncedList.indexWhere((p) => p.id == productId);
        if (idx != -1) {
          syncedList[idx] = syncedList[idx].copyWith(
            isFavorited: serverFavorited,
            favoriteCount: serverCount,
          );
          setSuccess(state.data!.copyWith(latestProducts: syncedList));
        }
      }
      return true;
    } catch (err) {
      final revertedList = List<ProductSummaryModel>.from(
        state.data?.latestProducts ?? const [],
      );
      final idx = revertedList.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        revertedList[idx] = original;
        setSuccess(state.data!.copyWith(latestProducts: revertedList));
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

/// Riverpod provider for HomeViewModel
final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  final repository = ref.watch(homeCatalogRepositoryProvider);
  return HomeViewModel(repository: repository, ref: ref);
});
