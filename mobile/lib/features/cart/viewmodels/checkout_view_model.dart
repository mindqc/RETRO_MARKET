import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Stored parameters for reloading preview if address changes
  String _source = 'CART';
  List<int>? _cartItemIds;
  int? _productId;
  int? _quantity;

  CheckoutViewModel({required this.repository});

  /// Loads checkout breakdown from POST /api/v1/checkout/preview
  Future<void> loadCheckoutPreview({
    required String source,
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    int? addressId,
  }) async {
    _source = source;
    _cartItemIds = cartItemIds;
    _productId = productId;
    _quantity = quantity;

    await runCatching(
      () async {
        final preview = await repository.previewCheckout(
          source: source,
          cartItemIds: cartItemIds,
          productId: productId,
          quantity: quantity,
          addressId: addressId ?? selectedAddress?.id,
        );

        if (selectedAddress == null && preview.shippingAddress != null) {
          selectedAddress = preview.shippingAddress;
        }

        return preview;
      },
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

  /// Places the order and returns the Payment session (M-PM-01)
  Future<PaymentSessionModel?> placeOrder() async {
    if (selectedAddress == null) {
      setError('Vui lòng chọn hoặc thêm địa chỉ nhận hàng.');
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
      setError('Lỗi khi đặt hàng: $e');
      return null;
    }
  }
}

/// Riverpod provider for CheckoutViewModel
final checkoutViewModelProvider = ChangeNotifierProvider.autoDispose<CheckoutViewModel>((ref) {
  final repo = ref.watch(cartCheckoutRepositoryProvider);
  return CheckoutViewModel(repository: repo);
});
