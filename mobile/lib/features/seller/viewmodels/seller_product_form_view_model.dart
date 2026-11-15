import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/base_view_model.dart';
import '../models/seller_product_form_payload.dart';
import '../models/seller_product_item_model.dart';
import '../repositories/seller_channel_repository.dart';

/// ViewModel managing product form creation (M-SL-03) and editing/resubmission (M-SL-04).
/// Enforces BR-PR-01 (Auction quantity locked to 1), BR-PR-03 (Mandatory defect info >= 5 chars),
/// and DEC-05 (Rejection reason display & clearing upon resubmission).
class SellerProductFormViewModel extends BaseViewModel<SellerProductItemModel?> {
  final SellerChannelRepository repository;

  int? editingProductId;
  String? currentRejectionReason;
  String title = '';
  String description = '';
  int categoryId = 0;
  String categoryName = '';
  int? brandId;
  String? brandName;
  String listingType = 'FIXED_PRICE'; // FIXED_PRICE / AUCTION
  double price = 0.0;
  int quantity = 1;
  String condition = 'GOOD'; // NEW_WITH_TAGS, LIKE_NEW, GOOD, FAIR, VINTAGE_WORN
  String defectInfo = '';
  List<String> imageUrls = [];

  // Auction specific
  double? startingPrice;
  double? minBidIncrement;
  double? reservePrice;
  DateTime? auctionStartsAt;
  DateTime? auctionEndsAt;

  bool isSubmitting = false;

  SellerProductFormViewModel({required this.repository});

  /// Initializes an empty form for creating new listing (M-SL-03)
  void initForCreate() {
    editingProductId = null;
    currentRejectionReason = null;
    title = '';
    description = '';
    categoryId = 0;
    categoryName = '';
    brandId = null;
    brandName = null;
    listingType = 'FIXED_PRICE';
    price = 0.0;
    quantity = 1;
    condition = 'GOOD';
    defectInfo = '';
    imageUrls = [];
    startingPrice = null;
    minBidIncrement = null;
    reservePrice = null;
    auctionStartsAt = null;
    auctionEndsAt = null;
    isSubmitting = false;
    notifyListeners();
  }

  /// Initializes form with existing product details for editing / resubmitting (M-SL-04 / DEC-05)
  void initForEdit(SellerProductItemModel product) {
    editingProductId = product.id;
    currentRejectionReason = product.rejectionReason;
    title = product.title;
    description = '';
    categoryId = product.categoryId ?? 0;
    categoryName = product.categoryName ?? '';
    brandId = product.brandId;
    brandName = product.brandName;
    listingType = product.listingType;
    price = product.price;
    quantity = product.listingType == 'AUCTION' ? 1 : product.availableQuantity;
    condition = product.condition;
    defectInfo = product.defectInfo ?? '';
    imageUrls = product.primaryImageUrl != null ? [product.primaryImageUrl!] : [];
    startingPrice = product.startingPrice;
    minBidIncrement = product.bidIncrement;
    reservePrice = product.reservePrice;
    auctionStartsAt = product.auctionStartsAt;
    auctionEndsAt = product.auctionEndsAt;
    isSubmitting = false;
    notifyListeners();
  }

  /// Toggles listing type and enforces BR-PR-01
  void setListingType(String type) {
    listingType = type.toUpperCase();
    if (listingType == 'AUCTION') {
      // BR-PR-01: Auction total quantity must strictly be 1
      quantity = 1;
    }
    notifyListeners();
  }

  void setCondition(String cond) {
    condition = cond.toUpperCase();
    notifyListeners();
  }

  void setCategory(int id, String name) {
    categoryId = id;
    categoryName = name;
    notifyListeners();
  }

  void setBrand(int? id, String? name) {
    brandId = id;
    brandName = name;
    notifyListeners();
  }

  void addImageUrl(String url) {
    if (imageUrls.length < 10) {
      imageUrls.add(url);
      notifyListeners();
    }
  }

  void removeImageUrl(int index) {
    if (index >= 0 && index < imageUrls.length) {
      imageUrls.removeAt(index);
      notifyListeners();
    }
  }

  /// Validates and submits product listing
  Future<SellerProductItemModel?> submit({required bool submitForReview}) async {
    final payload = SellerProductFormPayload(
      title: title,
      description: description,
      categoryId: categoryId,
      brandId: brandId,
      listingType: listingType,
      price: price,
      availableQuantity: listingType == 'AUCTION' ? 1 : quantity,
      condition: condition,
      defectInfo: defectInfo,
      imageUrls: imageUrls,
      submitForReview: submitForReview,
      startingPrice: startingPrice,
      minBidIncrement: minBidIncrement,
      reservePrice: reservePrice,
      auctionStartsAt: auctionStartsAt,
      auctionEndsAt: auctionEndsAt,
    );

    final validationError = payload.validate();
    if (validationError != null) {
      setError(validationError);
      return null;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      SellerProductItemModel result;
      if (editingProductId != null) {
        // Edit / Resubmit (DEC-05)
        result = await repository.updateAndResubmitProduct(editingProductId!, payload);
        // DEC-05: Clearing rejection reason upon successful resubmission
        currentRejectionReason = null;
      } else {
        // Create new
        result = await repository.createProduct(payload);
      }

      isSubmitting = false;
      setSuccess(result);
      return result;
    } catch (e) {
      isSubmitting = false;
      setError('Lỗi khi lưu bài đăng: $e');
      return null;
    }
  }
}

/// Riverpod provider for SellerProductFormViewModel
final sellerProductFormViewModelProvider = ChangeNotifierProvider.autoDispose<SellerProductFormViewModel>((ref) {
  final repo = ref.watch(sellerChannelRepositoryProvider);
  return SellerProductFormViewModel(repository: repo);
});
