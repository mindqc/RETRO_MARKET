import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/base_view_model.dart';
import '../../catalog/models/product_summary_model.dart';
import '../../catalog/models/review_item_model.dart';
import '../../home/models/featured_seller_model.dart';
import '../models/saved_engagement_overview_model.dart';
import '../models/seller_reviews_summary_model.dart';
import '../repositories/communication_engagement_repository.dart';

// ==========================================
// ENGAGEMENT VIEW MODEL (M-PF-05)
// ==========================================

/// ViewModel for Saved Favorites & Followed Shops (M-PF-05)
class EngagementViewModel extends BaseViewModel<SavedEngagementOverviewModel> {
  final CommunicationEngagementRepository repository;

  final List<ProductSummaryModel> _favoriteProducts = [];
  final List<FeaturedSellerModel> _followedShops = [];
  int _activeTabIndex = 0; // 0: Favorites, 1: Followed Shops

  EngagementViewModel({required this.repository});

  List<ProductSummaryModel> get favoriteProducts => List.unmodifiable(_favoriteProducts);
  List<FeaturedSellerModel> get followedShops => List.unmodifiable(_followedShops);
  int get activeTabIndex => _activeTabIndex;

  void setActiveTab(int index) {
    if (_activeTabIndex != index) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  /// Loads favorite products and followed shops
  Future<void> loadEngagementData() async {
    setLoading();
    try {
      final favResponse = await repository.fetchFavorites(page: 1, perPage: 20);
      _favoriteProducts.clear();
      _favoriteProducts.addAll(favResponse.items);

      setSuccess(
        SavedEngagementOverviewModel(
          favoriteProducts: List.unmodifiable(_favoriteProducts),
          followedShops: List.unmodifiable(_followedShops),
        ),
      );
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Optimistically toggles favorite for a product (AC-P711-03)
  Future<bool> toggleFavoriteProduct(int productId) async {
    final existingIndex = _favoriteProducts.indexWhere((p) => p.id == productId);
    ProductSummaryModel? removedProduct;

    if (existingIndex != -1) {
      // Remove from favorites list immediately
      removedProduct = _favoriteProducts.removeAt(existingIndex);
      notifyListeners();
    }

    try {
      final isFavorited = await repository.toggleFavorite(productId);
      if (isFavorited && removedProduct != null) {
        // If server says favorited but we removed it, restore it
        _favoriteProducts.add(removedProduct);
        notifyListeners();
      }
      return isFavorited;
    } catch (e) {
      // Revert if error
      if (removedProduct != null) {
        _favoriteProducts.insert(existingIndex, removedProduct);
        notifyListeners();
      }
      return existingIndex != -1;
    }
  }

  /// Optimistically toggles follow for a seller shop (AC-P711-03)
  Future<bool> toggleFollowSeller(FeaturedSellerModel seller) async {
    final existingIndex = _followedShops.indexWhere((s) => s.id == seller.id);
    if (existingIndex != -1) {
      _followedShops.removeAt(existingIndex);
    } else {
      _followedShops.add(seller);
    }
    notifyListeners();

    try {
      final isFollowing = await repository.toggleFollowSeller(seller.id);
      if (!isFollowing) {
        _followedShops.removeWhere((s) => s.id == seller.id);
      } else if (!_followedShops.any((s) => s.id == seller.id)) {
        _followedShops.add(seller);
      }
      notifyListeners();
      return isFollowing;
    } catch (e) {
      // Revert
      if (existingIndex != -1) {
        _followedShops.insert(existingIndex, seller);
      } else {
        _followedShops.removeWhere((s) => s.id == seller.id);
      }
      notifyListeners();
      return existingIndex == -1;
    }
  }
}

/// Riverpod provider for EngagementViewModel
final engagementViewModelProvider = ChangeNotifierProvider.autoDispose<EngagementViewModel>((ref) {
  final repo = ref.watch(communicationEngagementRepositoryProvider);
  return EngagementViewModel(repository: repo);
});

// ==========================================
// REVIEW VIEW MODEL (M-RV-01..02)
// ==========================================

/// ViewModel for Verified Reviews & Seller Reviews List (M-RV-01..02)
class ReviewViewModel extends BaseViewModel<SellerReviewsSummaryModel> {
  final CommunicationEngagementRepository repository;

  SellerReviewsSummaryModel? _reviewsSummary;
  int? _activeStarFilter;
  bool _isSubmitting = false;

  ReviewViewModel({required this.repository});

  SellerReviewsSummaryModel? get reviewsSummary => _reviewsSummary;
  int? get activeStarFilter => _activeStarFilter;
  bool get isSubmitting => _isSubmitting;

  /// Filtered reviews based on selected star rating chip
  List<ReviewItemModel> get filteredReviews {
    final list = _reviewsSummary?.reviews ?? [];
    if (_activeStarFilter == null || _activeStarFilter == 0) {
      return list;
    }
    return list.where((r) => r.rating == _activeStarFilter).toList();
  }

  /// Sets star filter (null or 0 means all stars)
  void setStarFilter(int? star) {
    if (_activeStarFilter != star) {
      _activeStarFilter = (star != null && star > 0) ? star : null;
      notifyListeners();
    }
  }

  /// Loads reviews summary and items for a seller (M-RV-02)
  Future<void> loadSellerReviews(int sellerId) async {
    setLoading();
    try {
      final summary = await repository.fetchSellerReviews(
        sellerId,
        ratingFilter: _activeStarFilter,
      );
      _reviewsSummary = summary;
      setSuccess(summary);
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Submits verified 1-5 star review for completed order (M-RV-01 / BR-RV-01)
  Future<bool> submitVerifiedReview({
    required int orderId,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      setError('Vui lòng chọn số sao từ 1 đến 5');
      return false;
    }
    if (comment.trim().length < 5) {
      setError('Nhận xét tối thiểu 5 ký tự');
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await repository.submitVerifiedReview(
        orderId,
        rating: rating,
        comment: comment.trim(),
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      setError(e.toString());
      return false;
    }
  }
}

/// Riverpod provider for ReviewViewModel
final reviewViewModelProvider = ChangeNotifierProvider.autoDispose<ReviewViewModel>((ref) {
  final repo = ref.watch(communicationEngagementRepositoryProvider);
  return ReviewViewModel(repository: repo);
});
