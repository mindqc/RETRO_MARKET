import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../models/product_detail_model.dart';
import '../repositories/home_catalog_repository.dart';

/// ViewModel for Product Detail screen (M-PD-01) and Defect Verification (M-PD-02)
class ProductDetailViewModel extends BaseViewModel<ProductDetailModel> {
  final HomeCatalogRepository repository;
  final Ref ref;

  int _currentImageIndex = 0;
  int _selectedQuantity = 1;
  bool _isAddingToCart = false;

  ProductDetailViewModel({
    required this.repository,
    required this.ref,
  });

  int get currentImageIndex => _currentImageIndex;
  int get selectedQuantity => _selectedQuantity;
  bool get isAddingToCart => _isAddingToCart;

  void setImageIndex(int index) {
    if (_currentImageIndex != index) {
      _currentImageIndex = index;
      notifyListeners();
    }
  }

  void setQuantity(int qty) {
    if (qty > 0) {
      final maxAvailable = state.data?.availableQuantity ?? 1;
      _selectedQuantity = qty <= maxAvailable ? qty : maxAvailable;
      notifyListeners();
    }
  }

  /// Loads product detail from GET /api/v1/products/{id}, with demo-compatible fallback
  Future<void> loadProductDetail(int productId) async {
    _currentImageIndex = 0;
    _selectedQuantity = 1;
    final demoFallback =
        ref.read(retroDemoStoreProvider).getDemoProductDetail(productId);
    if (demoFallback != null) {
      setSuccess(demoFallback);
      return;
    }
    await runCatching(
      () async {
        try {
          return await repository.fetchProductDetail(productId);
        } catch (_) {
          final fallback =
              ref.read(retroDemoStoreProvider).getDemoProductDetail(productId);
          if (fallback != null) return fallback;
          rethrow;
        }
      },
      emptyMessage: 'Không tìm thấy sản phẩm hoặc sản phẩm đã bị ẩn.',
    );
  }

  /// Optimistic favorite toggle with guest login guard (DEC-01)
  Future<bool> toggleFavorite(BuildContext context) async {
    final authVM = ref.read(authViewModelProvider);
    if (!authVM.isAuthenticated) {
      showGuestLoginPrompt(context);
      return false;
    }

    final currentProduct = state.data;
    if (currentProduct == null) return false;

    final bool newFavoriteStatus = !currentProduct.isFavorited;
    final int newCount = newFavoriteStatus
        ? currentProduct.favoriteCount + 1
        : (currentProduct.favoriteCount > 0 ? currentProduct.favoriteCount - 1 : 0);

    // Optimistic UI update
    setSuccess(currentProduct.copyWith(
      isFavorited: newFavoriteStatus,
      favoriteCount: newCount,
    ));

    try {
      final res = await repository.toggleFavorite(currentProduct.id);
      final bool serverFav = res['is_favorited'] as bool? ?? newFavoriteStatus;
      final int serverCount = res['favorite_count'] as int? ?? newCount;
      if (state.data != null) {
        setSuccess(state.data!.copyWith(
          isFavorited: serverFav,
          favoriteCount: serverCount,
        ));
      }
      return serverFav;
    } catch (e) {
      // Revert optimistic update
      setSuccess(currentProduct);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật yêu thích: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
      return currentProduct.isFavorited;
    }
  }

  /// Adds product to user's cart (OF-01 / BR-AC-02 self-purchase forbidden)
  Future<bool> addToCart(BuildContext context, {int? quantity}) async {
    final currentProduct = state.data;
    if (currentProduct == null) return false;

    // BR-AC-02: Self-transaction forbidden
    if (currentProduct.isOwner) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không thể mua hoặc thêm vào giỏ hàng sản phẩm của chính mình (BR-AC-02).'),
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

    final int qtyToAdd = quantity ?? _selectedQuantity;
    if (qtyToAdd > currentProduct.availableQuantity) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số lượng yêu cầu ($qtyToAdd) vượt quá số lượng còn lại (${currentProduct.availableQuantity}).'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
      return false;
    }

    _isAddingToCart = true;
    notifyListeners();

    try {
      await repository.addToCart(productId: currentProduct.id, quantity: qtyToAdd);
      _isAddingToCart = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm $qtyToAdd sản phẩm vào giỏ hàng!'),
            backgroundColor: AppColors.secondaryPineGreen,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Xem giỏ',
              textColor: AppColors.surfaceCard,
              onPressed: () => context.push(AppRoutes.cart),
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      _isAddingToCart = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thêm vào giỏ hàng thất bại: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
      return false;
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
          'Vui lòng đăng nhập hoặc tạo tài khoản izithrift để lưu đồ yêu thích, mua sắm và kết nối với chủ tiệm.',
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

/// Riverpod provider for ProductDetailViewModel
final productDetailViewModelProvider = ChangeNotifierProvider.autoDispose<ProductDetailViewModel>((ref) {
  final repo = ref.watch(homeCatalogRepositoryProvider);
  return ProductDetailViewModel(repository: repo, ref: ref);
});
