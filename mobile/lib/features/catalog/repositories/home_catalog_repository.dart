import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_client.dart';
import '../../home/models/home_feed_model.dart';
import '../models/product_detail_model.dart';
import '../models/product_filter_query.dart';
import '../models/product_summary_model.dart';
import '../models/taxonomy_model.dart';

/// Repository for Home Discovery, Catalog Taxonomy, and Product Search & Detail (P7-05, P7-06)
class HomeCatalogRepository {
  final DioClient dioClient;

  HomeCatalogRepository({required this.dioClient});

  /// Fetches aggregated Home Discovery feed (M-HM-01)
  /// GET /api/v1/home
  Future<HomeFeedModel> fetchHomeFeed() async {
    final response = await dioClient.get<Map<String, dynamic>>(ApiEndpoints.home);
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return HomeFeedModel.fromJson(data);
  }

  /// Fetches category taxonomy tree and brands directory (M-DS-01)
  /// GET /api/v1/catalog/taxonomy
  Future<TaxonomyModel> fetchTaxonomy() async {
    final response = await dioClient.get<Map<String, dynamic>>(ApiEndpoints.taxonomy);
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return TaxonomyModel.fromJson(data);
  }

  /// Searches and filters public approved products with pagination (M-DS-02, M-DS-03)
  /// GET /api/v1/products
  Future<PaginatedResponse<ProductSummaryModel>> searchProducts(ProductFilterQuery query) async {
    return dioClient.getPaginated<ProductSummaryModel>(
      ApiEndpoints.products,
      queryParameters: query.toQueryParameters(),
      fromJsonItem: (item) => ProductSummaryModel.fromJson(
        item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  /// Fetches comprehensive product detail with images, seller snapshot, and DEC-04 price (M-PD-01)
  /// GET /api/v1/products/{id}
  Future<ProductDetailModel> fetchProductDetail(int productId) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.productDetail(productId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return ProductDetailModel.fromJson(data);
  }

  /// Toggles favorite status for a product (optimistic sync with backend)
  /// POST /api/v1/products/{id}/favorite
  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.toggleFavorite(productId),
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  /// Adds a product to the user's cart (M-CR-01 / OF-01)
  /// POST /api/v1/cart/items
  Future<Map<String, dynamic>> addToCart({required int productId, int quantity = 1}) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.cartItems,
      data: {
        'product_id': productId,
        'quantity': quantity,
      },
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }
}

/// Riverpod provider for HomeCatalogRepository
final homeCatalogRepositoryProvider = Provider<HomeCatalogRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return HomeCatalogRepository(dioClient: dioClient);
});
