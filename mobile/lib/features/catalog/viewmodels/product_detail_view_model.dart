import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../auth/widgets/auth_login_bottom_sheet.dart';
import '../models/product_detail_model.dart';
import '../models/product_summary_model.dart';
import '../models/review_item_model.dart';
import '../repositories/home_catalog_repository.dart';
import '../repositories/seller_storefront_repository.dart';

/// ViewModel for Product Detail screen (M-PD-01) and Defect Verification (M-PD-02)
class ProductDetailViewModel extends BaseViewModel<ProductDetailModel> {
  final HomeCatalogRepository repository;
  final SellerStorefrontRepository? sellerStorefrontRepository;
  final Ref ref;

  int _currentImageIndex = 0;
  int _selectedQuantity = 1;
  bool _isAddingToCart = false;
  bool _isLoadingSellerExtras = false;
  List<ReviewItemModel> _sellerReviews = const [];
  int _sellerReviewCount = 0;
  double? _sellerAverageRating;
  List<ProductSummaryModel> _sellerOtherProducts = const [];

  ProductDetailViewModel({
    required this.repository,
    this.sellerStorefrontRepository,
    required this.ref,
  });

  int get currentImageIndex => _currentImageIndex;
  int get selectedQuantity => _selectedQuantity;
  bool get isAddingToCart => _isAddingToCart;
  bool get isLoadingSellerExtras => _isLoadingSellerExtras;
  List<ReviewItemModel> get sellerReviews => _sellerReviews;
  int get sellerReviewCount => _sellerReviewCount;
  double? get sellerAverageRating => _sellerAverageRating;
  List<ProductSummaryModel> get sellerOtherProducts => _sellerOtherProducts;

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

  /// Loads product detail from GET /api/v1/products/{id}, with demo-compatible fallback,
  /// then loads seller reviews and other active listings from the same shop.
  Future<void> loadProductDetail(int productId) async {
    _currentImageIndex = 0;
    _selectedQuantity = 1;
    _sellerReviews = const [];
    _sellerReviewCount = 0;
    _sellerAverageRating = null;
    _sellerOtherProducts = const [];
    _isLoadingSellerExtras = false;

    final demoFallback =
        ref.read(retroDemoStoreProvider).getDemoProductDetail(productId);
    if (demoFallback != null) {
      setSuccess(demoFallback);
      await _loadSellerReviewsAndOtherProducts(demoFallback);
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

    final loaded = state.data;
    if (loaded != null) {
      await _loadSellerReviewsAndOtherProducts(loaded);
    }
  }

  Future<void> _loadSellerReviewsAndOtherProducts(
    ProductDetailModel product,
  ) async {
    final seller = product.seller;
    if (seller == null || seller.id <= 0) return;

    if (isDisposed) return;
    _isLoadingSellerExtras = true;
    notifyListeners();

    List<ReviewItemModel> reviews = const [];
    int reviewCount = 0;
    double? avgRating = seller.averageRating > 0 ? seller.averageRating : null;
    List<ProductSummaryModel> otherProducts = const [];

    final storefrontRepo = sellerStorefrontRepository;
    if (storefrontRepo != null) {
      // 1. Fetch seller reviews via GET /api/v1/sellers/{id}/reviews
      try {
        final paginated = await storefrontRepo.fetchSellerReviews(
          seller.id,
          page: 1,
          perPage: 5,
        );
        reviews = paginated.items;
        reviewCount = paginated.meta.total > 0
            ? paginated.meta.total
            : reviews.length;
      } catch (_) {
        // Non-fatal: fallback handled below
      }

      // 2. Fetch seller storefront active listings via GET /api/v1/sellers/{id}
      try {
        final storefront = await storefrontRepo.fetchSellerStorefront(
          seller.id,
          tab: 'approved',
          page: 1,
          perPage: 10,
        );
        if (storefront.averageRating > 0) {
          avgRating = storefront.averageRating;
        }
        if (storefront.reviewCount > reviewCount) {
          reviewCount = storefront.reviewCount;
        }
        if (reviews.isEmpty && storefront.reviews.isNotEmpty) {
          reviews = storefront.reviews;
          if (reviewCount == 0) reviewCount = reviews.length;
        }
        otherProducts = storefront.activeListings
            .where((item) => item.id != product.id)
            .toList();
      } catch (_) {
        // Non-fatal: fallback handled below
      }
    }

    // Fallback for offline/demo listings when API returns empty
    if (otherProducts.isEmpty && product.relatedProducts.isNotEmpty) {
      otherProducts = product.relatedProducts
          .where((item) => item.id != product.id)
          .toList();
    }
    if (otherProducts.isEmpty) {
      final demoStore = ref.read(retroDemoStoreProvider);
      final demoSeller = demoStore.getDemoSellerStorefront(seller.id);
      if (demoSeller != null) {
        otherProducts = demoSeller.activeListings
            .where((item) => item.id != product.id)
            .toList();
        if (reviews.isEmpty && demoSeller.reviews.isNotEmpty) {
          reviews = demoSeller.reviews;
          reviewCount = demoSeller.reviewCount > 0
              ? demoSeller.reviewCount
              : reviews.length;
        }
      }
    }

    if (isDisposed || state.data?.id != product.id) return;

    _sellerReviews = reviews;
    _sellerReviewCount = reviewCount;
    _sellerAverageRating = avgRating;
    _sellerOtherProducts = otherProducts;
    _isLoadingSellerExtras = false;
    notifyListeners();
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

    final demoStore = ref.read(retroDemoStoreProvider);
    if (demoStore.getDemoProductDetail(currentProduct.id) != null) {
      demoStore.toggleLocalFavorite(currentProduct.id);
      return demoStore.isProductFavorited(currentProduct.id);
    }

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

  /// Guest authentication bottom sheet per DEC-01 with preserved return path
  void showGuestLoginPrompt(
    BuildContext context, {
    String featureTitle = 'Đăng nhập để tiếp tục mua sắm',
    String description =
        'Đăng nhập hoặc tạo tài khoản izithrift để lưu đồ yêu thích, thêm vào giỏ hàng, mua ngay và trò chuyện cùng chủ tiệm.',
    PendingNavigationTarget? intendedTarget,
    IconData icon = Icons.shopping_bag_outlined,
  }) {
    final target = intendedTarget ??
        PendingNavigationTarget(
          route: AppRoutes.productDetailPath(state.data?.id ?? 0),
          returnToCaller: true,
        );
    showAuthLoginBottomSheet(
      context,
      providerRef: ref,
      featureTitle: featureTitle,
      description: description,
      intendedTarget: target,
      icon: icon,
      primaryButtonLabel: 'Đăng nhập ngay',
    );
  }
}

/// Riverpod provider for ProductDetailViewModel
final productDetailViewModelProvider = ChangeNotifierProvider.autoDispose<ProductDetailViewModel>((ref) {
  final repo = ref.watch(homeCatalogRepositoryProvider);
  final storefrontRepo = ref.watch(sellerStorefrontRepositoryProvider);
  return ProductDetailViewModel(
    repository: repo,
    sellerStorefrontRepository: storefrontRepo,
    ref: ref,
  );
});
