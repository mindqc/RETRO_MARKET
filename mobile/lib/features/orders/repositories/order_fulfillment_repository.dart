import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_client.dart';
import '../models/dispute_evidence_model.dart';
import '../models/dispute_model.dart';
import '../models/order_model.dart';

/// Unified Repository managing Buyer Purchases, Seller Fulfillment, and Dispute Resolution (P7-09).
class OrderFulfillmentRepository {
  final DioClient dioClient;

  OrderFulfillmentRepository({required this.dioClient});

  // ==========================================
  // BUYER PURCHASES ENDPOINTS (M-OR-02..05)
  // ==========================================

  /// Lists orders purchased by current authenticated user (M-OR-02).
  /// GET /api/v1/orders/purchases
  Future<PaginatedResponse<OrderModel>> fetchMyPurchases({
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status.toUpperCase();
    }

    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.myPurchases,
      queryParameters: queryParams,
    );

    return PaginatedResponse.fromJson(
      response.data ?? {},
      (json) => OrderModel.fromJson(json),
    );
  }

  /// Retrieves order details by order ID (M-OR-03 / M-SL-06).
  /// GET /api/v1/orders/{id}
  Future<OrderModel> fetchOrderDetail(int orderId) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.orderDetail(orderId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data);
  }

  /// Cancels order or requests cancellation according to 3-tier rules (DEC-06 / M-OR-04).
  /// POST /api/v1/orders/{id}/cancel
  Future<OrderModel> cancelOrder(int orderId, {required String reason}) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.cancelOrder(orderId),
      data: {'reason': reason},
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data);
  }

  /// Withdraws pending buyer cancellation request during PREPARING status (DEC-06).
  /// POST /api/v1/orders/{id}/withdraw-cancel-request
  Future<OrderModel> withdrawCancelRequest(int orderId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.withdrawCancelRequest(orderId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data);
  }

  /// Buyer confirms satisfactory delivery, immediately releasing 100% item_subtotal to Seller (DEC-04 / OF-05).
  /// POST /api/v1/orders/{id}/confirm-delivery
  Future<OrderModel> confirmDeliveryAndReleaseEscrow(int orderId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.confirmDelivery(orderId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data);
  }

  // ==========================================
  // SELLER FULFILLMENT ENDPOINTS (M-SL-05..07)
  // ==========================================

  /// Lists orders sold by the authenticated seller's store (M-SL-05).
  /// GET /api/v1/seller/orders
  Future<PaginatedResponse<OrderModel>> fetchSellerOrders({
    String? status,
    int page = 1,
    int perPage = 12,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status.toUpperCase();
    }

    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.sellerOrders,
      queryParameters: queryParams,
    );

    return PaginatedResponse.fromJson(
      response.data ?? {},
      (json) => OrderModel.fromJson(json),
    );
  }

  /// Marks paid order as PREPARING (M-SL-06).
  /// POST /api/v1/seller/orders/{id}/prepare
  Future<OrderModel> markOrderPreparing(int orderId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.sellerOrderPrepare(orderId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data);
  }

  /// Attaches shipping details and transitions order to SHIPPED (M-SL-07).
  /// POST /api/v1/seller/orders/{id}/ship
  Future<OrderModel> shipOrder(
    int orderId, {
    required String carrierName,
    required String trackingCode,
    String? shippingNote,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.sellerOrderShip(orderId),
      data: {
        'carrier_name': carrierName,
        'tracking_code': trackingCode,
        if (shippingNote != null && shippingNote.isNotEmpty) 'shipping_note': shippingNote,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data);
  }

  /// Marks order as DELIVERED to buyer, starting 24h countdown to auto-complete (OF-04).
  /// POST /api/v1/seller/orders/{id}/deliver
  Future<OrderModel> markOrderDelivered(int orderId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.sellerOrderDeliver(orderId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data);
  }

  /// Seller responds to buyer's cancellation request (APPROVE or REJECT) (DEC-06 / DEC-07).
  /// POST /api/v1/seller/orders/{id}/respond-cancel
  Future<OrderModel> respondToCancelRequest(
    int orderId, {
    required String action, // 'APPROVE' or 'REJECT'
    String? reason,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.sellerOrderRespondCancel(orderId),
      data: {
        'decision': action.toUpperCase(),
        if (reason != null && reason.isNotEmpty) 'note': reason,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data);
  }

  // ==========================================
  // DISPUTE RESOLUTION ENDPOINTS (M-DP-01..03)
  // ==========================================

  /// Lists all disputes involving the user as buyer or seller.
  /// GET /api/v1/disputes
  Future<PaginatedResponse<DisputeModel>> fetchDisputes({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.disputes,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    return PaginatedResponse.fromJson(
      response.data ?? {},
      (json) => DisputeModel.fromJson(json),
    );
  }

  /// Fetches dispute detail and full 2-way counter evidence thread (M-DP-02).
  /// GET /api/v1/disputes/{id}
  Future<DisputeModel> fetchDisputeDetail(int disputeId) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.disputeDetail(disputeId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return DisputeModel.fromJson(data);
  }

  /// Opens dispute against order, immediately freezing escrow funds (DEC-03 / BR-DP-02 / M-DP-01).
  /// POST /api/v1/orders/{id}/disputes
  Future<DisputeModel> openDispute(
    int orderId, {
    required String reasonCategory,
    required String description,
    List<String> attachmentUrls = const [],
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.openDispute(orderId),
      data: {
        'reason_category': reasonCategory,
        'description': description,
        if (attachmentUrls.isNotEmpty) 'evidences': attachmentUrls,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return DisputeModel.fromJson(data);
  }

  /// Submits additional evidence or counter-statement to active dispute (M-DP-03).
  /// POST /api/v1/disputes/{id}/evidences
  Future<DisputeEvidenceModel> submitDisputeEvidence(
    int disputeId, {
    required String messageNote,
    String? evidenceType,
    List<String> attachmentUrls = const [],
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.disputeEvidences(disputeId),
      data: {
        'message_note': messageNote,
        'evidence_type': ?evidenceType,
        if (attachmentUrls.isNotEmpty) 'file_url': attachmentUrls.first,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return DisputeEvidenceModel.fromJson(data);
  }
}

/// Riverpod provider for OrderFulfillmentRepository
final orderFulfillmentRepositoryProvider = Provider<OrderFulfillmentRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OrderFulfillmentRepository(dioClient: dioClient);
});
