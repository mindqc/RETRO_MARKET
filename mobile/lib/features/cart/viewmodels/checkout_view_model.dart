import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/base_view_model.dart';
import '../../profile/models/user_address_model.dart';
import '../models/checkout_preview_model.dart';
import '../models/payment_session_model.dart';
import '../repositories/cart_checkout_repository.dart';

/// ViewModel managing Order Checkout preview, address resolution, and order creation (DEC-04 / M-OR-01).
class CheckoutViewModel extends BaseViewModel<CheckoutPreviewModel> {
  final CartCheckoutRepository repository;

  UserAddressModel? selectedAddress;
  String? orderNote;
  bool isSubmittingOrder = false;
  String? _submitErrorMessage;

  // Stored parameters for reloading preview if address changes
  String _source = 'CART';
  List<int>? _cartItemIds;
  int? _productId;
  int? _quantity;

  CheckoutViewModel({required this.repository});

  @override
  String? get errorMessage => _submitErrorMessage ?? super.errorMessage;

  /// Checks whether the checkout preview has valid order groups, items, and grand total.
  bool get isCheckoutValid {
    final preview = state.data;
    if (preview == null) return false;
    if (preview.orderGroups.isEmpty) return false;
    if (preview.itemsCount <= 0) return false;
    if (preview.orderGroups.every((g) => g.items.isEmpty)) return false;
    if (preview.grandTotalAmount <= 0) return false;
    return true;
  }

  /// Loads checkout breakdown from POST /api/v1/checkout/preview
  Future<void> loadCheckoutPreview({
    required String source,
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    int? addressId,
    bool refreshAddressFromServer = false,
  }) async {
    _submitErrorMessage = null;
    _source = source;
    _cartItemIds = cartItemIds;
    _productId = productId;
    _quantity = quantity;

    final int? effectiveAddressId = refreshAddressFromServer
        ? addressId
        : (addressId ?? selectedAddress?.id);

    await runCatching(
      () async {
        final preview = await repository.previewCheckout(
          source: source,
          cartItemIds: cartItemIds,
          productId: productId,
          quantity: quantity,
          addressId: effectiveAddressId,
        );

        if (refreshAddressFromServer) {
          selectedAddress = preview.shippingAddress;
        } else if (preview.shippingAddress != null &&
            (selectedAddress == null ||
                selectedAddress!.id == preview.shippingAddress!.id)) {
          selectedAddress = preview.shippingAddress;
        }

        return preview;
      },
      isEmpty: (preview) =>
          preview.orderGroups.isEmpty ||
          preview.itemsCount <= 0 ||
          preview.orderGroups.every((group) => group.items.isEmpty),
      emptyMessage: 'Không có sản phẩm nào để thanh toán.',
    );
  }

  /// Updates delivery address and refreshes cost preview
  void updateShippingAddress(UserAddressModel address) {
    selectedAddress = address;
    notifyListeners();
    loadCheckoutPreview(
      source: _source,
      cartItemIds: _cartItemIds,
      productId: _productId,
      quantity: _quantity,
      addressId: address.id,
    );
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      if (error.error is ApiException) {
        return (error.error as ApiException).message;
      }
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ?? 'Không thể kết nối đến máy chủ.';
    }
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  /// Places the order and returns the Payment session (M-PM-01)
  Future<PaymentSessionModel?> placeOrder() async {
    _submitErrorMessage = null;
    final preview = state.data;

    if (preview == null ||
        preview.orderGroups.isEmpty ||
        preview.itemsCount <= 0 ||
        preview.orderGroups.every((group) => group.items.isEmpty)) {
      _submitErrorMessage = 'Không có sản phẩm hợp lệ để đặt hàng.';
      notifyListeners();
      return null;
    }

    if (preview.grandTotalAmount <= 0) {
      _submitErrorMessage = 'Tổng thanh toán không hợp lệ.';
      notifyListeners();
      return null;
    }

    if (selectedAddress == null || selectedAddress!.id <= 0) {
      _submitErrorMessage = 'Vui lòng chọn hoặc thêm địa chỉ nhận hàng.';
      notifyListeners();
      return null;
    }

    isSubmittingOrder = true;
    notifyListeners();

    try {
      final paymentSession = await repository.placeOrder(
        source: _source,
        cartItemIds: _cartItemIds,
        productId: _productId,
        quantity: _quantity,
        shippingAddressId: selectedAddress!.id,
        note: orderNote,
      );

      isSubmittingOrder = false;
      notifyListeners();
      return paymentSession;
    } catch (e) {
      isSubmittingOrder = false;
      _submitErrorMessage = 'Lỗi khi đặt hàng: ${_extractErrorMessage(e)}';
      notifyListeners();
      return null;
    }
  }
}

/// Riverpod provider for CheckoutViewModel
final checkoutViewModelProvider =
    ChangeNotifierProvider.autoDispose<CheckoutViewModel>((ref) {
      final repo = ref.watch(cartCheckoutRepositoryProvider);
      return CheckoutViewModel(repository: repo);
    });
