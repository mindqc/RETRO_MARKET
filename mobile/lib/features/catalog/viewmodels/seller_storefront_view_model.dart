import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../models/review_item_model.dart';
import '../models/seller_public_profile_model.dart';
import '../repositories/seller_storefront_repository.dart';

/// ViewModel for Public Seller Storefront screen (M-US-03)
class SellerStorefrontViewModel extends BaseViewModel<SellerPublicProfileModel> {
  final SellerStorefrontRepository repository;
  final Ref ref;

  int _selectedTabIndex = 0;
  List<ReviewItemModel> _reviews = [];
  bool _isLoadingReviews = false;

  SellerStorefrontViewModel({
    required this.repository,
    required this.ref,
  });

  int get selectedTabIndex => _selectedTabIndex;
  List<ReviewItemModel> get reviews => _reviews;
  bool get isLoadingReviews => _isLoadingReviews;

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  /// Loads public seller storefront profile and listings (M-US-03)
  Future<void> loadStorefront(int sellerId) async {
    _selectedTabIndex = 0;
    _reviews = [];
    await runCatching(
      () async {
        try {
          return await repository.fetchSellerStorefront(sellerId);
        } catch (_) {
          final fallback =
              ref.read(retroDemoStoreProvider).getDemoSellerStorefront(sellerId);
          if (fallback != null) return fallback;
          rethrow;
        }
      },
      emptyMessage: 'Không tìm thấy gian hàng này hoặc người bán đã tạm ngưng hoạt động.',
    );
  }

  /// Loads verified buyer reviews for seller storefront
  Future<void> loadReviews(int sellerId, {int? rating}) async {
    _isLoadingReviews = true;
    notifyListeners();

    try {
      final res = await repository.fetchSellerReviews(sellerId, rating: rating);
      _reviews = res.items;
      _isLoadingReviews = false;
      notifyListeners();
    } catch (e) {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  /// Toggles follow status with optimistic UI update and guest guard (DEC-01 / BR-AC-02)
  Future<bool> toggleFollow(BuildContext context) async {
    final currentSeller = state.data;
    if (currentSeller == null) return false;

    // BR-AC-02: Prevent self-follow
    if (currentSeller.isOwner) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không thể theo dõi chính gian hàng của mình (BR-AC-02).'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
      return false;
    }

    final authVM = ref.read(authViewModelProvider);
    if (!authVM.isAuthenticated) {
      showGuestLoginPrompt(context);
      return false;
    }

    final bool newFollowing = !currentSeller.isFollowing;
    final int newCount = newFollowing
        ? currentSeller.followersCount + 1
        : (currentSeller.followersCount > 0 ? currentSeller.followersCount - 1 : 0);

    // Optimistic UI update
    setSuccess(currentSeller.copyWith(
      isFollowing: newFollowing,
      followersCount: newCount,
    ));

    try {
      final res = await repository.toggleFollowSeller(currentSeller.userId);
      final bool serverFollowing = res['is_following'] as bool? ?? newFollowing;
      final int serverCount = res['followers_count'] as int? ?? newCount;

      if (state.data != null) {
        setSuccess(state.data!.copyWith(
          isFollowing: serverFollowing,
          followersCount: serverCount,
        ));
      }
      return serverFollowing;
    } catch (e) {
      final demoStore = ref.read(retroDemoStoreProvider);
      if (demoStore.getDemoSellerStorefront(currentSeller.userId) != null) {
        demoStore.toggleLocalFollowSeller(currentSeller.userId);
        return newFollowing;
      }

      // Revert optimistic update
      setSuccess(currentSeller);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật theo dõi tiệm: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
      return currentSeller.isFollowing;
    }
  }

  /// Guest authentication dialog per DEC-01
  void showGuestLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        backgroundColor: AppColors.surfaceCard,
        title: Row(
          children: const [
            Icon(Icons.lock_outline, color: AppColors.primaryTerracotta),
            SizedBox(width: DesignTokens.spaceSm),
            Text(
              'Yêu cầu đăng nhập',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Vui lòng đăng nhập để theo dõi tiệm đồ si yêu thích và nhận thông báo khi có hàng mới lên kệ.',
          style: TextStyle(color: AppColors.textCharcoal),
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
            child: const Text('Đăng nhập ngay'),
          ),
        ],
      ),
    );
  }
}

/// Riverpod provider for SellerStorefrontViewModel
final sellerStorefrontViewModelProvider = ChangeNotifierProvider.autoDispose<SellerStorefrontViewModel>((ref) {
  final repo = ref.watch(sellerStorefrontRepositoryProvider);
  return SellerStorefrontViewModel(repository: repo, ref: ref);
});
