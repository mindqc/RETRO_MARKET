import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_client.dart';
import '../models/seller_dashboard_model.dart';
import '../models/seller_product_form_payload.dart';
import '../models/seller_product_item_model.dart';
import '../models/seller_wallet_overview_model.dart';

/// Unified Repository for Seller Channel operations (M-SL-01, M-SL-02, M-SL-03, M-SL-04, M-SL-08).
class SellerChannelRepository {
  final DioClient dioClient;

  SellerChannelRepository({required this.dioClient});

  Future<FormData> _buildProductFormData(
    SellerProductFormPayload payload,
  ) async {
    final fields = payload.toMap();
    final files = <MultipartFile>[];
    for (final file in payload.imageFiles) {
      files.add(
        MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name),
      );
    }
    if (files.isNotEmpty) fields['images'] = files;
    return FormData.fromMap(fields);
  }

  /// Fetches seller metrics and action item counters (M-SL-01)
  /// GET /api/v1/seller/dashboard
  Future<SellerDashboardModel> fetchDashboard() async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.sellerDashboard,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SellerDashboardModel.fromJson(data);
  }

  /// Lists seller products filtered by status with pagination (M-SL-02)
  /// GET /api/v1/seller/products
  Future<PaginatedResponse<SellerProductItemModel>> fetchSellerProducts({
    String? status,
    int page = 1,
    int perPage = 12,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
    if (status != null && status.toUpperCase() != 'ALL') {
      queryParams['status'] = status.toUpperCase();
    }

    return dioClient.getPaginated<SellerProductItemModel>(
      ApiEndpoints.sellerProducts,
      queryParameters: queryParams,
      fromJsonItem: (item) => SellerProductItemModel.fromJson(
        item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  /// Creates a new product listing (M-SL-03)
  /// POST /api/v1/seller/products
  Future<SellerProductItemModel> createProduct(
    SellerProductFormPayload payload,
  ) async {
    final response = payload.imageFiles.isNotEmpty
        ? await dioClient.postMultipart<Map<String, dynamic>>(
            ApiEndpoints.sellerProducts,
            formData: await _buildProductFormData(payload),
          )
        : await dioClient.post<Map<String, dynamic>>(
            ApiEndpoints.sellerProducts,
            data: payload.toMap(),
          );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SellerProductItemModel.fromJson(data);
  }

  /// Fetches seller product details for editing or inspecting (P9-01 / Option 2)
  /// GET /api/v1/products/{id}
  Future<SellerProductItemModel> fetchProductDetail(int productId) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.productDetail(productId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final productMap = data['product'] is Map<String, dynamic>
        ? data['product'] as Map<String, dynamic>
        : data;
    return SellerProductItemModel.fromJson(productMap);
  }

  /// Updates or resubmits a rejected product listing (M-SL-04 / DEC-05)
  /// PUT /api/v1/seller/products/{id}
  Future<SellerProductItemModel> updateAndResubmitProduct(
    int productId,
    SellerProductFormPayload payload,
  ) async {
    final response = payload.imageFiles.isNotEmpty
        ? await dioClient.putMultipart<Map<String, dynamic>>(
            ApiEndpoints.sellerProductDetail(productId),
            formData: await _buildProductFormData(payload),
          )
        : await dioClient.put<Map<String, dynamic>>(
            ApiEndpoints.sellerProductDetail(productId),
            data: payload.toMap(),
          );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SellerProductItemModel.fromJson(data);
  }

  /// Changes listing visibility or status (APPROVED <-> HIDDEN, ARCHIVED, DRAFT)
  /// PATCH /api/v1/seller/products/{id}/status
  Future<Map<String, dynamic>> updateProductStatus(
    int productId,
    String status,
  ) async {
    final response = await dioClient.patch<Map<String, dynamic>>(
      ApiEndpoints.sellerProductStatus(productId),
      data: {'status': status.toUpperCase()},
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  /// Relists an expired or cancelled auction product (M-SL-02 / DEC-02)
  /// POST /api/v1/seller/products/{id}/relist
  Future<Map<String, dynamic>> relistAuctionProduct(
    int productId,
    Map<String, dynamic> scheduleData,
  ) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.sellerRelist(productId),
      data: scheduleData,
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  /// Fetches seller wallet balance, escrow held funds, and append-only ledger (M-SL-08)
  /// GET /api/v1/seller/wallet
  Future<SellerWalletOverviewModel> fetchWalletLedger({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.sellerWallet,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SellerWalletOverviewModel.fromJson(data);
  }
}

/// Riverpod provider for SellerChannelRepository
final sellerChannelRepositoryProvider = Provider<SellerChannelRepository>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return SellerChannelRepository(dioClient: dioClient);
});
