import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/cart_item_model.dart';
import '../models/cart_model.dart';
import '../models/checkout_preview_model.dart';
import '../models/payment_session_model.dart';

/// Unified Repository managing Cart, Checkout (DEC-04) and Mock QR Escrow Payments (M-PM-01..03).
class CartCheckoutRepository {
  final DioClient dioClient;

  CartCheckoutRepository({required this.dioClient});

  /// Fetches the current user's shopping cart grouped by store (M-CR-01).
  /// GET /api/v1/cart
  Future<CartModel> fetchCart() async {
    final response = await dioClient.get<Map<String, dynamic>>(ApiEndpoints.cart);
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return CartModel.fromJson(data);
  }

  /// Adds a product to the cart (M-CR-01 / M-PD-01).
  /// POST /api/v1/cart/items
  Future<CartItemModel> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.cartItems,
      data: {
        'product_id': productId,
        'quantity': quantity,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return CartItemModel.fromJson(data);
  }

  /// Updates quantity of an item in cart.
  /// PUT /api/v1/cart/items/{id}
  Future<CartItemModel> updateCartItemQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    final response = await dioClient.put<Map<String, dynamic>>(
      ApiEndpoints.cartItemDetail(cartItemId),
      data: {
        'quantity': quantity,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return CartItemModel.fromJson(data);
  }

  /// Removes an item from the cart.
  /// DELETE /api/v1/cart/items/{id}
  Future<bool> removeCartItem(int cartItemId) async {
    await dioClient.delete<Map<String, dynamic>>(
      ApiEndpoints.cartItemDetail(cartItemId),
    );
    return true;
  }

  /// Previews checkout breakdown with Buyer Protection Fee (DEC-04 / M-OR-01).
  /// POST /api/v1/checkout/preview
  Future<CheckoutPreviewModel> previewCheckout({
    required String source, // 'CART' or 'BUY_NOW'
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    int? addressId,
  }) async {
    final payload = <String, dynamic>{
      'source': source.toUpperCase(),
    };
    if (cartItemIds != null && cartItemIds.isNotEmpty) {
      payload['cart_item_ids'] = cartItemIds;
    }
    if (productId != null) {
      payload['product_id'] = productId;
      payload['quantity'] = quantity ?? 1;
    }
    if (addressId != null) {
      payload['address_id'] = addressId;
    }

    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.checkoutPreview,
      data: payload,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return CheckoutPreviewModel.fromJson(data);
  }

  /// Places order and creates initial payment session (M-OR-01 / OF-02).
  /// POST /api/v1/orders
  Future<PaymentSessionModel> placeOrder({
    required String source, // 'CART' or 'BUY_NOW'
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    required int shippingAddressId,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      'source': source.toUpperCase(),
      'shipping_address_id': shippingAddressId,
    };
    if (cartItemIds != null && cartItemIds.isNotEmpty) {
      payload['cart_item_ids'] = cartItemIds;
    }
    if (productId != null) {
      payload['product_id'] = productId;
      payload['quantity'] = quantity ?? 1;
    }
    if (note != null && note.isNotEmpty) {
      payload['note'] = note;
    }

    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.placeOrder,
      data: payload,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return PaymentSessionModel.fromJson(data);
  }

  /// Fetches payment QR session details (M-PM-01).
  /// GET /api/v1/payments/{id}
  Future<PaymentSessionModel> fetchPaymentStatus(int paymentId) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.paymentDetail(paymentId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return PaymentSessionModel.fromJson(data);
  }

  /// Simulates QR payment success (M-PM-01 -> M-PM-02 / BR-FN-03).
  /// POST /api/v1/payments/{id}/simulate-success
  Future<PaymentSessionModel> simulatePaymentSuccess(int paymentId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.simulatePaymentSuccess(paymentId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return PaymentSessionModel.fromJson(data);
  }

  /// Simulates QR payment failure (M-PM-01 -> M-PM-03).
  /// POST /api/v1/payments/{id}/simulate-failure
  Future<PaymentSessionModel> simulatePaymentFailure(int paymentId, {String? reason}) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.simulatePaymentFailure(paymentId),
      data: reason != null ? {'reason': reason} : null,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return PaymentSessionModel.fromJson(data);
  }
}

/// Riverpod provider for CartCheckoutRepository
final cartCheckoutRepositoryProvider = Provider<CartCheckoutRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CartCheckoutRepository(dioClient: dioClient);
});
