import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/viewmodels/auth_view_model.dart';
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

  /// Fetches aggregated home feed from GET /api/v1/home
  Future<void> loadHomeFeed() async {
    await runCatching(
      () => repository.fetchHomeFeed(),
      isEmpty: (feed) =>
          feed.categories.isEmpty &&
          feed.liveAuctions.isEmpty &&
          feed.featuredSellers.isEmpty &&
          feed.latestProducts.isEmpty,
      emptyMessage: 'Chưa có sản phẩm nào trên Retro Market.',
    );
  }

  /// Pull-to-refresh without clearing the screen
  Future<void> refresh() async {
    try {
      final feed = await repository.fetchHomeFeed();
      setSuccess(feed);
    } catch (e) {
      // If error occurs during pull to refresh, keep current data and notify
      if (state.data != null) {
        setError('Không thể làm mới: $e', null, state.data);
      } else {
        await loadHomeFeed();
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
    final updatedList = List<dynamic>.from(currentFeed.latestProducts);
    updatedList[index] = original.copyWith(
      isFavorited: nextFavorited,
      favoriteCount: nextCount,
    );

    final optimisticFeed = currentFeed.copyWith(
      latestProducts: updatedList.cast(),
    );
    setSuccess(optimisticFeed);

    try {
      final result = await repository.toggleFavorite(productId);
      // Synchronize exact count from backend if returned
      if (result['favorite_count'] != null) {
        final serverCount = (result['favorite_count'] as num).toInt();
        final serverFavorited = result['is_favorited'] as bool? ?? nextFavorited;
        final syncedList = List<dynamic>.from(state.data?.latestProducts ?? []);
        final idx = syncedList.indexWhere((p) => p.id == productId);
        if (idx != -1) {
          syncedList[idx] = (syncedList[idx]).copyWith(
            isFavorited: serverFavorited,
            favoriteCount: serverCount,
          );
          setSuccess(state.data!.copyWith(latestProducts: syncedList.cast()));
        }
      }
      return true;
    } catch (err) {
      // Revert on failure
      final revertedList = List<dynamic>.from(state.data?.latestProducts ?? []);
      final idx = revertedList.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        revertedList[idx] = original;
        setSuccess(state.data!.copyWith(latestProducts: revertedList.cast()));
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
