import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_client.dart';
import '../models/review_item_model.dart';
import '../models/seller_public_profile_model.dart';

/// Repository for Public Seller Storefront, Follower Management and Reviews (M-US-03)
class SellerStorefrontRepository {
  final DioClient dioClient;

  SellerStorefrontRepository({required this.dioClient});

  /// Fetches public seller storefront data including profile and listings (M-US-03)
  /// GET /api/v1/sellers/{id}
  Future<SellerPublicProfileModel> fetchSellerStorefront(
    int sellerId, {
    String tab = 'approved',
    int page = 1,
    int perPage = 12,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.sellerDetail(sellerId),
      queryParameters: {
        'tab': tab,
        'page': page,
        'per_page': perPage,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SellerPublicProfileModel.fromJson(data);
  }

  /// Toggles follow status for a seller (BR-AC-02 self-follow blocked)
  /// POST /api/v1/sellers/{id}/follow
  Future<Map<String, dynamic>> toggleFollowSeller(int sellerId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.sellerFollow(sellerId),
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  /// Fetches paginated verified buyer reviews for seller storefront (M-US-03)
  /// GET /api/v1/sellers/{id}/reviews
  Future<PaginatedResponse<ReviewItemModel>> fetchSellerReviews(
    int sellerId, {
    int? rating,
    int page = 1,
    int perPage = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (rating != null) {
      queryParams['rating'] = rating;
    }

    return dioClient.getPaginated<ReviewItemModel>(
      ApiEndpoints.sellerReviews(sellerId),
      queryParameters: queryParams,
      fromJsonItem: (item) => ReviewItemModel.fromJson(
        item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map),
      ),
    );
  }
}

/// Riverpod provider for SellerStorefrontRepository
final sellerStorefrontRepositoryProvider = Provider<SellerStorefrontRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SellerStorefrontRepository(dioClient: dioClient);
});
