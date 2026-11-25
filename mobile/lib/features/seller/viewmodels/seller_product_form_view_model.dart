import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/state/base_view_model.dart';
import '../models/seller_product_form_payload.dart';
import '../models/seller_product_item_model.dart';
import '../repositories/seller_channel_repository.dart';

/// ViewModel managing product form creation (M-SL-03), auction creation, and editing/resubmission (M-SL-04).
/// Enforces BR-PR-01 (Auction quantity locked to 1), BR-PR-03 (Mandatory defect info >= 5 chars),
/// DEC-05 (Rejection reason display & clearing upon resubmission), and strict PENDING_REVIEW moderation.
class SellerProductFormViewModel
    extends BaseViewModel<SellerProductItemModel?> {
  final SellerChannelRepository repository;
  final RetroDemoMarketplaceStore? demoStore;

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
  String condition =
      'GOOD'; // NEW_WITH_TAGS, LIKE_NEW, GOOD, FAIR, VINTAGE_WORN
  String defectInfo = '';
  String location = 'Quận 1, TP. Hồ Chí Minh';
  String shippingNote = 'Giao hàng toàn quốc • Cho kiểm tra trước khi nhận';
  List<String> imageUrls = [];
  List<XFile> imageFiles = [];

  // Auction specific
  double? startingPrice;
  double? minBidIncrement;
  double? reservePrice;
  DateTime? auctionStartsAt;
  DateTime? auctionEndsAt;

  bool isSubmitting = false;

  SellerProductFormViewModel({
    required this.repository,
    this.demoStore,
  });

  /// Initializes an empty form for creating a fixed-price or general listing (M-SL-03)
  void initForCreate({String initialListingType = 'FIXED_PRICE'}) {
    editingProductId = null;
    currentRejectionReason = null;
    title = '';
    description = '';
    categoryId = 0;
    categoryName = '';
    brandId = null;
    brandName = null;
    listingType = initialListingType.toUpperCase();
    price = 0.0;
    quantity = 1;
    condition = 'GOOD';
    defectInfo = '';
    location = 'Quận 1, TP. Hồ Chí Minh';
    shippingNote = 'Giao hàng toàn quốc • Cho kiểm tra trước khi nhận';
    imageUrls = [];
    imageFiles = [];
    startingPrice = null;
    minBidIncrement = listingType == 'AUCTION' ? 20000.0 : null;
    reservePrice = null;
    if (listingType == 'AUCTION') {
      final start = DateTime.now().add(const Duration(minutes: 30));
      auctionStartsAt = start;
      auctionEndsAt = start.add(const Duration(hours: 24));
    } else {
      auctionStartsAt = null;
      auctionEndsAt = null;
    }
    isSubmitting = false;
    notifyListeners();
  }

  /// Initializes form with existing product details for editing / resubmitting (M-SL-04 / DEC-05)
  void initForEdit(SellerProductItemModel product) {
    editingProductId = product.id;
    currentRejectionReason = product.rejectionReason;
    title = product.title;
    description = product.description ?? '';
    categoryId = product.categoryId ?? 0;
    categoryName = product.categoryName ?? '';
    brandId = product.brandId;
    brandName = product.brandName;
    listingType = product.listingType;
    price = product.price;
    quantity = product.listingType == 'AUCTION' ? 1 : product.availableQuantity;
    condition = product.condition;
    defectInfo = product.defectInfo ?? '';
    imageUrls = product.primaryImageUrl != null
        ? [product.primaryImageUrl!]
        : [];
    imageFiles = [];
    startingPrice = product.startingPrice;
    minBidIncrement = product.bidIncrement;
    reservePrice = product.reservePrice;
    auctionStartsAt = product.auctionStartsAt;
    auctionEndsAt = product.auctionEndsAt;
    isSubmitting = false;
    notifyListeners();
  }

  /// Asynchronously loads product details by ID for editing/resubmission (P9-01 / Option 2)
  Future<SellerProductItemModel?> loadProductForEdit(int productId) async {
    setLoading();
    try {
      final product = await repository.fetchProductDetail(productId);
      initForEdit(product);
      setSuccess(product);
      return product;
    } catch (e) {
      setError('Lỗi khi tải thông tin bài đăng: $e');
      return null;
    }
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

  void setLocation(String value) {
    location = value.trim();
    notifyListeners();
  }

  void setShippingNote(String value) {
    shippingNote = value.trim();
    notifyListeners();
  }

  void addImageUrl(String url) {
    if (imageUrls.length + imageFiles.length < 10) {
      imageUrls.add(url);
      notifyListeners();
    }
  }

  void setPrimaryImageUrl(int index) {
    if (index > 0 && index < imageUrls.length) {
      final picked = imageUrls.removeAt(index);
      imageUrls.insert(0, picked);
      notifyListeners();
    }
  }

  void addImageFiles(Iterable<XFile> files) {
    final remaining = [
      8 - imageFiles.length,
      10 - imageUrls.length - imageFiles.length,
    ].reduce((a, b) => a < b ? a : b);
    if (remaining <= 0) return;
    imageFiles.addAll(files.take(remaining));
    notifyListeners();
  }

  void setPrimaryImageFile(int index) {
    if (index > 0 && index < imageFiles.length) {
      final picked = imageFiles.removeAt(index);
      imageFiles.insert(0, picked);
      notifyListeners();
    }
  }

  void removeImageFile(int index) {
    if (index >= 0 && index < imageFiles.length) {
      imageFiles.removeAt(index);
      notifyListeners();
    }
  }

  void removeImageUrl(int index) {
    if (index >= 0 && index < imageUrls.length) {
      imageUrls.removeAt(index);
      notifyListeners();
    }
  }

  /// Validates and submits product or auction listing.
  /// Strict Moderation Policy: Newly submitted listings ALWAYS enter PENDING_REVIEW
  /// (never auto-published to public marketplace feeds).
  Future<SellerProductItemModel?> submit({
    required bool submitForReview,
  }) async {
    final composedDescription = _composeEnrichedDescription();

    final payload = SellerProductFormPayload(
      title: title,
      description: composedDescription,
      categoryId: categoryId,
      brandId: brandId,
      listingType: listingType,
      price: listingType == 'AUCTION' ? (startingPrice ?? price) : price,
      availableQuantity: listingType == 'AUCTION' ? 1 : quantity,
      condition: condition,
      defectInfo: defectInfo,
      imageUrls: imageUrls.where((u) => !u.startsWith('assets/')).toList(),
      imageFiles: imageFiles,
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
        result = await repository.updateAndResubmitProduct(
          editingProductId!,
          payload,
        );
        currentRejectionReason = null;
      } else {
        result = await repository.createProduct(payload);
      }

      isSubmitting = false;
      setSuccess(result);
      return result;
    } catch (e) {
      // Demo-compatible offline fallback: strictly stores submission as PENDING_REVIEW / DRAFT
      if (demoStore != null && editingProductId == null) {
        final demoItem = demoStore!.addPendingSubmission(
          title: title,
          description: composedDescription,
          categoryId: categoryId,
          categoryName: categoryName.isNotEmpty ? categoryName : 'Vintage',
          listingType: listingType,
          price: listingType == 'AUCTION' ? (startingPrice ?? price) : price,
          quantity: listingType == 'AUCTION' ? 1 : quantity,
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
        isSubmitting = false;
        setSuccess(demoItem);
        return demoItem;
      }

      isSubmitting = false;
      setError('Lỗi khi lưu bài đăng: $e');
      return null;
    }
  }

  String _composeEnrichedDescription() {
    final buffer = StringBuffer(description.trim());
    if (location.isNotEmpty && !description.contains('Khu vực:')) {
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write('Khu vực: $location');
    }
    if (shippingNote.isNotEmpty && !description.contains('Giao hàng:')) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('Giao hàng: $shippingNote');
    }
    return buffer.toString();
  }
}

/// Riverpod provider for SellerProductFormViewModel
final sellerProductFormViewModelProvider =
    ChangeNotifierProvider.autoDispose<SellerProductFormViewModel>((ref) {
      final repo = ref.watch(sellerChannelRepositoryProvider);
      final demoStore = ref.read(retroDemoStoreProvider);
      return SellerProductFormViewModel(
        repository: repo,
        demoStore: demoStore,
      );
    });
